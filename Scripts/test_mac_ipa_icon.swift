import Foundation
import AppKit
import ImageIO

@main
struct IPAIconEditorTest
{
    static func main() throws
    {
        let repository = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let originalIcon = repository.appendingPathComponent("AltServer/Assets.xcassets/AppIcon.appiconset/Icon@1024.png")
        let nonsquareIcon = repository.appendingPathComponent("docs/assets/brand/altforge-wordmark.png")
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let appURL = root.appendingPathComponent("Fixture.app", isDirectory: true)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        let originalCopy = appURL.appendingPathComponent("OriginalIcon.png")
        try FileManager.default.copyItem(at: originalIcon, to: originalCopy)
        let originalData = try Data(contentsOf: originalCopy)

        let alternate = ["Alternate": ["CFBundleIconFiles": ["AltIcon"]]]
        let originalIcons: [String: Any] = [
            "CFBundlePrimaryIcon": ["CFBundleIconFiles": ["OriginalIcon"], "CFBundleIconName": "OldAsset"],
            "CFBundleAlternateIcons": alternate
        ]
        let info: [String: Any] = [
            "CFBundleIcons": originalIcons,
            "CFBundleIcons~ipad": originalIcons
        ]
        let infoURL = appURL.appendingPathComponent("Info.plist")
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: infoURL)
        guard IPAIconEditor.preview(in: appURL) != nil else { fatalError("Original icon preview failed") }

        _ = try IPAIconEditor.applyCustomIcon(at: originalIcon, to: appURL, within: root)
        let updated = try PropertyListSerialization.propertyList(from: Data(contentsOf: infoURL), format: nil) as! [String: Any]
        let phoneIcons = updated["CFBundleIcons"] as! [String: Any]
        let primary = phoneIcons["CFBundlePrimaryIcon"] as! [String: Any]
        let iconName = (primary["CFBundleIconFiles"] as! [String]).first!
        guard primary["CFBundleIconName"] == nil,
              phoneIcons["CFBundleAlternateIcons"] as? [String: [String: [String]]] == alternate,
              (updated["CFBundleIcons~ipad"] as? [String: Any])?["CFBundlePrimaryIcon"] != nil,
              try Data(contentsOf: originalCopy) == originalData,
              IPAIconEditor.preview(in: appURL) != nil else { fatalError("Icon metadata or source changed unexpectedly") }

        let writtenURL = appURL.appendingPathComponent(iconName + ".png")
        guard let source = CGImageSourceCreateWithURL(writtenURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              properties[kCGImagePropertyPixelWidth] as? Int == 1024,
              properties[kCGImagePropertyPixelHeight] as? Int == 1024 else { fatalError("Custom icon is not 1024px PNG") }
        for suffix in ["@2x.png", "@3x.png", "@2x~ipad.png"]
        {
            guard FileManager.default.fileExists(atPath: appURL.appendingPathComponent(iconName + suffix).path) else {
                fatalError("Missing device icon variant: \(suffix)")
            }
        }

        let crop = IPAIconCropView(image: try IPAIconEditor.cropSource(at: nonsquareIcon))
        do
        {
            _ = try IPAIconEditor.applyCustomIcon(at: nonsquareIcon, to: appURL, within: root)
            fatalError("Uncropped image was installed")
        }
        catch IPAIconEditor.IconError.uncroppedImage {}
        let initialCrop = try crop.croppedPNGData()
        let zoom = NSSlider(value: 2, minValue: 1, maxValue: 4, target: crop,
                            action: #selector(IPAIconCropView.changeZoom(_:)))
        crop.changeZoom(zoom)
        guard try crop.croppedPNGData() != initialCrop else { fatalError("Zoom did not change the crop") }
        let croppedURL = root.appendingPathComponent("Cropped.png")
        try initialCrop.write(to: croppedURL)
        _ = try IPAIconEditor.applyCustomIcon(at: croppedURL, to: appURL, within: root)

        do
        {
            _ = try IPAIconEditor.applyCustomIcon(at: originalIcon, to: repository, within: root)
            fatalError("Icon editor accepted a path outside its temporary root")
        }
        catch IPAIconEditor.IconError.invalidLocation {}

        let linkedApp = root.appendingPathComponent("Linked.app", isDirectory: true)
        try FileManager.default.createDirectory(at: linkedApp, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: linkedApp.appendingPathComponent("Info.plist"), withDestinationURL: infoURL)
        guard IPAIconEditor.preview(in: linkedApp) == nil else { fatalError("Preview followed an external Info.plist") }
        do
        {
            _ = try IPAIconEditor.applyCustomIcon(at: originalIcon, to: linkedApp, within: root)
            fatalError("Icon editor followed an external Info.plist")
        }
        catch IPAIconEditor.IconError.invalidLocation {}

        if CommandLine.arguments.count > 2
        {
            let importedApp = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
            guard IPAIconEditor.preview(in: importedApp) != nil else { fatalError("Imported IPA icon preview failed") }
        }

        print("macOS IPA icon editor fixture passed")
    }
}
