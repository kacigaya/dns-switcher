import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @State private var selection: UUID?
    @State private var editorSubject: ProfileEditorSubject?
    @State private var isConfirmingDeletion = false
    /// Kept apart from `selection` because the context menu can delete a row
    /// that is not selected.
    @State private var pendingDeletion: DnsProfile?

    var body: some View {
        LiquidGlassContainer(spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                Text("DNS Switcher")
                    .font(.system(.title2, design: .rounded).bold())

                ProfilesCard(
                    selection: $selection,
                    onAdd: addProfile,
                    onEdit: editProfile,
                    onDelete: requestDeletion
                )
                OptionsCard()

                Spacer(minLength: 0)
                SettingsFooter()
            }
            .padding(22)
        }
        .frame(width: 460, height: 560)
        .background(.ultraThinMaterial)
        .sheet(item: $editorSubject) { subject in
            ProfileEditorView(
                profile: subject.profile,
                title: subject.title,
                onCancel: cancelEditing,
                onSave: saveProfile
            )
        }
        .confirmationDialog(
            "Delete \(pendingDeletion?.name ?? "profile")?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { profile in
            Button("Delete", role: .destructive) { deleteProfile(profile) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This profile will be removed. Your current DNS settings stay unchanged.")
        }
    }

    // MARK: - Actions

    private func profile(withId id: UUID) -> DnsProfile? {
        profileStore.profiles.first { $0.id == id }
    }

    private func addProfile() {
        editorSubject = ProfileEditorSubject(
            profile: DnsProfile(name: "New Profile", servers: ["1.1.1.1"]),
            isNew: true
        )
    }

    private func editProfile(_ id: UUID) {
        guard let profile = profile(withId: id) else { return }
        editorSubject = ProfileEditorSubject(profile: profile, isNew: false)
    }

    private func cancelEditing() {
        editorSubject = nil
    }

    private func requestDeletion(_ id: UUID) {
        guard let profile = profile(withId: id) else { return }
        pendingDeletion = profile
        isConfirmingDeletion = true
    }

    private func deleteProfile(_ profile: DnsProfile) {
        profileStore.profiles.removeAll { $0.id == profile.id }
        if profileStore.activeProfileId == profile.id {
            profileStore.activeProfileId = nil
        }
        if selection == profile.id {
            selection = nil
        }
    }

    private func saveProfile(_ profile: DnsProfile) {
        if let index = profileStore.profiles.firstIndex(where: { $0.id == profile.id }) {
            profileStore.profiles[index] = profile
        } else {
            profileStore.profiles.append(profile)
        }
        selection = profile.id
        editorSubject = nil
    }
}
