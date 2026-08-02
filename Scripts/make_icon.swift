#!/usr/bin/env swift
//
// make_icon.swift — generate AppIcon.icns from a square source image
// with macOS-style rounded corners.
//
// Usage:
//   swift Scripts/make_icon.swift app-icon.png AppIcon.icns
//
// Produces the standard macOS iconset (10 sizes, 1× and 2×), each with
// the canonical squircle-ish rounded mask and 10% safe-area padding, and
// packs them into the requested .icns via iconutil.

import Foundation
import AppKit

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: make_icon.swift <source.png> <output.icns>\n".utf8))
    exit(1)
}

let sourcePath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let source = NSImage(contentsOfFile: sourcePath) else {
    FileHandle.standardError.write(Data("error: could not load \(sourcePath)\n".utf8))
    exit(1)
}

// macOS app iconset specification — generate 1× and 2× variants.
let entries: [(name: String, px: Int)] = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",     128),
    ("icon_128x128@2x.png",  256),
    ("icon_256x256.png",     256),
    ("icon_256x256@2x.png",  512),
    ("icon_512x512.png",     512),
    ("icon_512x512@2x.png",  1024),
]

func renderMaskedIcon(source: NSImage, sizePx: Int) -> Data? {
    let size = CGFloat(sizePx)

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: sizePx,
        pixelsHigh: sizePx,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Apple's macOS Big Sur+ template: ~10% safe-area padding, with
    // the icon content masked by a rounded square (~22.5% radius).
    let inset = size * 0.10
    let content = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let radius = content.width * 0.225

    let path = NSBezierPath(roundedRect: content, xRadius: radius, yRadius: radius)
    path.addClip()

    source.draw(in: content, from: .zero, operation: .copy, fraction: 1.0)
    return rep.representation(using: .png, properties: [:])
}

let iconsetDir = (outputPath as NSString).deletingPathExtension + ".iconset"
let fm = FileManager.default

try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

for entry in entries {
    guard let data = renderMaskedIcon(source: source, sizePx: entry.px) else {
        FileHandle.standardError.write(Data("error: render failed for \(entry.name)\n".utf8))
        exit(1)
    }
    let dest = (iconsetDir as NSString).appendingPathComponent(entry.name)
    try data.write(to: URL(fileURLWithPath: dest))
    print("  + \(entry.name)  \(entry.px)x\(entry.px)")
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", outputPath]
let errPipe = Pipe()
task.standardError = errPipe
try task.run()
task.waitUntilExit()

guard task.terminationStatus == 0 else {
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
    FileHandle.standardError.write(errData)
    FileHandle.standardError.write(Data("error: iconutil exited \(task.terminationStatus)\n".utf8))
    exit(1)
}

try? fm.removeItem(atPath: iconsetDir)
print("✓ wrote \(outputPath)")
