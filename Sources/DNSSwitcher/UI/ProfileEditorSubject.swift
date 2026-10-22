import Foundation

/// The profile being edited plus whether it is new, so the editor sheet can be
/// driven by a single optional value.
struct ProfileEditorSubject: Identifiable {
    let profile: DnsProfile
    let isNew: Bool

    var id: UUID { profile.id }
    var title: String { isNew ? "New Profile" : "Edit Profile" }
}
