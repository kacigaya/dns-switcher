import Foundation
import Combine
import Darwin

final class ProfileStore: ObservableObject {
    private static let profilesKey = "dns_profiles"
    private static let activeProfileIdKey = "active_profile_id"
    private static let applyToAllKey = "apply_to_all_interfaces"
    private static let maxProfileNameLength = 50

    @Published var profiles: [DnsProfile] {
        didSet { Save() }
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
            self.profiles = validated.isEmpty ? DnsProfile.defaults : validated
        } else {
            self.profiles = DnsProfile.defaults
        }

        if let idString = UserDefaults.standard.string(forKey: Self.activeProfileIdKey) {
            self.activeProfileId = UUID(uuidString: idString)
        } else {
            self.activeProfileId = nil
        }
    }

    private func Save() {
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

    private static func isValidIPAddress(_ string: String) -> Bool {
        return string.withCString { cString in
            var ipv4Address = sockaddr_in()
            if inet_pton(AF_INET, cString, &ipv4Address.sin_addr) == 1 { return true }
            var ipv6Address = sockaddr_in6()
            if inet_pton(AF_INET6, cString, &ipv6Address.sin6_addr) == 1 { return true }
            return false
        }
    }

    func ActiveProfile() -> DnsProfile? {
        guard let id = activeProfileId else { return nil }
        return profiles.first { $0.id == id }
    }
}
