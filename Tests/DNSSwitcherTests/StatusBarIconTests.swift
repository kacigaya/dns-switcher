import AppKit
import XCTest
@testable import DNSSwitcher

final class StatusBarIconTests: XCTestCase {
    func testIsTemplateAtMenuBarSize() {
        let image = StatusBarIcon.make()
        XCTAssertTrue(image.isTemplate)
        XCTAssertEqual(image.size, NSSize(width: 18, height: 18))
    }

    @MainActor
    func testDrawsGlyphInsideCanvas() throws {
        let rep = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 36, pixelsHigh: 36, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        StatusBarIcon.make().draw(in: NSRect(x: 0, y: 0, width: 36, height: 36))
        NSGraphicsContext.restoreGraphicsState()

        // The centre lies on the globe's equator; the corners stay clear of the ring.
        XCTAssertGreaterThan(rep.colorAt(x: 18, y: 18)?.alphaComponent ?? 0, 0.5)
        for (x, y) in [(0, 0), (35, 0), (0, 35), (35, 35)] {
            XCTAssertEqual(rep.colorAt(x: x, y: y)?.alphaComponent ?? 1, 0, "corner \(x),\(y)")
        }
    }
}
