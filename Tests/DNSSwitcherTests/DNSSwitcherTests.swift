import XCTest
@testable import DNSSwitcher

final class DNSSwitcherTests: XCTestCase {
    func testDnsParsingAndMatching() {
        XCTAssertEqual(
            DnsManager.ParseDnsServers("1.1.1.1\n2001:0db8::1\n"),
            ["1.1.1.1", "2001:0db8::1"]
        )
        XCTAssertEqual(DnsManager.ParseDnsServers("There aren't any DNS Servers set on Wi-Fi.\n"), [])
        XCTAssertTrue(DnsManager.DnsServersMatch(["2001:db8::1"], ["2001:0db8::1"]))
        XCTAssertFalse(DnsManager.DnsServersMatch(["1.1.1.1", "1.0.0.1"], ["1.0.0.1", "1.1.1.1"]))
        XCTAssertFalse(DnsManager.DnsServersMatch(["invalid"], ["invalid"]))
        XCTAssertEqual(DnsManager.ShellQuote("Wi-Fi'; echo pwned"), "'Wi-Fi'\\''; echo pwned'")
    }

    func testServiceOrderParsing() {
        let output = """
            An asterisk (*) denotes that a network service is disabled.
            (1) Ethernet
            (Hardware Port: Ethernet, Device: en0)
            (2) Wi-Fi
            (Hardware Port: Wi-Fi, Device: en1)
            (*) Disabled VPN
            """

        XCTAssertEqual(NetworkInterface.ParseServiceOrder(output), ["Ethernet", "Wi-Fi"])
    }
}
