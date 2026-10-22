import SwiftUI

/// Shown in place of the profile list when no profiles exist.
struct EmptyProfilesView: View {
    let onAdd: () -> Void

    var body: some View {
        if #available(macOS 14.0, *) {
            ContentUnavailableView {
                Label("No Profiles", systemImage: "tray")
            } description: {
                Text("Add a profile to switch DNS from the menu bar.")
            } actions: {
                Button("Add Profile", action: onAdd)
                    .liquidGlassButtonStyle()
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("No Profiles")
                    .font(.headline)
                Text("Add a profile to switch DNS from the menu bar.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Add Profile", action: onAdd)
                    .liquidGlassButtonStyle()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
