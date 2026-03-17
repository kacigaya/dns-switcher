import Foundation
import Combine

final class ProfileStore: ObservableObject {
    private static let profilesKey = "dns_profiles"
    private static let activeProfileIdKey = "active_profile_id"
    private static let applyToAllKey = "apply_to_all_interfaces"

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
            self.profiles = decoded
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

    func ActiveProfile() -> DnsProfile? {
        guard let id = activeProfileId else { return nil }
        return profiles.first { $0.id == id }
    }
}
