import AppKit
import SwiftUI

/// Quit, version, and Done controls at the bottom of the settings window.
struct SettingsFooter: View {
    /// Marketing version from the bundle, absent in non-bundled debug builds.
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    var body: some View {
        HStack {
            Button(role: .destructive, action: quit) {
                Label("Quit", systemImage: "power")
            }
            .keyboardShortcut("q")
            .liquidGlassButtonStyle()

            Spacer()

            if let appVersion {
                Text("Version \(appVersion)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Button("Done", action: close)
                .keyboardShortcut(.defaultAction)
                .liquidGlassButtonStyle(prominent: true)
        }
    }

    private func quit() {
        NSApp.terminate(nil)
    }

    private func close() {
        NSApp.keyWindow?.close()
    }
}
