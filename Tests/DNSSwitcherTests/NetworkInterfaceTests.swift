import XCTest
@testable import DNSSwitcher

final class NetworkInterfaceTests: XCTestCase {
    func testParseServiceOrderSkipsDisabledServices() {
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

    func testParseServiceOrderHandlesEmptyAndNoisyOutput() {
        XCTAssertEqual(NetworkInterface.parseServiceOrder(""), [])
        XCTAssertEqual(NetworkInterface.parseServiceOrder("(10) Thunderbolt Bridge"), ["Thunderbolt Bridge"])
        XCTAssertEqual(NetworkInterface.parseServiceOrder("(3) "), [])
    }
}
