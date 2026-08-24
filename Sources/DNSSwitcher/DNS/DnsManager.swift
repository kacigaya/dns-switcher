import AppKit
import Foundation

enum DnsManager {
    struct CommandResult {
        let output: String
        let exitCode: Int32
    }

    static func runCommand(_ executable: String, args: [String]) -> CommandResult {
        let task = Process()
        let pipe = Pipe()

        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            return CommandResult(output: error.localizedDescription, exitCode: -1)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        return CommandResult(
            output: String(data: data, encoding: .utf8) ?? "",
            exitCode: task.terminationStatus
        )
    }

    /// Wraps a single argument in single quotes, escaping any embedded single quotes.
    /// This prevents shell interpretation of metacharacters like $, `, !, ;, |, &, etc.
    static func shellQuote(_ arg: String) -> String {
        let escaped = arg.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    /// Escapes a pre-quoted shell command for embedding inside an AppleScript
    /// `do shell script "..."` double-quoted string.
    private static func escapeForAppleScript(_ command: String) -> String {
        return command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    static func runPrivileged(args: [String]) -> CommandResult {
        let command = args.map { shellQuote($0) }.joined(separator: " ")
        let escapedCommand = escapeForAppleScript(command)

        let script = """
            do shell script "\(escapedCommand)" with administrator privileges
            """

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            return CommandResult(output: "Failed to create AppleScript", exitCode: -1)
        }

        let result = appleScript.executeAndReturnError(&error)

        if let error = error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            return CommandResult(output: message, exitCode: 1)
        }

        return CommandResult(output: result.stringValue ?? "", exitCode: 0)
    }

    @discardableResult
    static func applyProfile(_ profile: DnsProfile, toAllInterfaces: Bool) -> Bool {
        applyDns(
            servers: profile.servers,
            action: "set DNS",
            failTitle: "DNS Change Partially Failed",
            toAllInterfaces: toAllInterfaces
        )
    }

    @discardableResult
    static func resetToDefault(toAllInterfaces: Bool) -> Bool {
        applyDns(
            servers: ["empty"],
            action: "reset DNS",
            failTitle: "DNS Reset Partially Failed",
            toAllInterfaces: toAllInterfaces
        )
    }

    private static func applyDns(
        servers: [String],
        action: String,
        failTitle: String,
        toAllInterfaces: Bool
    ) -> Bool {
        let interfaces = toAllInterfaces
            ? NetworkInterface.listActiveInterfaces()
            : Array(NetworkInterface.listActiveInterfaces().prefix(1))

        guard !interfaces.isEmpty else {
            showAlert(title: "No Active Interfaces", message: "Could not find any active network interfaces.")
            return false
        }

        var failures: [String] = []
        for iface in interfaces {
            let args = ["-setdnsservers", iface] + servers
            let result = runCommand("/usr/sbin/networksetup", args: args)

            if result.exitCode != 0 {
                let privResult = runPrivileged(args: ["/usr/sbin/networksetup"] + args)

                if privResult.exitCode != 0 {
                    let details = privResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
                    failures.append(
                        details.isEmpty
                            ? "Could not \(action) for \(iface)."
                            : "Could not \(action) for \(iface). Details: \(details)"
                    )
                }
            }
        }

        flushDnsCache()

        if !failures.isEmpty {
            showAlert(title: failTitle, message: failures.joined(separator: "\n"))
        }
        return failures.isEmpty
    }

    static func getCurrentDNS(for interface: String) -> [String]? {
        let result = runCommand("/usr/sbin/networksetup", args: ["-getdnsservers", interface])
        guard result.exitCode == 0 else { return nil }

        return parseDnsServers(result.output)
    }

    static func parseDnsServers(_ output: String) -> [String] {
        output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { ProfileStore.isValidIPAddress($0) }
    }

    static func dnsServersMatch(_ lhs: [String], _ rhs: [String]) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy {
            guard let left = ProfileStore.normalizedIPAddress($0),
                  let right = ProfileStore.normalizedIPAddress($1)
            else { return false }
            return left == right
        }
    }

    private static func flushDnsCache() {
        _ = runCommand("/usr/bin/dscacheutil", args: ["-flushcache"])
    }

    private static func showAlert(title: String, message: String) {
        let show = {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        if Thread.isMainThread {
            show()
        } else {
            DispatchQueue.main.async(execute: show)
        }
    }
}
