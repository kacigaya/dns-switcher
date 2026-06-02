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
        Form {
            Section("Profiles") {
                List(selection: $selection) {
                    ForEach(profileStore.profiles) { profile in
                        ProfileRow(profile: profile, isActive: profile.id == profileStore.activeProfileId)
                            .tag(profile.id)
                    }
                    .onMove { indices, destination in
                        profileStore.profiles.move(fromOffsets: indices, toOffset: destination)
                    }
                }
                .frame(minHeight: 180)
                .listStyle(.bordered)

                LiquidGlassContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: AddProfile) {
                            Image(systemName: "plus")
                                .frame(width: 20, height: 16)
                        }
                        .help("Add profile")
                        .liquidGlassButtonStyle()

                        Button(action: RemoveSelected) {
                            Image(systemName: "minus")
                                .frame(width: 20, height: 16)
                        }
                        .help("Remove profile")
                        .liquidGlassButtonStyle()
                        .disabled(selection == nil)

                        Button {
                            guard let sel = selection,
                                  let profile = profileStore.profiles.first(where: { $0.id == sel })
                            else { return }
                            editingProfile = profile
                            showingEditor = true
                        } label: {
                            Image(systemName: "pencil")
                                .frame(width: 20, height: 16)
                        }
                        .help("Edit profile")
                        .liquidGlassButtonStyle()
                        .disabled(selection == nil)

                        Spacer()
                    }
                }
            }

            Section {
                Toggle("Apply to all network interfaces", isOn: $profileStore.applyToAll)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            loginItemError = nil
                        } catch {
                            launchAtLogin = !newValue
                            loginItemError = error.localizedDescription
                        }
                    }

                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 460)
        .sheet(isPresented: $showingEditor) {
            if let profile = editingProfile {
                ProfileEditorView(
                    profile: profile,
                    onCancel: { showingEditor = false }
                ) { updated in
                    if let idx = profileStore.profiles.firstIndex(where: { $0.id == updated.id }) {
                        profileStore.profiles[idx] = updated
                    }
                    showingEditor = false
                }
            }
        }
    }

    private func AddProfile() {
        let newProfile = DnsProfile(name: "New Profile", servers: ["8.8.8.8"])
        profileStore.profiles.append(newProfile)
        selection = newProfile.id
        editingProfile = newProfile
        showingEditor = true
    }

    private func RemoveSelected() {
        guard let sel = selection else { return }
        profileStore.profiles.removeAll { $0.id == sel }
        selection = nil
    }
}

private struct ProfileRow: View {
    let profile: DnsProfile
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.25))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.body)
                    .lineLimit(1)

                Text(profile.servers.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .modifier(ActiveRowGlass(isActive: isActive))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isActive ? "\(profile.name), active" : profile.name)
    }
}

/// Adds a green-tinted Liquid Glass capsule behind the active profile row;
/// inactive rows render unchanged.
private struct ActiveRowGlass: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.liquidGlass(in: .capsule, tint: .green.opacity(0.6))
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
                .font(.headline)

            Form {
                TextField("Name", text: $profile.name)
                TextField("DNS servers", text: $serversText, prompt: Text("8.8.8.8, 1.1.1.1"))
            }
            .formStyle(.grouped)
            .frame(minHeight: 110)

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

                    Button("Save", action: Save)
                        .keyboardShortcut(.defaultAction)
                        .liquidGlassButtonStyle(prominent: true)
                }
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func Save() {
        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            validationError = "Profile name cannot be empty."
            return
        }

        if trimmedName.count > 50 {
            validationError = "Profile name must be 50 characters or fewer."
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
            if !IsValidIP(server) {
                validationError = "\"\(server)\" is not a valid IPv4 or IPv6 address."
                return
            }
        }

        profile.servers = servers
        validationError = nil
        onSave(profile)
    }

    private func IsValidIP(_ string: String) -> Bool {
        var sin = sockaddr_in()
        if inet_pton(AF_INET, string, &sin.sin_addr) == 1 { return true }
        var sin6 = sockaddr_in6()
        if inet_pton(AF_INET6, string, &sin6.sin6_addr) == 1 { return true }
        return false
    }
}
