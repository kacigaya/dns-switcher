import Foundation

enum NetworkInterface {
    /// Returns network services that are currently connected (have an IP address),
    /// sorted so Wi-Fi and Ethernet appear first.
    static func ListActiveInterfaces() -> [String] {
        let allServices = ListAllServices()
        let connected = allServices.filter { IsConnected($0) }

        // Sort: Wi-Fi and Ethernet first, then others
        return connected.sorted { a, b in
            Priority(a) < Priority(b)
        }
    }

    private static func ListAllServices() -> [String] {
        let result = DnsManager.RunCommand("/usr/sbin/networksetup", args: ["-listallnetworkservices"])
        guard result.exitCode == 0 else { return [] }

        return
            result.output
            .components(separatedBy: "\n")
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("*") }
    }

    /// Check if a service has an IP address assigned (meaning it's connected).
    private static func IsConnected(_ service: String) -> Bool {
        let result = DnsManager.RunCommand("/usr/sbin/networksetup", args: ["-getinfo", service])
        guard result.exitCode == 0 else { return false }

        // Look for a real IP address line (not "none")
        for line in result.output.components(separatedBy: "\n") {
            if line.hasPrefix("IP address:") {
                let value = line.replacingOccurrences(of: "IP address:", with: "").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty && value != "none" {
                    return true
                }
            }
        }
        return false
    }

    private static func Priority(_ service: String) -> Int {
        let lower = service.lowercased()
        if lower == "wi-fi" { return 0 }
        if lower.contains("ethernet") || lower.contains("lan") { return 1 }
        return 2
    }
}
