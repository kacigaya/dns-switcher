import AppKit

final class MenuBuilder: NSObject {
    private let profileStore: ProfileStore
    private let onShowSettings: () -> Void

    init(profileStore: ProfileStore, onShowSettings: @escaping () -> Void) {
        self.profileStore = profileStore
        self.onShowSettings = onShowSettings
    }

    func BuildMenu() -> NSMenu {
        let menu = NSMenu()

        let interfaces = NetworkInterface.ListActiveInterfaces()

        if interfaces.isEmpty {
            let noIfaceItem = NSMenuItem(title: "No active interfaces", action: nil, keyEquivalent: "")
            noIfaceItem.isEnabled = false
            menu.addItem(noIfaceItem)
        } else {
            // Detect current DNS to show checkmark
            let currentDNS = DnsManager.GetCurrentDNS(for: interfaces[0])

            for profile in profileStore.profiles {
                let item = NSMenuItem(
                    title: profile.name,
                    action: #selector(SelectProfile(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = profile.id

                if Set(profile.servers) == Set(currentDNS) {
                    item.state = .on
                    if profileStore.activeProfileId != profile.id {
                        DispatchQueue.main.async {
                            self.profileStore.activeProfileId = profile.id
                        }
                    }
                }

                menu.addItem(item)
            }

            menu.addItem(.separator())

            let offItem = NSMenuItem(
                title: "Off (DHCP)",
                action: #selector(ResetDNS(_:)),
                keyEquivalent: ""
            )
            offItem.target = self
            if currentDNS.isEmpty {
                offItem.state = .on
            }
            menu.addItem(offItem)
        }

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences\u{2026}",
            action: #selector(OpenPreferences(_:)),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(Quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func SelectProfile(_ sender: NSMenuItem) {
        guard let profileId = sender.representedObject as? UUID,
              let profile = profileStore.profiles.first(where: { $0.id == profileId })
        else { return }

        DnsManager.ApplyProfile(profile, toAllInterfaces: profileStore.applyToAll)
        profileStore.activeProfileId = profile.id
    }

    @objc private func ResetDNS(_ sender: NSMenuItem) {
        DnsManager.ResetToDefault(toAllInterfaces: profileStore.applyToAll)
        profileStore.activeProfileId = nil
    }

    @objc private func OpenPreferences(_ sender: NSMenuItem) {
        onShowSettings()
    }

    @objc private func Quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}
