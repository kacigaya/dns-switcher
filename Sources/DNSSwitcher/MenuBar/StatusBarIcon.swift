import AppKit

/// Menu bar glyph: a globe inside two circular arrows, a one-colour version of
/// the app icon. It is drawn in code because the Makefile copies only the
/// executable into the app bundle, so a SwiftPM resource bundle would be missing.
enum StatusBarIcon {
    static let size = NSSize(width: 18, height: 18)

    static func make() -> NSImage {
        // Flipped so y grows downward and angles increase clockwise on screen.
        let image = NSImage(size: size, flipped: true) { _ in
            draw()
            return true
        }
        // A template image lets macOS tint it for light, dark and highlighted menu bars.
        image.isTemplate = true
        image.accessibilityDescription = "DNS Switcher"
        return image
    }

    private static func draw() {
        let center = NSPoint(x: 9, y: 9)
        let ringRadius: CGFloat = 7.4
        let headLength: CGFloat = 2.9
        let headHalfWidth: CGFloat = 2.2

        func point(_ degrees: CGFloat, _ radius: CGFloat) -> NSPoint {
            let t = degrees * .pi / 180
            return NSPoint(x: center.x + radius * cos(t), y: center.y + radius * sin(t))
        }

        NSColor.black.set()

        // Two clockwise arrows; each head sits at the end angle.
        for (start, end) in [(CGFloat(198), CGFloat(322)), (18, 142)] {
            let headDegrees = headLength / ringRadius * 180 / .pi
            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: ringRadius, startAngle: start,
                          endAngle: end - headDegrees * 0.6, clockwise: false)
            arc.lineWidth = 1.6
            arc.lineCapStyle = .round
            arc.stroke()

            let base = end - headDegrees
            let head = NSBezierPath()
            head.move(to: point(base, ringRadius + headHalfWidth))
            head.line(to: point(end + 2, ringRadius))
            head.line(to: point(base, ringRadius - headHalfWidth))
            head.close()
            head.fill()
        }

        // Globe: outline, one meridian and the equator.
        let globeRadius: CGFloat = 4.1
        let meridianRadius: CGFloat = 1.75
        let globe = NSBezierPath(ovalIn: NSRect(x: center.x - globeRadius, y: center.y - globeRadius,
                                                width: globeRadius * 2, height: globeRadius * 2))
        globe.append(NSBezierPath(ovalIn: NSRect(x: center.x - meridianRadius, y: center.y - globeRadius,
                                                 width: meridianRadius * 2, height: globeRadius * 2)))
        globe.move(to: NSPoint(x: center.x - globeRadius, y: center.y))
        globe.line(to: NSPoint(x: center.x + globeRadius, y: center.y))
        globe.lineWidth = 1.1
        globe.stroke()
    }
}
