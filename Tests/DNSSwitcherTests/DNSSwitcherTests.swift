import XCTest
@testable import DNSSwitcher

final class DNSSwitcherTests: XCTestCase {
    func testDnsParsingAndMatching() {
        XCTAssertEqual(
            DnsManager.parseDnsServers("1.1.1.1\n2001:0db8::1\n"),
            ["1.1.1.1", "2001:0db8::1"]
        )
        XCTAssertEqual(DnsManager.parseDnsServers("There aren't any DNS Servers set on Wi-Fi.\n"), [])
        XCTAssertTrue(DnsManager.dnsServersMatch(["2001:db8::1"], ["2001:0db8::1"]))
        XCTAssertFalse(DnsManager.dnsServersMatch(["1.1.1.1", "1.0.0.1"], ["1.0.0.1", "1.1.1.1"]))
        XCTAssertFalse(DnsManager.dnsServersMatch(["invalid"], ["invalid"]))
        XCTAssertEqual(DnsManager.shellQuote("Wi-Fi'; echo pwned"), "'Wi-Fi'\\''; echo pwned'")
    }

    func testShellCommandQuotesEveryArgument() {
        XCTAssertEqual(
            DnsManager.shellCommand(["/usr/sbin/networksetup", "-setdnsservers", "Wi-Fi", "1.1.1.1"]),
            "'/usr/sbin/networksetup' '-setdnsservers' 'Wi-Fi' '1.1.1.1'"
        )
        XCTAssertEqual(DnsManager.shellCommand(["a b", "$(id)"]), "'a b' '$(id)'")
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

        XCTAssertEqual(NetworkInterface.parseServiceOrder(output), ["Ethernet", "Wi-Fi"])
    }
}
