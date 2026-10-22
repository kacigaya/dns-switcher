import Foundation
import Testing
@testable import DNSSwitcher

@MainActor
struct ProfileStoreSanitizingTests {
    private let suiteName = "DNSSwitcherTests.\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    @Test func duplicateProfileIdsKeepTheFirstEntry() throws {
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let first = DnsProfile(name: "Home", servers: ["10.0.0.1"])
        let duplicate = DnsProfile(id: first.id, name: "Copy", servers: ["10.0.0.2"])
        let other = DnsProfile(name: "Work", servers: ["10.1.0.1"])
        defaults.set(try JSONEncoder().encode([first, duplicate, other]), forKey: "dns_profiles")

        #expect(ProfileStore(defaults: defaults).profiles == [first, other])
        // The sanitized list is written back.
        #expect(ProfileStore(defaults: defaults).profiles == [first, other])
    }
}
