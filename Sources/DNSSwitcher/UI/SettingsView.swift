import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @State private var selection: UUID?
    @State private var editingProfile: DnsProfile?
    @State private var showingEditor = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(profileStore.profiles) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name).fontWeight(.medium)
                            Text(profile.servers.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if profile.id == profileStore.activeProfileId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .tag(profile.id)
                }
                .onMove { indices, destination in
                    profileStore.profiles.move(fromOffsets: indices, toOffset: destination)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            HStack {
                Button(action: AddProfile) {
                    Image(systemName: "plus")
                }
                Button(action: RemoveSelected) {
                    Image(systemName: "minus")
                }
                .disabled(selection == nil)

                Spacer()

                Button("Edit\u{2026}") {
                    guard let sel = selection,
                          let profile = profileStore.profiles.first(where: { $0.id == sel })
                    else { return }
                    editingProfile = profile
                    showingEditor = true
                }
                .disabled(selection == nil)
            }
            .padding(8)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Apply to all network interfaces", isOn: $profileStore.applyToAll)

                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }
            .padding()
        }
        .frame(width: 420, height: 380)
        .sheet(isPresented: $showingEditor) {
            if let profile = editingProfile {
                ProfileEditorView(profile: profile) { updated in
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

struct ProfileEditorView: View {
    @State var profile: DnsProfile
    @State private var serversText: String
    @State private var validationError: String?

    let onSave: (DnsProfile) -> Void

    init(profile: DnsProfile, onSave: @escaping (DnsProfile) -> Void) {
        self._profile = State(initialValue: profile)
        self._serversText = State(initialValue: profile.servers.joined(separator: ", "))
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Profile").font(.headline)

            Form {
                TextField("Name:", text: $profile.name)
                TextField("DNS Servers (comma-separated):", text: $serversText)

                if let error = validationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            HStack {
                Button("Cancel") {
                    onSave(profile) // dismiss without changes — caller handles sheet
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
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
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private func IsValidIP(_ string: String) -> Bool {
        // IPv4
        var sin = sockaddr_in()
        if inet_pton(AF_INET, string, &sin.sin_addr) == 1 { return true }
        // IPv6
        var sin6 = sockaddr_in6()
        if inet_pton(AF_INET6, string, &sin6.sin6_addr) == 1 { return true }
        return false
    }
}
