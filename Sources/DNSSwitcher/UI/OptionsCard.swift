import ServiceManagement
import SwiftUI

/// App-wide switches: which interfaces to change and the login item.
struct OptionsCard: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Apply to all network interfaces", isOn: $profileStore.applyToAll)
            Divider()
            Toggle("Launch at login", isOn: $launchAtLogin)
                // macOS 13 predates the zero-argument onChange overload.
                .onChange(of: launchAtLogin) { setLaunchAtLogin($0) }

            if let loginItemError {
                Label(loginItemError, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .padding(18)
        .liquidGlass(in: .rect(cornerRadius: 20))
        .onAppear(perform: syncLaunchAtLogin)
    }

    /// The login item can change in System Settings while this window is closed.
    private func syncLaunchAtLogin() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        // Skip when the toggle is only catching up with the real status,
        // which also stops the error path below from looping.
        guard enabled != (SMAppService.mainApp.status == .enabled) else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
            // Reflect the state that actually applied.
            syncLaunchAtLogin()
        }
    }
}
