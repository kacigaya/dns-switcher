import Testing
@testable import DNSSwitcher

struct DnsServerParsingTests {
    @Test func noServersNoticeMeansAutomaticDns() {
        #expect(DnsManager.parseDnsServers("There aren't any DNS Servers set on Wi-Fi.\n") == [])
    }

    @Test(arguments: [
        "** Error: The parameters were not valid.\n",
        "Wi-Fi is not a recognized network service.\n",
        "",
    ])
    func unrecognizedOutputIsUnreadable(output: String) {
        #expect(DnsManager.parseDnsServers(output) == nil)
    }
}
