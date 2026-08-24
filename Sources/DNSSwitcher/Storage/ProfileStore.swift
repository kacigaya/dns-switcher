import Foundation
import Combine

/// Stores the user's DNS profiles and preferences in `UserDefaults`.
@MainActor
final class ProfileStore: ObservableObject {
    private static let profilesKey = "dns_profiles"
    private static let activeProfileIdKey = "active_profile_id"
    private static let applyToAllKey = "apply_to_all_interfaces"

    private let defaults: UserDefaults

    @Published var profiles: [DnsProfile] {
        didSet { save() }
    }

    @Published var activeProfileId: UUID? {
        didSet {
            defaults.set(activeProfileId?.uuidString, forKey: Self.activeProfileIdKey)
        }
    }

    @Published var applyToAll: Bool {
        didSet {
            defaults.set(applyToAll, forKey: Self.applyToAllKey)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.applyToAll = defaults.bool(forKey: Self.applyToAllKey)

        if let data = defaults.data(forKey: Self.profilesKey),
           let decoded = try? JSONDecoder().decode([DnsProfile].self, from: data) {
            let validated = decoded.filter(\.isValid)
            self.profiles = decoded.isEmpty ? [] : (validated.isEmpty ? DnsProfile.defaults : validated)
            if self.profiles != decoded,
               let sanitizedData = try? JSONEncoder().encode(self.profiles) {
                defaults.set(sanitizedData, forKey: Self.profilesKey)
            }
        } else {
            self.profiles = DnsProfile.defaults
        }

        if let idString = defaults.string(forKey: Self.activeProfileIdKey),
           let id = UUID(uuidString: idString),
           self.profiles.contains(where: { $0.id == id }) {
            self.activeProfileId = id
        } else {
            self.activeProfileId = nil
            defaults.removeObject(forKey: Self.activeProfileIdKey)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: Self.profilesKey)
        }
    }
}
