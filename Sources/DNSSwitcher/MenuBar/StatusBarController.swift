import AppKit

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menuBuilder: MenuBuilder
    private let menu = NSMenu()

    /// Last known DNS state. Nil until the first read completes.
    private var snapshot: DnsSnapshot?
    private var refreshTask: Task<Void, Never>?

    init(profileStore: ProfileStore, onShowSettings: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.menuBuilder = MenuBuilder(profileStore: profileStore, onShowSettings: onShowSettings)
        super.init()

        menuBuilder.onDnsChanged = { [weak self] in self?.refreshSnapshot() }

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "DNS Switcher")
            button.image?.isTemplate = true
            button.toolTip = "DNS Switcher"
            button.setAccessibilityLabel("DNS Switcher")
        }

        menu.delegate = self
        statusItem.menu = menu
        menuBuilder.buildMenu(menu, snapshot: nil)
        refreshSnapshot()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Render immediately from the cached snapshot: reading the live state
        // spawns several networksetup processes and would stall the menu.
        menuBuilder.buildMenu(menu, snapshot: snapshot)
        refreshSnapshot()
    }

    /// Reads the DNS state off the main actor, then rebuilds the menu in place.
    private func refreshSnapshot() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            // Detached because DnsSnapshot.load() blocks on child processes,
            // which must never happen on the main actor.
            let snapshot = await Task.detached(priority: .userInitiated) {
                DnsSnapshot.load()
            }.value

            guard !Task.isCancelled, let self else { return }
            guard snapshot != self.snapshot else { return }

            self.snapshot = snapshot
            self.menuBuilder.buildMenu(self.menu, snapshot: snapshot)
        }
    }
}
