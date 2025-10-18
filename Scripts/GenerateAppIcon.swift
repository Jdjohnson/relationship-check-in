#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Generate a simple, elegant app icon: solid purple background with a clean heart shape in white.

let canvasSize: Int = 1024
let margin: CGFloat = 112 // breathing room around the heart

func createContext(width: Int, height: Int) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let ctx = CGContext(data: nil,
                              width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bytesPerRow: 0,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo) else {
        fatalError("Failed to create CGContext")
    }
    // Flip to draw in typical top-left origin coordinates
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func drawBackground(in ctx: CGContext) {
    // #5c5adb (DesignSystem.Colors.primaryPurple)
    let purple = CGColor(red: 92/255.0, green: 90/255.0, blue: 219/255.0, alpha: 1)
    ctx.setFillColor(purple)
    ctx.fill(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
}

// Parametric heart curve (nice symmetric heart):
// x(t) = 16 sin^3 t
// y(t) = 13 cos t − 5 cos 2t − 2 cos 3t − cos 4t
// We sample it, normalize to our rect, and fill.
func heartPath(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    var points: [CGPoint] = []
    let samples = 720
    for i in 0..<samples {
        let t = Double(i) * (2.0 * Double.pi) / Double(samples)
        let x = 16.0 * pow(sin(t), 3)
        let y = 13.0 * cos(t) - 5.0 * cos(2.0*t) - 2.0 * cos(3.0*t) - cos(4.0*t)
        points.append(CGPoint(x: x, y: y))
    }
    // Compute bounds
    var minX = Double.infinity, maxX = -Double.infinity
    var minY = Double.infinity, maxY = -Double.infinity
    for p in points {
        if p.x < minX { minX = p.x }
        if p.x > maxX { maxX = p.x }
        if p.y < minY { minY = p.y }
        if p.y > maxY { maxY = p.y }
    }
    let srcWidth = maxX - minX
    let srcHeight = maxY - minY
    // Scale to fit inside rect while preserving aspect ratio
    let scale = min(rect.width / CGFloat(srcWidth), rect.height / CGFloat(srcHeight))
    let center = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04) // slight vertical tweak
    func map(_ p: CGPoint) -> CGPoint {
        let x = ((p.x - minX) * Double(scale)) + Double(rect.minX)
        let y = ((p.y - minY) * Double(scale)) + Double(rect.minY)
        // Convert to CoreGraphics flipped Y by reflecting around rect midY
        let cg = CGPoint(x: x, y: y)
        let dy = cg.y - rect.midY
        return CGPoint(x: CGFloat(cg.x), y: center.y - dy)
    }
    guard let first = points.first.map(map) else { return path }
    path.move(to: first)
    for p in points.dropFirst() {
        path.addLine(to: map(p))
    }
    path.closeSubpath()
    return path
}

func writePNG(from image: CGImage, to url: URL) throws {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "GenerateAppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        throw NSError(domain: "GenerateAppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize PNG"])
    }
}

// Paths
let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] ?? FileManager.default.currentDirectoryPath
let appIconDir = URL(fileURLWithPath: srcRoot)
    .appendingPathComponent("RelationshipCheckin/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let outputURL = appIconDir.appendingPathComponent("AppIcon-1024.png", isDirectory: false)

// Ensure directory exists
try? FileManager.default.createDirectory(at: appIconDir, withIntermediateDirectories: true)

// Draw
let ctx = createContext(width: canvasSize, height: canvasSize)
drawBackground(in: ctx)

let insetRect = CGRect(x: CGFloat(margin), y: CGFloat(margin), width: CGFloat(canvasSize) - 2*CGFloat(margin), height: CGFloat(canvasSize) - 2*CGFloat(margin))
let heart = heartPath(in: insetRect)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.addPath(heart)
ctx.fillPath()

guard let cgImage = ctx.makeImage() else { fatalError("Failed to produce CGImage") }
do {
    try writePNG(from: cgImage, to: outputURL)
    fputs("Generated app icon at \(outputURL.path)\n", stderr)
} catch {
    fputs("Error writing PNG: \(error)\n", stderr)
    exit(1)
}


