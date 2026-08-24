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
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                Text(profile.servers.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isActive {
                // The status dot alone conveys state through color only.
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
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
