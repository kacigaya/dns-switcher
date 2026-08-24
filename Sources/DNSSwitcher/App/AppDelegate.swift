import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let profileStore = ProfileStore()
    private var statusBarController: StatusBarController?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Close any windows that SwiftUI's Settings scene auto-created
        for window in NSApp.windows {
            window.close()
        }

        statusBarController = StatusBarController(profileStore: profileStore) { [weak self] in
            self?.showSettings()
        }
    }

    private func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            activate()
            return
        }

        let settingsView = SettingsView()
            .environmentObject(profileStore)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "DNS Switcher Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        // The window is recreated on demand, so there is no state to restore.
        window.isRestorable = false
        window.makeKeyAndOrderFront(nil)
        activate()

        self.settingsWindow = window
    }

    private func activate() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
