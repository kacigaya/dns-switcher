import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @State private var selection: UUID?
    @State private var editorSubject: EditorSubject?
    @State private var isConfirmingDeletion = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    /// The profile being edited plus whether it is new, so the sheet can be
    /// driven by a single optional value.
    private struct EditorSubject: Identifiable {
        let profile: DnsProfile
        let isNew: Bool

        var id: UUID { profile.id }
        var title: String { isNew ? "New Profile" : "Edit Profile" }
    }

    var body: some View {
        LiquidGlassContainer(spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                Text("DNS Switcher")
                    .font(.system(.title2, design: .rounded).weight(.semibold))

                profilesCard
                optionsCard

                if let loginItemError {
                    Label(loginItemError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
                footer
            }
            .padding(22)
        }
        .frame(width: 460, height: 560)
        .background(.ultraThinMaterial)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
        .sheet(item: $editorSubject) { subject in
            ProfileEditorView(
                profile: subject.profile,
                title: subject.title,
                onCancel: { editorSubject = nil }
            ) { updated in
                saveProfile(updated)
                editorSubject = nil
            }
        }
        .confirmationDialog(
            "Delete \(selectedProfile?.name ?? "profile")?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteSelected)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This profile will be removed. Your current DNS settings stay unchanged.")
        }
    }

    // MARK: - Profiles

    private var profilesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILES")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            profileList
            toolbar
        }
        .padding(16)
        .liquidGlass(in: .rect(cornerRadius: 20))
    }

    @ViewBuilder
    private var profileList: some View {
        if profileStore.profiles.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No profiles yet")
                    .font(.callout.weight(.medium))
                Text("Add a profile to switch DNS from the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .accessibilityElement(children: .combine)
        } else {
            List(selection: $selection) {
                ForEach(profileStore.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isActive: profile.id == profileStore.activeProfileId,
                        isSelected: profile.id == selection
                    )
                    .tag(profile.id)
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
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button("Add profile", systemImage: "plus", action: addProfile)
                .liquidGlassButtonStyle()

            Button("Remove profile", systemImage: "minus", action: requestDeletion)
                .liquidGlassButtonStyle()
                .disabled(selectedProfile == nil)

            Button("Edit profile", systemImage: "pencil", action: editSelected)
                .liquidGlassButtonStyle()
                .disabled(selectedProfile == nil)

            Spacer()
        }
        // Keeps the compact icon appearance while VoiceOver still reads the titles.
        .labelStyle(.iconOnly)
    }

    // MARK: - Options

    private var optionsCard: some View {
        VStack(spacing: 14) {
            Toggle("Apply to all network interfaces", isOn: $profileStore.applyToAll)
            Divider()
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { setLaunchAtLogin($0) }
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

    private var selectedProfile: DnsProfile? {
        guard let selection else { return nil }
        return profileStore.profiles.first { $0.id == selection }
    }

    private func addProfile() {
        editorSubject = EditorSubject(
            profile: DnsProfile(name: "New Profile", servers: ["1.1.1.1"]),
            isNew: true
        )
    }

    private func editSelected() {
        guard let selectedProfile else { return }
        editorSubject = EditorSubject(profile: selectedProfile, isNew: false)
    }

    private func requestDeletion() {
        guard selectedProfile != nil else { return }
        isConfirmingDeletion = true
    }

    private func deleteSelected() {
        guard let profile = selectedProfile else { return }

        profileStore.profiles.removeAll { $0.id == profile.id }
        if profileStore.activeProfileId == profile.id {
            profileStore.activeProfileId = nil
        }
        selection = nil
    }

    private func saveProfile(_ profile: DnsProfile) {
        if let index = profileStore.profiles.firstIndex(where: { $0.id == profile.id }) {
            profileStore.profiles[index] = profile
        } else {
            profileStore.profiles.append(profile)
        }
        selection = profile.id
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
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
