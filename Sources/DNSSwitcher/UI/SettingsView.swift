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
        ZStack {
            LiquidGlassBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Header

                VStack(spacing: 0) {
                    List(selection: $selection) {
                        ForEach(profileStore.profiles) { profile in
                            ProfileRow(profile: profile, isActive: profile.id == profileStore.activeProfileId)
                                .tag(profile.id)
                                .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onMove { indices, destination in
                            profileStore.profiles.move(fromOffsets: indices, toOffset: destination)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.inset)

                    Divider()
                        .opacity(0.45)

                    HStack(spacing: 8) {
                        Button(action: AddProfile) {
                            Label("Add", systemImage: "plus")
                        }

                        Button(action: RemoveSelected) {
                            Label("Remove", systemImage: "minus")
                        }
                        .disabled(selection == nil)

                        Spacer()

                        Button {
                            guard let sel = selection,
                                  let profile = profileStore.profiles.first(where: { $0.id == sel })
                            else { return }
                            editingProfile = profile
                            showingEditor = true
                        } label: {
                            Label("Edit", systemImage: "slider.horizontal.3")
                        }
                        .disabled(selection == nil)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .padding(12)
                }
                .glassPanel()

                VStack(alignment: .leading, spacing: 12) {
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
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .glassPanel()
            }
            .padding(.top, 30)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 460)
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

    private var Header: some View {
        HStack(spacing: 12) {
            Image(systemName: "network")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white, Color.accentColor)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("DNS Switcher")
                    .font(.title2.weight(.semibold))

                Text("Profiles and launch settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(profile.servers.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Active profile")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(isActive ? 0.45 : 0.22), lineWidth: 1)
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
                    onCancel()
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

private struct LiquidGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct GlassPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.32), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }
}

private extension View {
    func glassPanel() -> some View {
        modifier(GlassPanelModifier())
    }
}
