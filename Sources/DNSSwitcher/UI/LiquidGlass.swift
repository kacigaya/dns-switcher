import SwiftUI

// Liquid Glass helpers.
//
// The real APIs (`glassEffect`, `GlassEffectContainer`, `buttonStyle(.glass)`)
// require macOS 26+. The app deploys to macOS 13, so every call site is gated
// behind `#available` with a sensible fallback for earlier systems.

extension View {
    /// Applies Liquid Glass behind the view, falling back to a material on < macOS 26.
    @ViewBuilder
    func liquidGlass<S: Shape>(
        in shape: S,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(Self.makeGlass(tint: tint, interactive: interactive), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    @available(macOS 26.0, *)
    private static func makeGlass(tint: Color?, interactive: Bool) -> Glass {
        var glass: Glass = .regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }

    /// Liquid Glass button style with a bordered fallback on < macOS 26.
    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            if prominent {
                self.buttonStyle(.borderedProminent)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }
}

/// Wraps content in a `GlassEffectContainer` on macOS 26+ so adjacent glass
/// shapes blend and morph; otherwise passes content through unchanged.
struct LiquidGlassContainer<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: Content

    init(spacing: CGFloat = 20.0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}
