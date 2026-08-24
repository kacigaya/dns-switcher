import Foundation
import Combine
// Required for inet_pton, AF_INET/AF_INET6, and sockaddr types used in IP validation.
import Darwin

final class ProfileStore: ObservableObject {
    private static let profilesKey = "dns_profiles"
    private static let activeProfileIdKey = "active_profile_id"
    private static let applyToAllKey = "apply_to_all_interfaces"
    static let maxProfileNameLength = 50

    @Published var profiles: [DnsProfile] {
        didSet { save() }
    }

    @Published var activeProfileId: UUID? {
        didSet {
            UserDefaults.standard.set(activeProfileId?.uuidString, forKey: Self.activeProfileIdKey)
        }
    }

    @Published var applyToAll: Bool {
        didSet {
            UserDefaults.standard.set(applyToAll, forKey: Self.applyToAllKey)
        }
    }

    init() {
        self.applyToAll = UserDefaults.standard.bool(forKey: Self.applyToAllKey)

        if let data = UserDefaults.standard.data(forKey: Self.profilesKey),
           let decoded = try? JSONDecoder().decode([DnsProfile].self, from: data) {
            let validated = decoded.filter { Self.isValidProfile($0) }
            self.profiles = decoded.isEmpty ? [] : (validated.isEmpty ? DnsProfile.defaults : validated)
            if self.profiles != decoded,
               let sanitizedData = try? JSONEncoder().encode(self.profiles) {
                UserDefaults.standard.set(sanitizedData, forKey: Self.profilesKey)
            }
        } else {
            self.profiles = DnsProfile.defaults
        }

        if let idString = UserDefaults.standard.string(forKey: Self.activeProfileIdKey),
           let id = UUID(uuidString: idString),
           self.profiles.contains(where: { $0.id == id }) {
            self.activeProfileId = id
        } else {
            self.activeProfileId = nil
            UserDefaults.standard.removeObject(forKey: Self.activeProfileIdKey)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: Self.profilesKey)
        }
    }

    private static func isValidProfile(_ profile: DnsProfile) -> Bool {
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= Self.maxProfileNameLength, !profile.servers.isEmpty else {
            return false
        }

        for server in profile.servers {
            if !isValidIPAddress(server) {
                return false
            }
        }
        return true
    }

    static func isValidIPAddress(_ string: String) -> Bool {
        normalizedIPAddress(string) != nil
    }

    static func normalizedIPAddress(_ string: String) -> Data? {
        return string.withCString { cString in
            var ipv4Address = sockaddr_in()
            if inet_pton(AF_INET, cString, &ipv4Address.sin_addr) == 1 {
                return Data(bytes: &ipv4Address.sin_addr, count: MemoryLayout<in_addr>.size)
            }
            var ipv6Address = sockaddr_in6()
            if inet_pton(AF_INET6, cString, &ipv6Address.sin6_addr) == 1 {
                return Data(bytes: &ipv6Address.sin6_addr, count: MemoryLayout<in6_addr>.size)
            }
            return nil
        }
    }
}
