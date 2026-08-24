import XCTest
@testable import DNSSwitcher

final class DnsManagerTests: XCTestCase {
    func testParseDnsServersKeepsOnlyAddresses() {
        XCTAssertEqual(
            DnsManager.parseDnsServers("1.1.1.1\n2001:0db8::1\n"),
            ["1.1.1.1", "2001:0db8::1"]
        )
        XCTAssertEqual(DnsManager.parseDnsServers("There aren't any DNS Servers set on Wi-Fi.\n"), [])
    }

    func testDnsServersMatchComparesNormalizedAddressesInOrder() {
        XCTAssertTrue(DnsManager.dnsServersMatch(["2001:db8::1"], ["2001:0db8::1"]))
        XCTAssertTrue(DnsManager.dnsServersMatch([], []))
        XCTAssertFalse(DnsManager.dnsServersMatch(["1.1.1.1", "1.0.0.1"], ["1.0.0.1", "1.1.1.1"]))
        XCTAssertFalse(DnsManager.dnsServersMatch(["1.1.1.1"], ["1.1.1.1", "1.0.0.1"]))
        XCTAssertFalse(DnsManager.dnsServersMatch(["invalid"], ["invalid"]))
    }

    func testShellQuoteNeutralizesMetacharacters() {
        XCTAssertEqual(DnsManager.shellQuote("Wi-Fi'; echo pwned"), "'Wi-Fi'\\''; echo pwned'")
        XCTAssertEqual(DnsManager.shellQuote("$(id)"), "'$(id)'")
        XCTAssertEqual(DnsManager.shellQuote("a`b`"), "'a`b`'")
    }

    func testShellCommandQuotesEveryArgument() {
        XCTAssertEqual(
            DnsManager.shellCommand(["/usr/sbin/networksetup", "-setdnsservers", "Wi-Fi", "1.1.1.1"]),
            "'/usr/sbin/networksetup' '-setdnsservers' 'Wi-Fi' '1.1.1.1'"
        )
        XCTAssertEqual(DnsManager.shellCommand(["a b", "$(id)"]), "'a b' '$(id)'")
    }
}
