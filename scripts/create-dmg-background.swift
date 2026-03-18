#!/usr/bin/env swift

import AppKit

let width = 660
let height = 400
let size = NSSize(width: width, height: height)
let image = NSImage(size: size)

image.lockFocus()

// Background gradient
let gradient = NSGradient(starting: NSColor(calibratedWhite: 0.95, alpha: 1.0),
                          ending: NSColor(calibratedWhite: 0.88, alpha: 1.0))!
gradient.draw(in: NSRect(origin: .zero, size: size), angle: 270)

// Arrow
let arrowPath = NSBezierPath()
let centerY = CGFloat(height) / 2.0
let arrowLeft: CGFloat = 260
let arrowRight: CGFloat = 400
let arrowMidX = (arrowLeft + arrowRight) / 2.0
let shaftHalf: CGFloat = 12
let headHalf: CGFloat = 30
let headStart: CGFloat = 350

// Shaft
arrowPath.move(to: NSPoint(x: arrowLeft, y: centerY - shaftHalf))
arrowPath.line(to: NSPoint(x: headStart, y: centerY - shaftHalf))
// Head
arrowPath.line(to: NSPoint(x: headStart, y: centerY - headHalf))
arrowPath.line(to: NSPoint(x: arrowRight, y: centerY))
arrowPath.line(to: NSPoint(x: headStart, y: centerY + headHalf))
arrowPath.line(to: NSPoint(x: headStart, y: centerY + shaftHalf))
arrowPath.line(to: NSPoint(x: arrowLeft, y: centerY + shaftHalf))
arrowPath.close()

NSColor(calibratedWhite: 0.55, alpha: 0.6).setFill()
arrowPath.fill()

// "Drag to install" text
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.4, alpha: 0.8),
    .paragraphStyle: paragraphStyle
]
let text = "Drag to Applications to install"
let textRect = NSRect(x: 0, y: 40, width: CGFloat(width), height: 30)
text.draw(in: textRect, withAttributes: attrs)

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmapRep = NSBitmapImageRep(data: tiffData),
      let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("Failed to generate image")
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-background.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Created \(outputPath)")
