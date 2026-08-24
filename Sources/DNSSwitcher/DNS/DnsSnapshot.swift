import Foundation

/// Point-in-time view of the system's DNS configuration, used to build the menu
/// without re-reading `networksetup` for every question the UI asks.
struct DnsSnapshot: Sendable, Equatable {
    /// Connected network services, in the user's configured service order.
    let interfaces: [String]

    /// DNS servers currently set per interface. A missing key means the
    /// interface's configuration could not be read.
    let dnsByInterface: [String: [String]]

    /// Reads the current configuration. This spawns several `networksetup`
    /// processes and blocks until they exit, so it must not run on the main actor.
    static func load() -> DnsSnapshot {
        let interfaces = NetworkInterface.listActiveInterfaces()

        var dnsByInterface: [String: [String]] = [:]
        for interface in interfaces {
            // Assigning nil leaves the key absent, which marks it unreadable.
            dnsByInterface[interface] = DnsManager.getCurrentDNS(for: interface)
        }

        return DnsSnapshot(interfaces: interfaces, dnsByInterface: dnsByInterface)
    }

    /// Interfaces a DNS change applies to, honoring the "all interfaces" setting.
    func targetedInterfaces(applyToAll: Bool) -> [String] {
        applyToAll ? interfaces : Array(interfaces.prefix(1))
    }

    /// DNS servers for every targeted interface, or nil if any could not be read.
    func targetedDnsServers(applyToAll: Bool) -> [[String]]? {
        var servers: [[String]] = []
        for interface in targetedInterfaces(applyToAll: applyToAll) {
            guard let current = dnsByInterface[interface] else { return nil }
            servers.append(current)
        }
        return servers
    }

    /// The profile matching what every targeted interface currently uses, if any.
    func matchingProfile(among profiles: [DnsProfile], applyToAll: Bool) -> DnsProfile? {
        guard let servers = targetedDnsServers(applyToAll: applyToAll), !servers.isEmpty else {
            return nil
        }
        return profiles.first { profile in
            servers.allSatisfy { DnsManager.dnsServersMatch(profile.servers, $0) }
        }
    }

    /// True when every targeted interface has no DNS servers set (DHCP).
    func usesAutomaticDns(applyToAll: Bool) -> Bool {
        guard let servers = targetedDnsServers(applyToAll: applyToAll), !servers.isEmpty else {
            return false
        }
        return servers.allSatisfy(\.isEmpty)
    }
}
