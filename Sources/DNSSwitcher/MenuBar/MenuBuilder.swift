import AppKit

@MainActor
final class MenuBuilder: NSObject {
    private let profileStore: ProfileStore
    private let onShowSettings: () -> Void

    /// Called after the DNS configuration is changed, so the owner can refresh
    /// its snapshot. Set by the owner once it has finished initializing.
    var onDnsChanged: (() -> Void)?

    /// State the visible menu was built from; also drives the menu actions so
    /// applying a profile does not have to re-enumerate network services.
    private var snapshot: DnsSnapshot?

    init(profileStore: ProfileStore, onShowSettings: @escaping () -> Void) {
        self.profileStore = profileStore
        self.onShowSettings = onShowSettings
    }

    /// Rebuilds `menu` from `snapshot`. A nil snapshot means the DNS state has
    /// not been read yet, so the profile section shows a placeholder instead.
    func buildMenu(_ menu: NSMenu, snapshot: DnsSnapshot?) {
        self.snapshot = snapshot
        menu.removeAllItems()

        if let snapshot {
            addProfileItems(to: menu, snapshot: snapshot)
        } else {
            addDisabledItem(to: menu, title: "Reading DNS settings\u{2026}")
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

    private func addProfileItems(to menu: NSMenu, snapshot: DnsSnapshot) {
        guard !snapshot.interfaces.isEmpty else {
            profileStore.activeProfileId = nil
            addDisabledItem(to: menu, title: "No active interfaces")
            return
        }

        let applyToAll = profileStore.applyToAll
        let activeProfileId = snapshot
            .matchingProfile(among: profileStore.profiles, applyToAll: applyToAll)?
            .id

        if profileStore.activeProfileId != activeProfileId {
            profileStore.activeProfileId = activeProfileId
        }

        if profileStore.profiles.isEmpty {
            addDisabledItem(to: menu, title: "No profiles \u{2014} add one in Preferences")
        }

        for profile in profileStore.profiles {
            let item = NSMenuItem(
                title: profile.name,
                action: #selector(selectProfile(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = profile.id
            item.toolTip = profile.servers.joined(separator: ", ")

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
        if snapshot.usesAutomaticDns(applyToAll: applyToAll) {
            offItem.state = .on
        }
        menu.addItem(offItem)
    }

    private func addDisabledItem(to menu: NSMenu, title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    /// Interfaces the current settings target, based on the menu's snapshot.
    private var targetedInterfaces: [String] {
        snapshot?.targetedInterfaces(applyToAll: profileStore.applyToAll) ?? []
    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard let profileId = sender.representedObject as? UUID,
              let profile = profileStore.profiles.first(where: { $0.id == profileId })
        else { return }

        if DnsManager.applyProfile(profile, to: targetedInterfaces) {
            profileStore.activeProfileId = profile.id
        } else {
            profileStore.activeProfileId = nil
        }
        onDnsChanged?()
    }

    @objc private func resetDNS(_ sender: NSMenuItem) {
        if DnsManager.resetToDefault(on: targetedInterfaces) {
            profileStore.activeProfileId = nil
        }
        onDnsChanged?()
    }

    @objc private func openPreferences(_ sender: NSMenuItem) {
        onShowSettings()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}
