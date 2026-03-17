import AppKit
import Foundation

enum DnsManager {
    struct CommandResult {
        let output: String
        let exitCode: Int32
    }

    static func RunCommand(_ executable: String, args: [String]) -> CommandResult {
        let task = Process()
        let pipe = Pipe()
        let errPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = errPipe

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return CommandResult(output: error.localizedDescription, exitCode: -1)
        }

        let outData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outData, encoding: .utf8) ?? ""
        let errOutput = String(data: errData, encoding: .utf8) ?? ""

        return CommandResult(
            output: output.isEmpty ? errOutput : output,
            exitCode: task.terminationStatus
        )
    }

    static func RunPrivileged(command: String) -> CommandResult {
        let escapedCommand = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

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

    static func ApplyProfile(_ profile: DnsProfile, toAllInterfaces: Bool) {
        let interfaces = toAllInterfaces
            ? NetworkInterface.ListActiveInterfaces()
            : Array(NetworkInterface.ListActiveInterfaces().prefix(1))

        guard !interfaces.isEmpty else {
            ShowAlert(title: "No Active Interfaces", message: "Could not find any active network interfaces.")
            return
        }

        for iface in interfaces {
            let args = ["-setdnsservers", iface] + profile.servers
            let result = RunCommand("/usr/sbin/networksetup", args: args)

            if result.exitCode != 0 {
                let serverList = profile.servers.joined(separator: " ")
                let cmd = "/usr/sbin/networksetup -setdnsservers \"\(iface)\" \(serverList)"
                let privResult = RunPrivileged(command: cmd)

                if privResult.exitCode != 0 {
                    ShowAlert(
                        title: "DNS Change Failed",
                        message: "Could not set DNS for \(iface):\n\(privResult.output)"
                    )
                    return
                }
            }
        }

        FlushDnsCache()
    }

    static func ResetToDefault(toAllInterfaces: Bool) {
        let interfaces = toAllInterfaces
            ? NetworkInterface.ListActiveInterfaces()
            : Array(NetworkInterface.ListActiveInterfaces().prefix(1))

        guard !interfaces.isEmpty else {
            ShowAlert(title: "No Active Interfaces", message: "Could not find any active network interfaces.")
            return
        }

        for iface in interfaces {
            let args = ["-setdnsservers", iface, "empty"]
            let result = RunCommand("/usr/sbin/networksetup", args: args)

            if result.exitCode != 0 {
                let cmd = "/usr/sbin/networksetup -setdnsservers \"\(iface)\" empty"
                let privResult = RunPrivileged(command: cmd)

                if privResult.exitCode != 0 {
                    ShowAlert(
                        title: "DNS Reset Failed",
                        message: "Could not reset DNS for \(iface):\n\(privResult.output)"
                    )
                    return
                }
            }
        }

        FlushDnsCache()
    }

    static func GetCurrentDNS(for interface: String) -> [String] {
        let result = RunCommand("/usr/sbin/networksetup", args: ["-getdnsservers", interface])
        guard result.exitCode == 0 else { return [] }

        let lines = result.output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // "There aren't any DNS Servers set on ..." means DHCP
        if lines.first?.contains("aren't any") == true {
            return []
        }

        return lines
    }

    private static func FlushDnsCache() {
        _ = RunCommand("/usr/bin/dscacheutil", args: ["-flushcache"])
    }

    private static func ShowAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
