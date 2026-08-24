import XCTest
@testable import DNSSwitcher

final class DnsSnapshotTests: XCTestCase {
    private let cloudflare = DnsProfile(name: "Cloudflare", servers: ["1.1.1.1", "1.0.0.1"])
    private let quad9 = DnsProfile(name: "Quad9", servers: ["9.9.9.9"])

    private func snapshot(_ dns: [String: [String]], interfaces: [String]) -> DnsSnapshot {
        DnsSnapshot(interfaces: interfaces, dnsByInterface: dns)
    }

    func testTargetedInterfacesHonorsApplyToAll() {
        let state = snapshot(["Wi-Fi": [], "Ethernet": []], interfaces: ["Wi-Fi", "Ethernet"])

        XCTAssertEqual(state.targetedInterfaces(applyToAll: true), ["Wi-Fi", "Ethernet"])
        XCTAssertEqual(state.targetedInterfaces(applyToAll: false), ["Wi-Fi"])
    }

    func testMatchingProfileRequiresEveryTargetedInterfaceToAgree() {
        let state = snapshot(
            ["Wi-Fi": ["1.1.1.1", "1.0.0.1"], "Ethernet": ["9.9.9.9"]],
            interfaces: ["Wi-Fi", "Ethernet"]
        )

        XCTAssertNil(state.matchingProfile(among: [cloudflare, quad9], applyToAll: true))
        XCTAssertEqual(
            state.matchingProfile(among: [cloudflare, quad9], applyToAll: false)?.name,
            "Cloudflare"
        )
    }

    func testUnreadableInterfaceMakesStateUnknown() {
        // Ethernet is missing from the map, meaning networksetup could not be read.
        let state = snapshot(["Wi-Fi": ["1.1.1.1", "1.0.0.1"]], interfaces: ["Wi-Fi", "Ethernet"])

        XCTAssertNil(state.targetedDnsServers(applyToAll: true))
        XCTAssertNil(state.matchingProfile(among: [cloudflare], applyToAll: true))
        XCTAssertFalse(state.usesAutomaticDns(applyToAll: true))
    }

    func testUsesAutomaticDnsOnlyWhenEveryTargetIsEmpty() {
        let allEmpty = snapshot(["Wi-Fi": [], "Ethernet": []], interfaces: ["Wi-Fi", "Ethernet"])
        let partly = snapshot(["Wi-Fi": [], "Ethernet": ["9.9.9.9"]], interfaces: ["Wi-Fi", "Ethernet"])

        XCTAssertTrue(allEmpty.usesAutomaticDns(applyToAll: true))
        XCTAssertFalse(partly.usesAutomaticDns(applyToAll: true))
        XCTAssertTrue(partly.usesAutomaticDns(applyToAll: false))
    }

    func testNoInterfacesMeansNoMatchAndNoAutomaticDns() {
        let state = snapshot([:], interfaces: [])

        XCTAssertNil(state.matchingProfile(among: [cloudflare], applyToAll: true))
        XCTAssertFalse(state.usesAutomaticDns(applyToAll: true))
    }
}
