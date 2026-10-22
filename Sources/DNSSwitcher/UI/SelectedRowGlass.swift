import SwiftUI

/// Highlights a selected profile row with Liquid Glass; active rows get a green tint.
struct SelectedRowGlass: ViewModifier {
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
