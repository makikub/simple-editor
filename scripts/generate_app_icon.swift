#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let distribution = root.appendingPathComponent("Distribution", isDirectory: true)
let docs = root.appendingPathComponent("docs", isDirectory: true)
let iconset = distribution.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icns = distribution.appendingPathComponent("AppIcon.icns")
let preview = docs.appendingPathComponent("icon.png")

try FileManager.default.createDirectory(at: distribution, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawIcon(size: Int) throws -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else {
        throw NSError(domain: "SimpleEditorIcon", code: 1)
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let corner = CGFloat(size) * 0.22
    let outer = CGPath(
        roundedRect: rect.insetBy(dx: CGFloat(size) * 0.045, dy: CGFloat(size) * 0.045),
        cornerWidth: corner,
        cornerHeight: corner,
        transform: nil
    )

    context.saveGState()
    context.addPath(outer)
    context.clip()

    let colors = [
        NSColor(calibratedRed: 0.86, green: 0.96, blue: 1.00, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.42, green: 0.82, blue: 0.84, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.09, green: 0.32, blue: 0.46, alpha: 1).cgColor
    ] as CFArray
    let locations: [CGFloat] = [0, 0.52, 1]
    let space = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations)!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: CGFloat(size) * 0.1, y: CGFloat(size) * 0.95),
        end: CGPoint(x: CGFloat(size) * 0.9, y: CGFloat(size) * 0.08),
        options: []
    )

    let glass = NSBezierPath(
        roundedRect: NSRect(
            x: CGFloat(size) * 0.16,
            y: CGFloat(size) * 0.2,
            width: CGFloat(size) * 0.68,
            height: CGFloat(size) * 0.66
        ),
        xRadius: CGFloat(size) * 0.08,
        yRadius: CGFloat(size) * 0.08
    )
    NSColor(calibratedWhite: 1, alpha: 0.28).setFill()
    glass.fill()

    NSColor(calibratedWhite: 1, alpha: 0.5).setStroke()
    glass.lineWidth = max(2, CGFloat(size) * 0.012)
    glass.stroke()

    let highlight = NSBezierPath()
    highlight.move(to: NSPoint(x: CGFloat(size) * 0.25, y: CGFloat(size) * 0.76))
    highlight.curve(
        to: NSPoint(x: CGFloat(size) * 0.74, y: CGFloat(size) * 0.7),
        controlPoint1: NSPoint(x: CGFloat(size) * 0.4, y: CGFloat(size) * 0.88),
        controlPoint2: NSPoint(x: CGFloat(size) * 0.63, y: CGFloat(size) * 0.83)
    )
    NSColor(calibratedWhite: 1, alpha: 0.5).setStroke()
    highlight.lineWidth = max(3, CGFloat(size) * 0.018)
    highlight.lineCapStyle = .round
    highlight.stroke()

    let lineColor = NSColor(calibratedRed: 0.08, green: 0.25, blue: 0.34, alpha: 0.58)
    lineColor.setStroke()
    for index in 0..<4 {
        let y = CGFloat(size) * (0.61 - CGFloat(index) * 0.105)
        let path = NSBezierPath()
        path.move(to: NSPoint(x: CGFloat(size) * 0.28, y: y))
        path.line(to: NSPoint(x: CGFloat(size) * (index == 3 ? 0.58 : 0.72), y: y))
        path.lineWidth = max(3, CGFloat(size) * 0.016)
        path.lineCapStyle = .round
        path.stroke()
    }

    let caret = NSBezierPath()
    caret.move(to: NSPoint(x: CGFloat(size) * 0.42, y: CGFloat(size) * 0.33))
    caret.line(to: NSPoint(x: CGFloat(size) * 0.42, y: CGFloat(size) * 0.63))
    NSColor(calibratedRed: 0.04, green: 0.18, blue: 0.24, alpha: 0.74).setStroke()
    caret.lineWidth = max(4, CGFloat(size) * 0.022)
    caret.lineCapStyle = .round
    caret.stroke()

    context.restoreGState()

    NSColor(calibratedWhite: 1, alpha: 0.42).setStroke()
    let rim = NSBezierPath(
        roundedRect: NSRect(
            x: CGFloat(size) * 0.055,
            y: CGFloat(size) * 0.055,
            width: CGFloat(size) * 0.89,
            height: CGFloat(size) * 0.89
        ),
        xRadius: corner,
        yRadius: corner
    )
    rim.lineWidth = max(2, CGFloat(size) * 0.01)
    rim.stroke()

    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "SimpleEditorIcon", code: 2)
    }
    try data.write(to: url)
}

let variants: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for variant in variants {
    try writePNG(drawIcon(size: variant.size), to: iconset.appendingPathComponent(variant.name))
}

try writePNG(drawIcon(size: 512), to: preview)

try? FileManager.default.removeItem(at: icns)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    throw NSError(domain: "SimpleEditorIcon", code: Int(process.terminationStatus))
}

try FileManager.default.removeItem(at: iconset)
print(icns.path)
print(preview.path)
