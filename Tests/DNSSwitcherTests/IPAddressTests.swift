import XCTest
@testable import DNSSwitcher

final class IPAddressTests: XCTestCase {
    func testAcceptsIPv4AndIPv6() {
        XCTAssertTrue(IPAddress.isValid("1.1.1.1"))
        XCTAssertTrue(IPAddress.isValid("255.255.255.255"))
        XCTAssertTrue(IPAddress.isValid("2001:db8::1"))
        XCTAssertTrue(IPAddress.isValid("::1"))
    }

    func testRejectsMalformedInput() {
        XCTAssertFalse(IPAddress.isValid(""))
        XCTAssertFalse(IPAddress.isValid("1.1.1"))
        XCTAssertFalse(IPAddress.isValid("256.1.1.1"))
        XCTAssertFalse(IPAddress.isValid("1.1.1.1 "))
        XCTAssertFalse(IPAddress.isValid("example.com"))
        XCTAssertFalse(IPAddress.isValid("There aren't any DNS Servers set on Wi-Fi."))
    }

    func testNormalizationIgnoresTextualDifferences() {
        XCTAssertEqual(IPAddress.normalized("2001:db8::1"), IPAddress.normalized("2001:0DB8:0000::1"))
        XCTAssertNotEqual(IPAddress.normalized("1.1.1.1"), IPAddress.normalized("1.0.0.1"))
    }

    func testIPv4AndIPv6NormalizeToDifferentWidths() {
        XCTAssertEqual(IPAddress.normalized("1.1.1.1")?.count, 4)
        XCTAssertEqual(IPAddress.normalized("::1")?.count, 16)
    }
}
