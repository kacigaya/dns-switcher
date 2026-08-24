import AppKit

final class MenuBuilder: NSObject {
    private let profileStore: ProfileStore
    private let onShowSettings: () -> Void

    init(profileStore: ProfileStore, onShowSettings: @escaping () -> Void) {
        self.profileStore = profileStore
        self.onShowSettings = onShowSettings
    }

    func buildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let interfaces = NetworkInterface.listActiveInterfaces()

        if interfaces.isEmpty {
            profileStore.activeProfileId = nil
            let noIfaceItem = NSMenuItem(title: "No active interfaces", action: nil, keyEquivalent: "")
            noIfaceItem.isEnabled = false
            menu.addItem(noIfaceItem)
        } else {
            // Detect current DNS to show checkmark
            let checkedInterfaces = profileStore.applyToAll ? interfaces : Array(interfaces.prefix(1))
            let currentDNS = checkedInterfaces.compactMap { DnsManager.getCurrentDNS(for: $0) }
            let didReadAll = currentDNS.count == checkedInterfaces.count
            let activeProfileId = didReadAll
                ? profileStore.profiles.first {
                    profile in currentDNS.allSatisfy { DnsManager.dnsServersMatch(profile.servers, $0) }
                }?.id
                : nil
            if profileStore.activeProfileId != activeProfileId {
                profileStore.activeProfileId = activeProfileId
            }

            for profile in profileStore.profiles {
                let item = NSMenuItem(
                    title: profile.name,
                    action: #selector(selectProfile(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = profile.id

                if profile.id == activeProfileId {
                    item.state = .on
                }

                menu.addItem(item)
            }

            menu.addItem(.separator())

            let offItem = NSMenuItem(
                title: "Off (DHCP)",
                action: #selector(resetDNS(_:)),
                keyEquivalent: ""
            )
            offItem.target = self
            if didReadAll && currentDNS.allSatisfy(\.isEmpty) {
                offItem.state = .on
            }
            menu.addItem(offItem)
        }

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences\u{2026}",
            action: #selector(openPreferences(_:)),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard let profileId = sender.representedObject as? UUID,
              let profile = profileStore.profiles.first(where: { $0.id == profileId })
        else { return }

        if DnsManager.applyProfile(profile, toAllInterfaces: profileStore.applyToAll) {
            profileStore.activeProfileId = profile.id
        } else {
            profileStore.activeProfileId = nil
        }
    }

    @objc private func resetDNS(_ sender: NSMenuItem) {
        if DnsManager.resetToDefault(toAllInterfaces: profileStore.applyToAll) {
            profileStore.activeProfileId = nil
        }
    }

    @objc private func openPreferences(_ sender: NSMenuItem) {
        onShowSettings()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}
