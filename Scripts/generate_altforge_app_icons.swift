#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

private struct Variant
{
    enum Decoration
    {
        case none
        case blueprint
        case diagonalBand
    }

    let assetName: String
    let documentationName: String
    let backgroundColors: [CGColor]
    let markColors: [CGColor]
    let decoration: Decoration
}

private func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor
{
    let red = CGFloat((hex >> 16) & 0xff) / 255
    let green = CGFloat((hex >> 8) & 0xff) / 255
    let blue = CGFloat(hex & 0xff) / 255
    return CGColor(red: red, green: green, blue: blue, alpha: alpha)
}

private func drawGradient(_ colors: [CGColor], in rect: CGRect, context: CGContext, start: CGPoint, end: CGPoint)
{
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil) else {
        fatalError("Unable to create icon gradient.")
    }
    context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

private func drawDecoration(_ decoration: Variant.Decoration, in rect: CGRect, context: CGContext)
{
    switch decoration
    {
    case .none:
        break

    case .blueprint:
        context.saveGState()
        context.setStrokeColor(color(0xDDEBFF, alpha: 0.12))
        context.setLineWidth(2)
        let spacing: CGFloat = 64
        stride(from: spacing, to: rect.width, by: spacing).forEach { coordinate in
            context.move(to: CGPoint(x: coordinate, y: 0))
            context.addLine(to: CGPoint(x: coordinate, y: rect.height))
            context.move(to: CGPoint(x: 0, y: coordinate))
            context.addLine(to: CGPoint(x: rect.width, y: coordinate))
        }
        context.strokePath()

        context.setStrokeColor(color(0x7FC8FF, alpha: 0.28))
        context.setLineWidth(3)
        context.stroke(CGRect(x: 96, y: 96, width: rect.width - 192, height: rect.height - 192))
        context.restoreGState()

    case .diagonalBand:
        context.saveGState()
        context.setFillColor(color(0xFF3E56, alpha: 0.92))
        context.move(to: CGPoint(x: rect.width * 0.78, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.width * 0.22, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        context.closePath()
        context.fillPath()
        context.restoreGState()
    }
}

private func render(_ variant: Variant, markMask: CGImage, size: Int) throws -> Data
{
    guard let context = CGContext(data: nil,
                                  width: size,
                                  height: size,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else {
        fatalError("Unable to create icon bitmap.")
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    context.interpolationQuality = .high

    drawGradient(variant.backgroundColors,
                 in: rect,
                 context: context,
                 start: CGPoint(x: rect.minX, y: rect.maxY),
                 end: CGPoint(x: rect.maxX, y: rect.minY))
    drawDecoration(variant.decoration, in: rect, context: context)

    context.saveGState()
    context.clip(to: rect, mask: markMask)
    drawGradient(variant.markColors,
                 in: rect,
                 context: context,
                 start: CGPoint(x: rect.minX, y: rect.maxY),
                 end: CGPoint(x: rect.maxX, y: rect.minY))
    context.restoreGState()

    guard let renderedImage = context.makeImage() else {
        fatalError("Unable to finish icon bitmap.")
    }
    let bitmap = NSBitmapImageRep(cgImage: renderedImage)
    guard let data = bitmap.representation(using: .png, properties: [.compressionFactor: 0.92]) else {
        fatalError("Unable to encode icon PNG.")
    }
    return data
}

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
let templateURL = rootURL.appendingPathComponent("docs/assets/brand/altforge-template-icon.png")

guard let template = NSImage(contentsOf: templateURL) else {
    fatalError("Missing brand template at \(templateURL.path).")
}

var proposedRect = CGRect(origin: .zero, size: template.size)
guard let markMask = template.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
    fatalError("Unable to decode the AltForge brand template.")
}

private let variants = [
    Variant(assetName: "Frost",
            documentationName: "frost",
            backgroundColors: [color(0x0A2436), color(0x126B87)],
            markColors: [color(0xF8FDFF), color(0x7DE4F2)],
            decoration: .none),
    Variant(assetName: "Paper",
            documentationName: "paper",
            backgroundColors: [color(0xFFFFFF), color(0xE8EBEF)],
            markColors: [color(0x24272D), color(0x07080A)],
            decoration: .diagonalBand),
    Variant(assetName: "Neon",
            documentationName: "neon",
            backgroundColors: [color(0x090A12), color(0x171124)],
            markColors: [color(0x48F2E3), color(0xFF4A78)],
            decoration: .none),
    Variant(assetName: "Blueprint",
            documentationName: "blueprint",
            backgroundColors: [color(0x061A38), color(0x124A80)],
            markColors: [color(0xFFFFFF), color(0xB9DFFF)],
            decoration: .blueprint),
]

for variant in variants
{
    let data = try render(variant, markMask: markMask, size: 1024)
    let fileName = "AltForge\(variant.assetName).png"
    let assetDirectory = rootURL.appendingPathComponent("AltStore/Resources/AppIcon_\(variant.assetName).icon/Assets", isDirectory: true)
    try fileManager.createDirectory(at: assetDirectory, withIntermediateDirectories: true)
    try data.write(to: assetDirectory.appendingPathComponent(fileName), options: .atomic)

    let documentationURL = rootURL.appendingPathComponent("docs/assets/brand/altforge-app-icon-\(variant.documentationName).png")
    try data.write(to: documentationURL, options: .atomic)
    print("Generated \(fileName)")
}
