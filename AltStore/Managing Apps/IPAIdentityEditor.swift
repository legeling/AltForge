import Foundation

import AltSign
import AltStoreCore

enum IPAIdentityEditor
{
    struct Changes
    {
        let name: String
        let bundleIdentifier: String
    }

    enum EditError: LocalizedError
    {
        case invalidName
        case invalidBundleIdentifier
        case reservedBundleIdentifier
        case missingCachedApp
        case cacheNotUpdated
        case unreadableMetadata

        var errorDescription: String?
        {
            switch self
            {
            case .invalidName:
                return NSLocalizedString("Enter an app name without line breaks.", comment: "IPA identity editor invalid app name")
            case .invalidBundleIdentifier:
                return NSLocalizedString("Enter a bundle ID like com.example.app using letters, numbers, periods, or hyphens.", comment: "IPA identity editor invalid bundle ID")
            case .reservedBundleIdentifier:
                return NSLocalizedString("This bundle ID belongs to AltForge. Choose another one.", comment: "IPA identity editor reserved bundle ID")
            case .missingCachedApp:
                return NSLocalizedString("The saved app file is unavailable. Import the IPA again to change its name.", comment: "Installed app rename missing cached bundle")
            case .cacheNotUpdated:
                return NSLocalizedString("The app was renamed, but its saved file could not be updated. Import the IPA again before refreshing it.", comment: "Installed app rename partial success")
            case .unreadableMetadata:
                return NSLocalizedString("The IPA's app information could not be edited.", comment: "IPA identity editor unreadable metadata")
            }
        }
    }

    static func validate(name: String, bundleIdentifier: String, originalBundleIdentifier: String) throws -> Changes
    {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let bundleIdentifier = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty, name.unicodeScalars.allSatisfy({ !CharacterSet.newlines.contains($0) && !CharacterSet.controlCharacters.contains($0) }) else {
            throw EditError.invalidName
        }

        let components = bundleIdentifier.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count >= 2, components.allSatisfy({ component in
            guard let first = component.unicodeScalars.first, let last = component.unicodeScalars.last,
                  isASCIILetterOrNumber(first), isASCIILetterOrNumber(last) else { return false }
            return component.unicodeScalars.allSatisfy { isASCIILetterOrNumber($0) || $0.value == 45 }
        }), bundleIdentifier.caseInsensitiveCompare(originalBundleIdentifier) != .orderedSame || bundleIdentifier == originalBundleIdentifier else {
            throw EditError.invalidBundleIdentifier
        }

        guard bundleIdentifier.caseInsensitiveCompare(StoreApp.altstoreAppID) != .orderedSame else {
            throw EditError.reservedBundleIdentifier
        }

        return Changes(name: name, bundleIdentifier: bundleIdentifier)
    }

    static func apply(_ changes: Changes, to application: ALTApplication, within temporaryDirectory: URL) throws -> ALTApplication
    {
        let changes = try validate(name: changes.name, bundleIdentifier: changes.bundleIdentifier,
                                   originalBundleIdentifier: application.bundleIdentifier)
        guard changes.name != application.name || changes.bundleIdentifier != application.bundleIdentifier else { return application }

        let rootURL = application.fileURL.resolvingSymlinksInPath().standardizedFileURL
        let temporaryRootURL = temporaryDirectory.resolvingSymlinksInPath().standardizedFileURL
        guard rootURL.path.hasPrefix(temporaryRootURL.path + "/") else { throw EditError.unreadableMetadata }
        let originalBundleIdentifier = application.bundleIdentifier
        let isChangingBundleIdentifier = changes.bundleIdentifier != originalBundleIdentifier
        var writes: [(url: URL, data: Data)] = []

        func stage(_ url: URL, update: (inout [String: Any]) throws -> Void) throws
        {
            let resolvedURL = url.resolvingSymlinksInPath().standardizedFileURL
            guard resolvedURL.path.hasPrefix(rootURL.path + "/"),
                  let data = try? Data(contentsOf: resolvedURL) else { throw EditError.unreadableMetadata }
            var format = PropertyListSerialization.PropertyListFormat.xml
            guard var values = (try? PropertyListSerialization.propertyList(from: data, format: &format)) as? [String: Any] else {
                throw EditError.unreadableMetadata
            }
            try update(&values)
            let outputFormat: PropertyListSerialization.PropertyListFormat = format == .openStep ? .xml : format
            guard let updatedData = try? PropertyListSerialization.data(fromPropertyList: values, format: outputFormat, options: 0) else {
                throw EditError.unreadableMetadata
            }
            writes.append((resolvedURL, updatedData))
        }

        try stage(application.bundle.infoPlistURL) { values in
            values[kCFBundleNameKey as String] = changes.name
            values["CFBundleDisplayName"] = changes.name
            values[kCFBundleIdentifierKey as String] = changes.bundleIdentifier
        }

        if changes.name != application.name
        {
            guard let children = try? FileManager.default.contentsOfDirectory(at: application.fileURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
                throw EditError.unreadableMetadata
            }
            for directory in children where directory.pathExtension == "lproj"
            {
                let stringsURL = directory.appendingPathComponent("InfoPlist.strings")
                guard FileManager.default.fileExists(atPath: stringsURL.path) else { continue }
                try stage(stringsURL) { values in
                    values[kCFBundleNameKey as String] = changes.name
                    values["CFBundleDisplayName"] = changes.name
                }
            }
        }

        if isChangingBundleIdentifier
        {
            var mappedIdentifiers = Set<String>()
            let pluginsURL = application.bundle.builtInPlugInsURL ?? application.fileURL.appendingPathComponent("PlugIns", isDirectory: true)
            if FileManager.default.fileExists(atPath: pluginsURL.path)
            {
                guard let extensions = try? FileManager.default.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil)
                    .filter({ $0.pathExtension.lowercased() == "appex" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) else {
                    throw EditError.unreadableMetadata
                }
                for extensionURL in extensions
                {
                    try stage(extensionURL.appendingPathComponent("Info.plist")) { values in
                        guard let oldIdentifier = values[kCFBundleIdentifierKey as String] as? String else {
                            throw EditError.unreadableMetadata
                        }
                        let suffix = oldIdentifier.hasPrefix(originalBundleIdentifier + ".")
                            ? String(oldIdentifier.dropFirst(originalBundleIdentifier.count + 1))
                            : oldIdentifier
                        let updatedIdentifier = changes.bundleIdentifier + "." + suffix
                        _ = try validate(name: changes.name, bundleIdentifier: updatedIdentifier,
                                         originalBundleIdentifier: oldIdentifier)
                        guard mappedIdentifiers.insert(updatedIdentifier.lowercased()).inserted else {
                            throw EditError.invalidBundleIdentifier
                        }
                        values[kCFBundleIdentifierKey as String] = updatedIdentifier
                    }
                }
            }
        }

        for write in writes
        {
            do { try write.data.write(to: write.url, options: .atomic) }
            catch { throw EditError.unreadableMetadata }
        }
        guard let updated = ALTApplication(fileURL: application.fileURL),
              updated.name == changes.name, updated.bundleIdentifier == changes.bundleIdentifier else {
            throw EditError.unreadableMetadata
        }
        return updated
    }

    private static func isASCIILetterOrNumber(_ scalar: Unicode.Scalar) -> Bool
    {
        return (65...90).contains(scalar.value) || (97...122).contains(scalar.value) || (48...57).contains(scalar.value)
    }
}
