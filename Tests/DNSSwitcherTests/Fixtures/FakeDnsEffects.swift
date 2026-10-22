@testable import DNSSwitcher

/// Records every DNS side effect and answers with scripted results, so tests
/// never run `networksetup`, prompt for a password, or show an alert.
@MainActor
final class FakeDnsEffects {
    struct Alert: Equatable {
        let title: String
        let message: String
    }

    /// Interfaces whose unprivileged `networksetup` call fails.
    var failingInterfaces: Set<String> = []
    var privilegedResult = DnsManager.CommandResult(output: "", exitCode: 0)

    private(set) var commands: [[String]] = []
    private(set) var privilegedCommands: [String] = []
    private(set) var alerts: [Alert] = []

    var effects: DnsManager.Effects {
        DnsManager.Effects(
            run: { executable, args in
                self.commands.append([executable] + args)
                // args[1] is the service name for `-setdnsservers <service> ...`.
                let fails = args.count > 1 && self.failingInterfaces.contains(args[1])
                return DnsManager.CommandResult(output: "", exitCode: fails ? 1 : 0)
            },
            runPrivileged: { command in
                self.privilegedCommands.append(command)
                return self.privilegedResult
            },
            showAlert: { title, message in
                self.alerts.append(Alert(title: title, message: message))
            }
        )
    }
}
