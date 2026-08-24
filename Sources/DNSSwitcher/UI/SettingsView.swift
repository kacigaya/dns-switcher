import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @State private var selection: UUID?
    @State private var editingProfile: DnsProfile?
    @State private var showingEditor = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        LiquidGlassContainer(spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                Text("DNS Switcher")
                    .font(.system(.title2, design: .rounded).weight(.semibold))

                profilesCard
                optionsCard

                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer(minLength: 0)
                footer
            }
            .padding(22)
        }
        .frame(width: 460, height: 560)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingEditor) {
            if let profile = editingProfile {
                ProfileEditorView(
                    profile: profile,
                    onCancel: { showingEditor = false }
                ) { updated in
                    if let idx = profileStore.profiles.firstIndex(where: { $0.id == updated.id }) {
                        profileStore.profiles[idx] = updated
                    } else {
                        profileStore.profiles.append(updated)
                    }
                    selection = updated.id
                    showingEditor = false
                }
            }
        }
    }

    // MARK: - Profiles

    private var profilesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILES")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            List {
                ForEach(profileStore.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isActive: profile.id == profileStore.activeProfileId,
                        isSelected: profile.id == selection
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selection = profile.id }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                .onMove { indices, destination in
                    profileStore.profiles.move(fromOffsets: indices, toOffset: destination)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(height: 210)

            toolbar
        }
        .padding(16)
        .liquidGlass(in: .rect(cornerRadius: 20))
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button(action: addProfile) {
                Image(systemName: "plus").frame(width: 22, height: 18)
            }
            .help("Add profile")
            .liquidGlassButtonStyle()

            Button(action: removeSelected) {
                Image(systemName: "minus").frame(width: 22, height: 18)
            }
            .help("Remove profile")
            .liquidGlassButtonStyle()
            .disabled(selection == nil)

            Button(action: editSelected) {
                Image(systemName: "pencil").frame(width: 22, height: 18)
            }
            .help("Edit profile")
            .liquidGlassButtonStyle()
            .disabled(selection == nil)

            Spacer()
        }
    }

    // MARK: - Options

    private var optionsCard: some View {
        VStack(spacing: 14) {
            Toggle("Apply to all network interfaces", isOn: $profileStore.applyToAll)
            Divider()
            Toggle(
                "Launch at login",
                isOn: Binding(get: { launchAtLogin }, set: setLaunchAtLogin)
            )
        }
        .toggleStyle(.switch)
        .padding(18)
        .liquidGlass(in: .rect(cornerRadius: 20))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .keyboardShortcut("q")
            .liquidGlassButtonStyle()

            Spacer()

            Button("Done") {
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.defaultAction)
            .liquidGlassButtonStyle(prominent: true)
        }
    }

    // MARK: - Actions

    private func addProfile() {
        let newProfile = DnsProfile(name: "New Profile", servers: ["8.8.8.8"])
        editingProfile = newProfile
        showingEditor = true
    }

    private func removeSelected() {
        guard let sel = selection else { return }
        profileStore.profiles.removeAll { $0.id == sel }
        if profileStore.activeProfileId == sel {
            profileStore.activeProfileId = nil
        }
        selection = nil
    }

    private func editSelected() {
        guard let sel = selection,
              let profile = profileStore.profiles.first(where: { $0.id == sel })
        else { return }
        editingProfile = profile
        showingEditor = true
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
    }
}

private struct ProfileRow: View {
    let profile: DnsProfile
    let isActive: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 9, height: 9)
                .shadow(color: isActive ? .green.opacity(0.6) : .clear, radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                Text(profile.servers.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 14)
        .modifier(SelectedRowGlass(isSelected: isSelected, isActive: isActive))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isActive ? "\(profile.name), active" : profile.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Highlights a selected profile row with Liquid Glass; active rows get a green tint.
private struct SelectedRowGlass: ViewModifier {
    let isSelected: Bool
    let isActive: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content.liquidGlass(
                in: .rect(cornerRadius: 12),
                tint: isActive ? .green.opacity(0.55) : .accentColor.opacity(0.55),
                interactive: true
            )
        } else if isActive {
            content.background(.green.opacity(0.12), in: .rect(cornerRadius: 12))
        } else {
            content
        }
    }
}

struct ProfileEditorView: View {
    @State var profile: DnsProfile
    @State private var serversText: String
    @State private var validationError: String?

    let onCancel: () -> Void
    let onSave: (DnsProfile) -> Void

    init(profile: DnsProfile, onCancel: @escaping () -> Void, onSave: @escaping (DnsProfile) -> Void) {
        self._profile = State(initialValue: profile)
        self._serversText = State(initialValue: profile.servers.joined(separator: ", "))
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Profile")
                .font(.system(.headline, design: .rounded))

            VStack(spacing: 12) {
                TextField("Name", text: $profile.name)
                TextField("DNS servers", text: $serversText, prompt: Text("8.8.8.8, 1.1.1.1"))
            }
            .textFieldStyle(.roundedBorder)

            if let error = validationError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            LiquidGlassContainer(spacing: 12) {
                HStack {
                    Button("Cancel") { onCancel() }
                        .keyboardShortcut(.cancelAction)
                        .liquidGlassButtonStyle()

                    Spacer()

                    Button("Save", action: save)
                        .keyboardShortcut(.defaultAction)
                        .liquidGlassButtonStyle(prominent: true)
                }
            }
        }
        .padding(22)
        .frame(width: 380)
        .background(.ultraThinMaterial)
    }

    private func save() {
        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            validationError = "Profile name cannot be empty."
            return
        }

        if trimmedName.count > ProfileStore.maxProfileNameLength {
            validationError = "Profile name must be \(ProfileStore.maxProfileNameLength) characters or fewer."
            return
        }

        profile.name = trimmedName

        let servers = serversText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if servers.isEmpty {
            validationError = "At least one DNS server is required."
            return
        }

        for server in servers {
            if !ProfileStore.isValidIPAddress(server) {
                validationError = "\"\(server)\" is not a valid IPv4 or IPv6 address."
                return
            }
        }

        profile.servers = servers
        validationError = nil
        onSave(profile)
    }
}
