import SwiftUI

/// The profile list with its add, remove, and edit controls.
struct ProfilesCard: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Binding var selection: UUID?
    let onAdd: () -> Void
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profiles")
                .font(.headline)

            Group {
                if profileStore.profiles.isEmpty {
                    EmptyProfilesView(onAdd: onAdd)
                } else {
                    profileList
                }
            }
            .frame(height: 210)

            HStack(spacing: 10) {
                Button("Add Profile", systemImage: "plus", action: onAdd)
                    .help("Add Profile")

                Button("Remove Profile", systemImage: "minus", action: deleteSelected)
                    .help("Remove Selected Profile")
                    .disabled(selection == nil)

                Button("Edit Profile", systemImage: "pencil", action: editSelected)
                    .help("Edit Selected Profile")
                    .disabled(selection == nil)

                Spacer()
            }
            .liquidGlassButtonStyle()
            // Keeps the compact icon appearance while VoiceOver still reads the titles.
            .labelStyle(.iconOnly)
        }
        .padding(16)
        .liquidGlass(in: .rect(cornerRadius: 20))
    }

    private var profileList: some View {
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
            .onMove(perform: moveProfiles)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // Right-click menu, plus double-click or Return to edit a row.
        .contextMenu(forSelectionType: UUID.self) { ids in
            if let id = ids.first {
                Button("Edit") { onEdit(id) }
                Button("Delete", role: .destructive) { onDelete(id) }
            }
        } primaryAction: { ids in
            if let id = ids.first {
                onEdit(id)
            }
        }
        .onDeleteCommand(perform: deleteSelected)
    }

    private func moveProfiles(from source: IndexSet, to destination: Int) {
        profileStore.profiles.move(fromOffsets: source, toOffset: destination)
    }

    private func editSelected() {
        if let selection {
            onEdit(selection)
        }
    }

    private func deleteSelected() {
        if let selection {
            onDelete(selection)
        }
    }
}
