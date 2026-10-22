import SwiftUI

/// One profile in the settings list, showing its name, servers, and whether it
/// is the profile currently applied to the system.
struct ProfileRow: View {
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
                    .lineLimit(1)

                Text(profile.servers.joined(separator: ", "))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isActive {
                // The status dot alone conveys state through color only.
                Image(systemName: "checkmark")
                    .font(.callout.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 14)
        .modifier(SelectedRowGlass(isSelected: isSelected, isActive: isActive))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(profile.name)
        .accessibilityValue(
            isActive
                ? "Active. Servers: \(profile.servers.joined(separator: ", "))"
                : "Servers: \(profile.servers.joined(separator: ", "))"
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
