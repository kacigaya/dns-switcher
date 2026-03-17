import AppKit
import Combine

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let profileStore: ProfileStore
    private var cancellables = Set<AnyCancellable>()
    private let menuBuilder: MenuBuilder

    init(profileStore: ProfileStore, onShowSettings: @escaping () -> Void) {
        self.profileStore = profileStore
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.menuBuilder = MenuBuilder(profileStore: profileStore, onShowSettings: onShowSettings)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "DNS Switcher")
            button.image?.isTemplate = true
        }

        RebuildMenu()

        profileStore.$profiles
            .merge(with: profileStore.$activeProfileId.map { _ in profileStore.profiles })
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.RebuildMenu() }
            .store(in: &cancellables)
    }

    private func RebuildMenu() {
        statusItem.menu = menuBuilder.BuildMenu()
    }
}
