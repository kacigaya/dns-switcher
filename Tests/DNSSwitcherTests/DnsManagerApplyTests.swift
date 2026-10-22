import Testing
@testable import DNSSwitcher

@MainActor
struct DnsManagerApplyTests {
    private let fake = FakeDnsEffects()
    private let cloudflare = DnsProfile(name: "Cloudflare", servers: ["1.1.1.1", "1.0.0.1"])
    private let flush = ["/usr/bin/dscacheutil", "-flushcache"]

    @Test func applyRunsWithoutPrivilegesWhenNetworksetupSucceeds() {
        let applied = DnsManager.applyProfile(cloudflare, to: ["Wi-Fi", "Ethernet"], effects: fake.effects)

        #expect(applied)
        #expect(fake.commands == [
            ["/usr/sbin/networksetup", "-setdnsservers", "Wi-Fi", "1.1.1.1", "1.0.0.1"],
            ["/usr/sbin/networksetup", "-setdnsservers", "Ethernet", "1.1.1.1", "1.0.0.1"],
            flush,
        ])
        #expect(fake.privilegedCommands.isEmpty)
        #expect(fake.alerts.isEmpty)
    }

    @Test func failedInterfacesShareOnePrivilegedCommand() {
        fake.failingInterfaces = ["Wi-Fi", "Ethernet"]

        let applied = DnsManager.applyProfile(
            DnsProfile(name: "One", servers: ["1.1.1.1"]),
            to: ["Wi-Fi", "USB LAN", "Ethernet"],
            effects: fake.effects
        )

        #expect(applied)
        #expect(fake.privilegedCommands == [
            "'/usr/sbin/networksetup' '-setdnsservers' 'Wi-Fi' '1.1.1.1'"
                + " && '/usr/sbin/networksetup' '-setdnsservers' 'Ethernet' '1.1.1.1'"
        ])
        #expect(fake.commands.last == flush)
    }

    @Test func hostileServiceNameStaysQuotedInPrivilegedCommand() throws {
        let service = "Wi-Fi'; touch /tmp/pwned; '"
        fake.failingInterfaces = [service]

        DnsManager.applyProfile(cloudflare, to: [service], effects: fake.effects)

        let command = try #require(fake.privilegedCommands.first)
        #expect(command.contains(DnsManager.shellQuote(service)))
        #expect(command.contains("'Wi-Fi'; touch") == false)
    }

    @Test func privilegedFailureAlertsAndStillFlushes() {
        fake.failingInterfaces = ["Wi-Fi"]
        fake.privilegedResult = DnsManager.CommandResult(output: "User canceled.\n", exitCode: 1)

        let applied = DnsManager.applyProfile(cloudflare, to: ["Wi-Fi"], effects: fake.effects)

        #expect(applied == false)
        #expect(fake.alerts == [FakeDnsEffects.Alert(
            title: "DNS Change Partially Failed",
            message: "Could not set DNS for Wi-Fi. Details: User canceled."
        )])
        #expect(fake.commands.last == flush)
    }

    @Test func noInterfacesAlertsWithoutRunningCommands() {
        let applied = DnsManager.applyProfile(cloudflare, to: [], effects: fake.effects)

        #expect(applied == false)
        #expect(fake.commands.isEmpty)
        #expect(fake.privilegedCommands.isEmpty)
        #expect(fake.alerts.map(\.title) == ["No Active Interfaces"])
    }

    @Test func resetClearsServersWithEmptyKeyword() {
        let reset = DnsManager.resetToDefault(on: ["Wi-Fi"], effects: fake.effects)

        #expect(reset)
        #expect(fake.commands == [
            ["/usr/sbin/networksetup", "-setdnsservers", "Wi-Fi", "empty"],
            flush,
        ])
    }

    @Test func privilegedScriptEscapesAppleScriptStringDelimiters() {
        #expect(
            DnsManager.privilegedScript(for: #"'a"b\c'"#)
                == #"do shell script "'a\"b\\c'" with administrator privileges"#
        )
    }
}
