import XCTest
@testable import DNSSwitcher

@MainActor
final class ProfileStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suiteName = "DNSSwitcherTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func store() -> ProfileStore {
        ProfileStore(defaults: defaults)
    }

    func testFirstLaunchSeedsBuiltInProfiles() {
        XCTAssertEqual(store().profiles.map(\.name), DnsProfile.defaults.map(\.name))
    }

    func testProfilesPersistAcrossInstances() {
        let first = store()
        first.profiles = [DnsProfile(name: "Home", servers: ["10.0.0.1"])]

        XCTAssertEqual(store().profiles.map(\.name), ["Home"])
    }

    func testEmptyProfileListIsPreserved() {
        let first = store()
        first.profiles = []

        XCTAssertEqual(store().profiles, [])
    }

    func testCorruptProfilesAreDiscardedOnLoad() {
        let good = DnsProfile(name: "Home", servers: ["10.0.0.1"])
        let bad = DnsProfile(name: "Broken", servers: ["not-an-ip"])
        defaults.set(try? JSONEncoder().encode([good, bad]), forKey: "dns_profiles")

        XCTAssertEqual(store().profiles, [good])
        // The sanitized list is written back, so the bad entry does not return.
        XCTAssertEqual(store().profiles, [good])
    }

    func testAllProfilesInvalidFallsBackToDefaults() {
        let bad = DnsProfile(name: "", servers: [])
        defaults.set(try? JSONEncoder().encode([bad]), forKey: "dns_profiles")

        XCTAssertEqual(store().profiles.map(\.name), DnsProfile.defaults.map(\.name))
    }

    func testUnreadableDataFallsBackToDefaults() {
        defaults.set(Data("not json".utf8), forKey: "dns_profiles")

        XCTAssertEqual(store().profiles.map(\.name), DnsProfile.defaults.map(\.name))
    }

    func testActiveProfileIdPersistsWhenTheProfileStillExists() {
        let first = store()
        let profile = DnsProfile(name: "Home", servers: ["10.0.0.1"])
        first.profiles = [profile]
        first.activeProfileId = profile.id

        XCTAssertEqual(store().activeProfileId, profile.id)
    }

    func testStaleActiveProfileIdIsCleared() {
        let first = store()
        first.profiles = [DnsProfile(name: "Home", servers: ["10.0.0.1"])]
        first.activeProfileId = UUID()

        let reloaded = store()
        XCTAssertNil(reloaded.activeProfileId)
        XCTAssertNil(defaults.string(forKey: "active_profile_id"))
    }

    func testApplyToAllPersists() {
        XCTAssertFalse(store().applyToAll)

        let first = store()
        first.applyToAll = true

        XCTAssertTrue(store().applyToAll)
    }
}
