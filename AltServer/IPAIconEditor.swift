import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

enum IPAIconEditor
{
    enum IconError: LocalizedError
    {
        case invalidImage
        case uncroppedImage
        case invalidLocation
        case unreadableMetadata

        var errorDescription: String?
        {
            switch self
            {
            case .invalidImage:
                return NSLocalizedString("Choose a PNG or JPEG image between 180 and 4096 pixels on each side.", comment: "Invalid custom IPA icon")
            case .uncroppedImage:
                return NSLocalizedString("Crop the image to a square before installing.", comment: "Custom IPA icon must be cropped")
            case .invalidLocation:
                return NSLocalizedString("The app icon can only be changed in a temporary installation copy.", comment: "Unsafe IPA icon destination")
            case .unreadableMetadata:
                return NSLocalizedString("The IPA's icon information could not be updated.", comment: "Invalid IPA icon metadata")
            }
        }
    }

    #if os(macOS)
    static func preview(in appURL: URL) -> NSImage?
    {
        let root = appURL.resolvingSymlinksInPath().standardizedFileURL
        let infoURL = appURL.appendingPathComponent("Info.plist").resolvingSymlinksInPath().standardizedFileURL
        guard infoURL.deletingLastPathComponent() == root else { return nil }
        guard let data = try? Data(contentsOf: infoURL),
              let info = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return nil }

        var names = [String]()
        for key in ["CFBundleIcons", "CFBundleIcons~ipad"]
        {
            guard let icons = info[key] as? [String: Any],
                  let primary = icons["CFBundlePrimaryIcon"] as? [String: Any] else { continue }
            names.append(contentsOf: primary["CFBundleIconFiles"] as? [String] ?? [])
            if let assetName = primary["CFBundleIconName"] as? String { names.append(assetName) }
        }
        names.append(contentsOf: info["CFBundleIconFiles"] as? [String] ?? [])
        if let name = info["CFBundleIconFile"] as? String { names.append(name) }

        for name in names.reversed()
        {
            guard !name.isEmpty, name == URL(fileURLWithPath: name).lastPathComponent else { continue }
            let stem = (name as NSString).deletingPathExtension
            for filename in [name, stem + "@3x.png", stem + "@2x.png", stem + "@2x~ipad.png", stem + ".png"]
            {
                let url = appURL.appendingPathComponent(filename).resolvingSymlinksInPath().standardizedFileURL
                guard url.deletingLastPathComponent() == root else { continue }
                if let image = try? self.image(at: url, maximumPixels: 256, validateDimensions: false) { return image }
            }
        }
        return nil
    }

    static func image(at url: URL, maximumPixels: Int = 256, validateDimensions: Bool = true) throws -> NSImage
    {
        let image = try self.thumbnail(at: url, maximumPixels: maximumPixels, validateDimensions: validateDimensions)
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
    #endif

    static func cropSource(at url: URL) throws -> CGImage
    {
        try self.thumbnail(at: url, maximumPixels: 4096, validateDimensions: true)
    }

    static func pngData(for image: CGImage) throws -> Data
    {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else {
            throw IconError.invalidImage
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw IconError.invalidImage }
        return output as Data
    }

    private static func resizedPNGData(for image: CGImage, size: Int) throws -> Data
    {
        guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw IconError.invalidImage }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        guard let scaled = context.makeImage() else { throw IconError.invalidImage }
        return try self.pngData(for: scaled)
    }

    static func applyCustomIcon(at imageURL: URL, to appURL: URL, within temporaryDirectory: URL) throws -> CGImage
    {
        let root = appURL.resolvingSymlinksInPath().standardizedFileURL
        let temporaryRoot = temporaryDirectory.resolvingSymlinksInPath().standardizedFileURL
        guard root.path.hasPrefix(temporaryRoot.path + "/") else { throw IconError.invalidLocation }

        let source = try self.thumbnail(at: imageURL, maximumPixels: 1024, validateDimensions: true)
        guard source.width == source.height else { throw IconError.uncroppedImage }
        guard let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw IconError.invalidImage }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        guard let rendered = context.makeImage() else { throw IconError.invalidImage }

        let output = try self.pngData(for: rendered)

        let infoURL = appURL.appendingPathComponent("Info.plist").resolvingSymlinksInPath().standardizedFileURL
        guard infoURL.deletingLastPathComponent() == root else { throw IconError.invalidLocation }
        guard let data = try? Data(contentsOf: infoURL),
              var info = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw IconError.unreadableMetadata
        }
        let iconName = "AltForgeIcon-" + UUID().uuidString
        let iconVariants = [(".png", output),
                            ("@2x.png", try self.resizedPNGData(for: rendered, size: 120)),
                            ("@3x.png", try self.resizedPNGData(for: rendered, size: 180)),
                            ("@2x~ipad.png", try self.resizedPNGData(for: rendered, size: 152))]
        for key in ["CFBundleIcons", "CFBundleIcons~ipad"]
        {
            var icons = info[key] as? [String: Any] ?? [:]
            var primary = icons["CFBundlePrimaryIcon"] as? [String: Any] ?? [:]
            primary.removeValue(forKey: "CFBundleIconName")
            primary["CFBundleIconFiles"] = [iconName]
            icons["CFBundlePrimaryIcon"] = primary
            info[key] = icons
        }
        info["CFBundleIconFiles"] = [iconName]
        info["CFBundleIconFile"] = iconName
        guard let updatedInfo = try? PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0) else {
            throw IconError.unreadableMetadata
        }

        do
        {
            for (suffix, data) in iconVariants
            {
                try data.write(to: appURL.appendingPathComponent(iconName + suffix), options: .atomic)
            }
            try updatedInfo.write(to: infoURL, options: .atomic)
        }
        catch
        {
            for (suffix, _) in iconVariants
            {
                try? FileManager.default.removeItem(at: appURL.appendingPathComponent(iconName + suffix))
            }
            throw IconError.unreadableMetadata
        }
        return rendered
    }

    private static func thumbnail(at url: URL, maximumPixels: Int, validateDimensions: Bool) throws -> CGImage
    {
        let maximumFileBytes = 20 * 1024 * 1024
        guard url.isFileURL,
              let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
              values.isRegularFile == true,
              let fileSize = values.fileSize, fileSize <= maximumFileBytes,
              let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let type = CGImageSourceGetType(source) as String?,
              type == UTType.png.identifier || type == UTType.jpeg.identifier else { throw IconError.invalidImage }

        if validateDimensions
        {
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight] as? Int,
                  (180...4096).contains(width), (180...4096).contains(height) else { throw IconError.invalidImage }
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixels,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCache: false
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw IconError.invalidImage
        }
        return image
    }
}

#if os(macOS)
final class IPAIconCropView: NSView
{
    private let image: CGImage
    private var zoom: CGFloat = 1
    private var offset = CGPoint.zero
    private var lastDragPoint: CGPoint?

    init(image: CGImage)
    {
        self.image = image
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 320))
    }

    required init?(coder: NSCoder) { return nil }
    override var intrinsicContentSize: NSSize { NSSize(width: 320, height: 320) }

    @objc func changeZoom(_ sender: NSSlider)
    {
        self.zoom = CGFloat(sender.doubleValue)
        self.clampOffset()
        self.needsDisplay = true
    }

    private var imageRect: CGRect
    {
        let side = min(self.bounds.width, self.bounds.height)
        let scale = max(side / CGFloat(self.image.width), side / CGFloat(self.image.height)) * self.zoom
        let width = CGFloat(self.image.width) * scale
        let height = CGFloat(self.image.height) * scale
        return CGRect(x: (self.bounds.width - width) / 2 + self.offset.x,
                      y: (self.bounds.height - height) / 2 + self.offset.y,
                      width: width, height: height)
    }

    private func clampOffset()
    {
        let rect = self.imageRect
        let limitX = max(0, (rect.width - self.bounds.width) / 2)
        let limitY = max(0, (rect.height - self.bounds.height) / 2)
        self.offset.x = min(max(self.offset.x, -limitX), limitX)
        self.offset.y = min(max(self.offset.y, -limitY), limitY)
    }

    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.clip(to: self.bounds)
        context.interpolationQuality = .high
        context.draw(self.image, in: self.imageRect)
        context.restoreGState()
        NSColor.separatorColor.setStroke()
        NSBezierPath(rect: self.bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
    }

    override func mouseDown(with event: NSEvent)
    {
        self.lastDragPoint = self.convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent)
    {
        let point = self.convert(event.locationInWindow, from: nil)
        if let previous = self.lastDragPoint
        {
            self.offset.x += point.x - previous.x
            self.offset.y += point.y - previous.y
            self.clampOffset()
            self.needsDisplay = true
        }
        self.lastDragPoint = point
    }

    override func mouseUp(with event: NSEvent) { self.lastDragPoint = nil }

    func croppedPNGData() throws -> Data
    {
        let outputSize = 1024
        guard let context = CGContext(data: nil, width: outputSize, height: outputSize, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw IPAIconEditor.IconError.invalidImage
        }
        let scale = CGFloat(outputSize) / self.bounds.width
        let rect = self.imageRect
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
        context.interpolationQuality = .high
        context.draw(self.image, in: CGRect(x: rect.minX * scale, y: rect.minY * scale,
                                            width: rect.width * scale, height: rect.height * scale))
        guard let rendered = context.makeImage() else { throw IPAIconEditor.IconError.invalidImage }
        return try IPAIconEditor.pngData(for: rendered)
    }
}
#endif
