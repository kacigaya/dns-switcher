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

    /// Quotes each argument and joins them into a single shell command line.
    static func shellCommand(_ args: [String]) -> String {
        args.map { shellQuote($0) }.joined(separator: " ")
    }

    @MainActor
    static func runPrivileged(command: String) -> CommandResult {
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

    @MainActor
    @discardableResult
    static func applyProfile(_ profile: DnsProfile, to interfaces: [String]) -> Bool {
        applyDns(
            servers: profile.servers,
            to: interfaces,
            action: "set DNS",
            failTitle: "DNS Change Partially Failed"
        )
    }

    @MainActor
    @discardableResult
    static func resetToDefault(on interfaces: [String]) -> Bool {
        // "empty" is networksetup's literal keyword for clearing DNS servers.
        applyDns(
            servers: ["empty"],
            to: interfaces,
            action: "reset DNS",
            failTitle: "DNS Reset Partially Failed"
        )
    }

    /// Runs `networksetup -setdnsservers` for each interface, escalating to a
    /// single administrator prompt for the interfaces that need one.
    ///
    /// Stays on the main actor because it may show an alert and because
    /// `NSAppleScript` is not safe to use from arbitrary threads.
    @MainActor
    private static func applyDns(
        servers: [String],
        to interfaces: [String],
        action: String,
        failTitle: String
    ) -> Bool {
        guard !interfaces.isEmpty else {
            showAlert(title: "No Active Interfaces", message: "Could not find any active network interfaces.")
            return false
        }

        // First pass without privileges; networksetup succeeds silently when
        // the session is already authorized.
        let failed = interfaces.filter { interface in
            runCommand("/usr/sbin/networksetup", args: ["-setdnsservers", interface] + servers).exitCode != 0
        }

        var failureMessage: String?
        if !failed.isEmpty {
            // Batch the remaining interfaces into one privileged script so the
            // user sees a single password prompt regardless of interface count.
            let command = failed
                .map { shellCommand(["/usr/sbin/networksetup", "-setdnsservers", $0] + servers) }
                .joined(separator: " && ")
            let result = runPrivileged(command: command)

            if result.exitCode != 0 {
                let details = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                let names = failed.joined(separator: ", ")
                failureMessage = details.isEmpty
                    ? "Could not \(action) for \(names)."
                    : "Could not \(action) for \(names). Details: \(details)"
            }
        }

        flushDnsCache()

        if let failureMessage {
            showAlert(title: failTitle, message: failureMessage)
            return false
        }
        return true
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
            .filter { IPAddress.isValid($0) }
    }

    static func dnsServersMatch(_ lhs: [String], _ rhs: [String]) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy {
            guard let left = IPAddress.normalized($0),
                  let right = IPAddress.normalized($1)
            else { return false }
            return left == right
        }
    }

    private static func flushDnsCache() {
        _ = runCommand("/usr/bin/dscacheutil", args: ["-flushcache"])
    }

    @MainActor
    private static func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
