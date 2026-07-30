import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menuBuilder: MenuBuilder
    private let menu = NSMenu()

    init(profileStore: ProfileStore, onShowSettings: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.menuBuilder = MenuBuilder(profileStore: profileStore, onShowSettings: onShowSettings)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "DNS Switcher")
            button.image?.isTemplate = true
        }

        menu.delegate = self
        statusItem.menu = menu
        RebuildMenu()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        RebuildMenu()
    }

    private func RebuildMenu() {
        menuBuilder.BuildMenu(menu)
    }
}
