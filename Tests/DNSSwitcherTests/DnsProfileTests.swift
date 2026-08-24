import XCTest
@testable import DNSSwitcher

final class DnsProfileTests: XCTestCase {
    func testBuiltInProfilesAreValid() {
        for profile in DnsProfile.defaults {
            XCTAssertNil(profile.validationError, "\(profile.name) should be valid")
        }
    }

    func testValidationReportsFirstProblem() {
        XCTAssertEqual(DnsProfile(name: "  ", servers: ["1.1.1.1"]).validationError, .emptyName)
        XCTAssertEqual(
            DnsProfile(name: String(repeating: "a", count: 51), servers: ["1.1.1.1"]).validationError,
            .nameTooLong(maximum: 50)
        )
        XCTAssertEqual(DnsProfile(name: "Empty", servers: []).validationError, .noServers)
        XCTAssertEqual(
            DnsProfile(name: "Bad", servers: ["1.1.1.1", "nope"]).validationError,
            .invalidServer("nope")
        )
        XCTAssertNil(DnsProfile(name: "Fine", servers: ["1.1.1.1", "2001:db8::1"]).validationError)
    }

    func testNameLengthBoundaryIsInclusive() {
        let profile = DnsProfile(name: String(repeating: "a", count: 50), servers: ["1.1.1.1"])
        XCTAssertTrue(profile.isValid)
    }

    func testParseServersSplitsOnCommasAndWhitespace() {
        XCTAssertEqual(DnsProfile.parseServers("1.1.1.1, 1.0.0.1"), ["1.1.1.1", "1.0.0.1"])
        XCTAssertEqual(DnsProfile.parseServers("1.1.1.1 1.0.0.1"), ["1.1.1.1", "1.0.0.1"])
        XCTAssertEqual(DnsProfile.parseServers("1.1.1.1\n1.0.0.1\n"), ["1.1.1.1", "1.0.0.1"])
        XCTAssertEqual(DnsProfile.parseServers("  ,, "), [])
    }
}
