import Foundation

enum NetworkInterface {
    /// Returns connected network services in the user's configured service order.
    static func ListActiveInterfaces() -> [String] {
        ListAllServices().filter { IsConnected($0) }
    }

    private static func ListAllServices() -> [String] {
        let result = DnsManager.RunCommand("/usr/sbin/networksetup", args: ["-listnetworkserviceorder"])
        guard result.exitCode == 0 else { return [] }

        return ParseServiceOrder(result.output)
    }

    static func ParseServiceOrder(_ output: String) -> [String] {
        output.components(separatedBy: "\n").compactMap { line in
            let line = line.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("("),
                  !line.hasPrefix("(*)"),
                  let close = line.firstIndex(of: ")")
            else { return nil }
            let name = String(line[line.index(after: close)...]).trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : name
        }
    }

    /// Check if a service has an IP address assigned (meaning it's connected).
    private static func IsConnected(_ service: String) -> Bool {
        let result = DnsManager.RunCommand("/usr/sbin/networksetup", args: ["-getinfo", service])
        guard result.exitCode == 0 else { return false }

        for line in result.output.components(separatedBy: "\n") {
            for prefix in ["IP address:", "IPv6 IP address:"] where line.hasPrefix(prefix) {
                let value = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty && value.lowercased() != "none" {
                    return true
                }
            }
        }
        return false
    }
}
