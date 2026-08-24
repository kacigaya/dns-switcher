import SwiftUI

/// Sheet for creating or editing a single DNS profile.
struct ProfileEditorView: View {
    @State private var name: String
    @State private var serversText: String
    @State private var validationMessage: String?
    @FocusState private var nameFieldIsFocused: Bool

    private let profileId: UUID
    private let title: String
    let onCancel: () -> Void
    let onSave: (DnsProfile) -> Void

    init(
        profile: DnsProfile,
        title: String,
        onCancel: @escaping () -> Void,
        onSave: @escaping (DnsProfile) -> Void
    ) {
        self.profileId = profile.id
        self.title = title
        self._name = State(initialValue: profile.name)
        self._serversText = State(initialValue: profile.servers.joined(separator: ", "))
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(.headline, design: .rounded))

            VStack(spacing: 12) {
                TextField("Name", text: $name)
                    .focused($nameFieldIsFocused)
                TextField("DNS servers", text: $serversText, prompt: Text("8.8.8.8, 1.1.1.1"))
            }
            .textFieldStyle(.roundedBorder)
            // macOS 13 predates the zero-argument onChange overload.
            .onChange(of: name) { _ in validationMessage = nil }
            .onChange(of: serversText) { _ in validationMessage = nil }

            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LiquidGlassContainer(spacing: 12) {
                HStack {
                    Button("Cancel", action: onCancel)
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
        .onAppear { nameFieldIsFocused = true }
    }

    private func save() {
        let candidate = DnsProfile(
            id: profileId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            servers: DnsProfile.parseServers(serversText)
        )

        if let error = candidate.validationError {
            validationMessage = error.message
            return
        }

        validationMessage = nil
        onSave(candidate)
    }
}
