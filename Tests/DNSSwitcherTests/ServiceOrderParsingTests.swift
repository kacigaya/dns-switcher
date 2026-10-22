import Testing
@testable import DNSSwitcher

struct ServiceOrderParsingTests {
    @Test func hardwarePortLinesWithParenthesesAreNotServices() {
        let output = """
            An asterisk (*) denotes that a network service is disabled.
            (1) Ethernet Adapter (en4)
            (Hardware Port: Ethernet Adapter (en4), Device: en4)
            (2) Wi-Fi
            (Hardware Port: Wi-Fi, Device: en0)
            """

        #expect(NetworkInterface.parseServiceOrder(output) == ["Ethernet Adapter (en4)", "Wi-Fi"])
    }

    @Test(arguments: ["(*) Disabled VPN", "() Nameless", "(x) Letter"])
    func linesWithoutNumericPositionAreSkipped(line: String) {
        #expect(NetworkInterface.parseServiceOrder(line).isEmpty)
    }
}
