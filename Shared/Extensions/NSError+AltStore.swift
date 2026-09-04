//
//  NSError+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 3/11/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias ALTFont = UIFont
#elseif canImport(AppKit)
import AppKit
public typealias ALTFont = NSFont
#endif

import AltSign

public struct ALTErrorPresentation
{
    public let title: String
    public let message: String
    public let recoverySuggestion: String?

    public var combinedMessage: String {
        return [self.message, self.recoverySuggestion].compactMap { $0 }.joined(separator: "\n\n")
    }
}

public extension NSError
{
    var userFacingPresentation: ALTErrorPresentation {
        let primaryError = self.presentationPrimaryError
        let localizedError = primaryError.relocalizedProviderError

        let title = self.localizedTitle ?? primaryError.localizedTitle ?? self.localizedFailure ?? primaryError.localizedFailure ?? localizedError.presentationTitle
        let message = localizedError.presentationMessage
        let recoverySuggestion = localizedError.localizedRecoverySuggestion ?? primaryError.localizedRecoverySuggestion ?? localizedError.fallbackRecoverySuggestion

        return ALTErrorPresentation(title: title, message: message, recoverySuggestion: recoverySuggestion)
    }

    @objc(alt_localizedFailure)
    var localizedFailure: String? {
        let localizedFailure = (self.userInfo[NSLocalizedFailureErrorKey] as? String) ?? (NSError.userInfoValueProvider(forDomain: self.domain)?(self, NSLocalizedFailureErrorKey) as? String)
        return localizedFailure
    }

    @objc(alt_localizedDebugDescription)
    var localizedDebugDescription: String? {
        let debugDescription = (self.userInfo[NSDebugDescriptionErrorKey] as? String) ?? (NSError.userInfoValueProvider(forDomain: self.domain)?(self, NSDebugDescriptionErrorKey) as? String)
        return debugDescription
    }

    @objc(alt_localizedTitle)
    var localizedTitle: String? {
        let localizedTitle = self.userInfo[ALTLocalizedTitleErrorKey] as? String
        return localizedTitle
    }

    @objc(alt_errorWithLocalizedFailure:)
    func withLocalizedFailure(_ failure: String) -> NSError
    {
        switch self
        {
        case var error as any ALTLocalizedError:
            error.errorFailure = failure
            return error as NSError

        default:
            var userInfo = self.userInfo
            userInfo[NSLocalizedFailureErrorKey] = failure

            let error = ALTWrappedError(error: self, userInfo: userInfo)
            return error
        }
    }

    @objc(alt_errorWithLocalizedTitle:)
    func withLocalizedTitle(_ title: String) -> NSError
    {
        switch self
        {
        case var error as any ALTLocalizedError:
            error.errorTitle = title
            return error as NSError

        default:
            var userInfo = self.userInfo
            userInfo[ALTLocalizedTitleErrorKey] = title

            let error = ALTWrappedError(error: self, userInfo: userInfo)
            return error
        }
    }

    func sanitizedForSerialization() -> NSError
    {
        var userInfo = self.userInfo
        userInfo[NSLocalizedDescriptionKey] = self.localizedDescription
        userInfo[NSLocalizedFailureErrorKey] = self.localizedFailure
        userInfo[NSLocalizedFailureReasonErrorKey] = self.localizedFailureReason
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = self.localizedRecoverySuggestion
        userInfo[NSDebugDescriptionErrorKey] = self.localizedDebugDescription

        // Remove userInfo values that don't conform to NSSecureEncoding.
        userInfo = userInfo.filter { (key, value) in
            guard let secureCodable = value as? NSSecureCoding else { return false }

            switch secureCodable
            {
            case let array as NSArray:
                let isSecureCodable = array.allSatisfy({ $0 is NSSecureCoding })
                return isSecureCodable

            case let dictionary as NSDictionary:
                let isSecureCodable = dictionary.allValues.allSatisfy({ $0 is NSSecureCoding })
                return isSecureCodable

            default: return true
            }
        }

        // Sanitize underlying errors.
        if let underlyingError = userInfo[NSUnderlyingErrorKey] as? Error
        {
            let sanitizedError = (underlyingError as NSError).sanitizedForSerialization()
            userInfo[NSUnderlyingErrorKey] = sanitizedError
        }

        if #available(iOS 14.5, macOS 11.3, *), let underlyingErrors = userInfo[NSMultipleUnderlyingErrorsKey] as? [Error]
        {
            let sanitizedErrors = underlyingErrors.map { ($0 as NSError).sanitizedForSerialization() }
            userInfo[NSMultipleUnderlyingErrorsKey] = sanitizedErrors
        }

        let error = NSError(domain: self.domain, code: self.code, userInfo: userInfo)
        return error
    }

    func formattedDetailedDescription(with font: ALTFont) -> NSAttributedString
    {
        #if canImport(UIKit)
        let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor
        let boldFont = ALTFont(descriptor: boldFontDescriptor, size: font.pointSize)
        #else
        let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.bold)
        let boldFont = ALTFont(descriptor: boldFontDescriptor, size: font.pointSize) ?? font
        #endif

        var preferredKeyOrder = [
            NSDebugDescriptionErrorKey,
            NSLocalizedDescriptionKey,
            NSLocalizedFailureErrorKey,
            NSLocalizedFailureReasonErrorKey,
            NSLocalizedRecoverySuggestionErrorKey,
            ALTLocalizedTitleErrorKey,
            ALTDiagnosticIDErrorKey,
            ALTDiagnosticStageErrorKey,
            ALTDiagnosticTraceErrorKey,
            ALTSourceFileErrorKey,
            ALTSourceLineErrorKey,
            NSUnderlyingErrorKey
        ]

        if #available(iOS 14.5, macOS 11.3, *)
        {
            preferredKeyOrder.append(NSMultipleUnderlyingErrorsKey)
        }

        var userInfo = self.userInfo
        userInfo[NSDebugDescriptionErrorKey] = self.localizedDebugDescription
        userInfo[NSLocalizedDescriptionKey] = self.localizedDescription
        userInfo[NSLocalizedFailureErrorKey] = self.localizedFailure
        userInfo[NSLocalizedFailureReasonErrorKey] = self.localizedFailureReason
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = self.localizedRecoverySuggestion

        let sortedUserInfo = userInfo.sorted { (a, b) in
            let indexA = preferredKeyOrder.firstIndex(of: a.key)
            let indexB = preferredKeyOrder.firstIndex(of: b.key)

            switch (indexA, indexB)
            {
            case (let indexA?, let indexB?): return indexA < indexB
            case (_?, nil): return true // indexA exists, indexB is nil, so A should come first.
            case (nil, _?): return false  // indexA is nil, indexB exists, so B should come first.
            case (nil, nil): return a.key < b.key // both indexes are nil, so sort alphabetically.
            }
        }

        let detailedDescription = NSMutableAttributedString()

        for (key, value) in sortedUserInfo
        {
            let keyName: String
            switch key
            {
            case NSDebugDescriptionErrorKey: keyName = NSLocalizedString("Debug Description", comment: "")
            case NSLocalizedDescriptionKey: keyName = NSLocalizedString("Error Description", comment: "")
            case NSLocalizedFailureErrorKey: keyName = NSLocalizedString("Failure", comment: "")
            case NSLocalizedFailureReasonErrorKey: keyName = NSLocalizedString("Failure Reason", comment: "")
            case NSLocalizedRecoverySuggestionErrorKey: keyName = NSLocalizedString("Recovery Suggestion", comment: "")
            case ALTLocalizedTitleErrorKey: keyName = NSLocalizedString("Title", comment: "")
            case ALTDiagnosticIDErrorKey: keyName = NSLocalizedString("Diagnostic ID", comment: "")
            case ALTDiagnosticStageErrorKey: keyName = NSLocalizedString("Failure Stage", comment: "")
            case ALTDiagnosticTraceErrorKey: keyName = NSLocalizedString("Operation Trace", comment: "")
            case ALTSourceFileErrorKey: keyName = NSLocalizedString("Source File", comment: "")
            case ALTSourceLineErrorKey: keyName = NSLocalizedString("Source Line", comment: "")
            case NSUnderlyingErrorKey: keyName = NSLocalizedString("Underlying Error", comment: "")
            default:
                if #available(iOS 14.5, macOS 11.3, *), key == NSMultipleUnderlyingErrorsKey
                {
                    keyName = NSLocalizedString("Underlying Errors", comment: "")
                }
                else
                {
                    keyName = key
                }
            }

            let attributedKey = NSAttributedString(string: keyName, attributes: [.font: boldFont])
            let attributedValue = NSAttributedString(string: String(describing: value), attributes: [.font: font])

            let attributedString = NSMutableAttributedString(attributedString: attributedKey)
            attributedString.mutableString.append("\n")
            attributedString.append(attributedValue)

            if !detailedDescription.string.isEmpty
            {
                detailedDescription.mutableString.append("\n\n")
            }

            detailedDescription.append(attributedString)
        }

        // Support dark mode
        #if canImport(UIKit)
        detailedDescription.addAttribute(.foregroundColor, value: UIColor.label, range: NSMakeRange(0, detailedDescription.length))
        #else
        detailedDescription.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSMakeRange(0, detailedDescription.length))
        #endif

        return detailedDescription
    }
}

public extension Error
{
    var userFacingPresentation: ALTErrorPresentation {
        return (self as NSError).userFacingPresentation
    }
}

private extension NSError
{
    var presentationPrimaryError: NSError {
        guard self.domain == AltServerErrorDomain,
              self.code == ALTServerError.Code.underlyingError.rawValue,
              let underlyingError = self.userInfo[NSUnderlyingErrorKey] as? Error
        else { return self }

        return underlyingError as NSError
    }

    var relocalizedProviderError: NSError {
        let domainsWithLocalProviders: Set<String> = [
            AltSignErrorDomain,
            ALTAppleAPIErrorDomain,
            AltServerErrorDomain,
            AltServerConnectionErrorDomain,
        ]
        guard domainsWithLocalProviders.contains(self.domain) else { return self }

        var userInfo = self.userInfo
        [
            NSLocalizedDescriptionKey,
            NSLocalizedFailureErrorKey,
            NSLocalizedFailureReasonErrorKey,
            NSLocalizedRecoverySuggestionErrorKey,
            NSDebugDescriptionErrorKey,
        ].forEach { userInfo.removeValue(forKey: $0) }

        return NSError(domain: self.domain, code: self.code, userInfo: userInfo)
    }

    var presentationTitle: String {
        switch self.domain
        {
        case ALTAppleAPIErrorDomain:
            if (3000...3004).contains(self.code) || (3018...3021).contains(self.code)
            {
                return NSLocalizedString("Apple ID Sign-In Failed", comment: "Error presentation title")
            }
            return NSLocalizedString("Apple Developer Setup Failed", comment: "Error presentation title")

        case AltSignErrorDomain:
            if (1...3).contains(self.code)
            {
                return NSLocalizedString("App Package Could Not Be Read", comment: "Error presentation title")
            }
            return NSLocalizedString("App Signing Failed", comment: "Error presentation title")

        case AltServerErrorDomain:
            switch self.code
            {
            case 1...6: return NSLocalizedString("Device Connection Failed", comment: "Error presentation title")
            case 7...16: return NSLocalizedString("App Installation Failed", comment: "Error presentation title")
            case 100...101: return NSLocalizedString("JIT Could Not Be Enabled", comment: "Error presentation title")
            default: return NSLocalizedString("AltForge Server Error", comment: "Error presentation title")
            }

        case AltServerConnectionErrorDomain:
            return NSLocalizedString("Device Connection Failed", comment: "Error presentation title")

        case NSURLErrorDomain:
            return NSLocalizedString("Network Request Failed", comment: "Error presentation title")

        case NSCocoaErrorDomain:
            return NSLocalizedString("File or Data Could Not Be Read", comment: "Error presentation title")

        case AltServerInstallationErrorDomain:
            return NSLocalizedString("Device Installation Failed", comment: "Error presentation title")

        default:
            break
        }

        if self.domain.hasSuffix(".SourceError")
        {
            return NSLocalizedString("Source Could Not Be Used", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".VerificationError")
        {
            return NSLocalizedString("App Verification Failed", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".AuthenticationError") || self.domain.hasSuffix(".AnisetteError") || self.domain.hasSuffix(".AppleProgramError")
        {
            return NSLocalizedString("Apple ID Sign-In Failed", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".RefreshError")
        {
            return NSLocalizedString("App Refresh Failed", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".PatchAppError") || self.domain.hasSuffix(".DeveloperDiskError")
        {
            return NSLocalizedString("App Preparation Failed", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".JITError") || self.domain.hasSuffix(".MountError")
        {
            return NSLocalizedString("JIT Could Not Be Enabled", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".MastodonError") || self.domain.hasSuffix(".BlueskyError") || self.domain.hasSuffix(".PatreonAPIError")
        {
            return NSLocalizedString("Account Request Failed", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".ProcessError")
        {
            return NSLocalizedString("Required Process Failed", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".MergeError")
        {
            return NSLocalizedString("App Data Could Not Be Updated", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".PluginError")
        {
            return NSLocalizedString("Mail Plug-In Operation Failed", comment: "Error presentation title")
        }
        else if self.domain.hasSuffix(".OperationError")
        {
            switch self.code
            {
            case 1200...1202: return NSLocalizedString("AltForge Server Connection Failed", comment: "Error presentation title")
            case 1401...1402: return NSLocalizedString("Access Could Not Be Verified", comment: "Error presentation title")
            case 1500...1599: return NSLocalizedString("App Verification Failed", comment: "Error presentation title")
            default: return NSLocalizedString("Operation Failed", comment: "Error presentation title")
            }
        }

        return NSLocalizedString("Operation Failed", comment: "Error presentation title")
    }

    var presentationMessage: String {
        if self.domain == NSCocoaErrorDomain
        {
            switch self.code
            {
            case 3840, 4864:
                return NSLocalizedString("The returned data could not be read.", comment: "User-facing data parsing error")
            case NSFileNoSuchFileError:
                return NSLocalizedString("The selected file could not be found.", comment: "User-facing file error")
            case NSFileReadCorruptFileError:
                return NSLocalizedString("The selected file is damaged or is not in the expected format.", comment: "User-facing file error")
            default:
                break
            }
        }
        else if self.domain == NSURLErrorDomain
        {
            switch self.code
            {
            case NSURLErrorNotConnectedToInternet:
                return NSLocalizedString("This device is not connected to the internet.", comment: "User-facing network error")
            case NSURLErrorTimedOut:
                return NSLocalizedString("The network request timed out.", comment: "User-facing network error")
            case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                return NSLocalizedString("The server address could not be resolved.", comment: "User-facing network error")
            case NSURLErrorCannotConnectToHost:
                return NSLocalizedString("A connection to the server could not be established.", comment: "User-facing network error")
            case NSURLErrorNetworkConnectionLost:
                return NSLocalizedString("The network connection was interrupted.", comment: "User-facing network error")
            case NSURLErrorSecureConnectionFailed,
                 NSURLErrorServerCertificateHasBadDate,
                 NSURLErrorServerCertificateUntrusted,
                 NSURLErrorServerCertificateHasUnknownRoot,
                 NSURLErrorServerCertificateNotYetValid:
                return NSLocalizedString("A secure connection to the server could not be verified.", comment: "User-facing network error")
            default:
                break
            }
        }

        if let failureReason = self.localizedFailureReason?.trimmingCharacters(in: .whitespacesAndNewlines), !failureReason.isEmpty
        {
            return failureReason
        }

        let description = self.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty && description != self.localizedErrorCode
        {
            return description
        }

        return NSLocalizedString("AltForge did not receive a recognizable reason for this failure.", comment: "Unknown error fallback")
    }

    var fallbackRecoverySuggestion: String? {
        if self.domain == NSURLErrorDomain
        {
            switch self.code
            {
            case NSURLErrorSecureConnectionFailed,
                 NSURLErrorServerCertificateHasBadDate,
                 NSURLErrorServerCertificateUntrusted,
                 NSURLErrorServerCertificateHasUnknownRoot,
                 NSURLErrorServerCertificateNotYetValid:
                return NSLocalizedString("Check the device date and time. If the problem continues, try another trusted network.", comment: "Network recovery suggestion")
            default:
                return NSLocalizedString("Check the network connection and try again.", comment: "Network recovery suggestion")
            }
        }
        else if self.domain == NSCocoaErrorDomain
        {
            switch self.code
            {
            case 3840, 4864:
                return NSLocalizedString("Try again. If the problem continues, update AltForge and AltForge Server before retrying.", comment: "Data parsing recovery suggestion")
            case NSFileNoSuchFileError:
                return NSLocalizedString("Select the file again and make sure it has not been moved or deleted.", comment: "File recovery suggestion")
            case NSFileReadCorruptFileError:
                return NSLocalizedString("Download or export the app again from a trusted source, then retry with the new file.", comment: "File recovery suggestion")
            default:
                return NSLocalizedString("Check that the file is accessible, then try again.", comment: "File recovery suggestion")
            }
        }

        if self.domain.hasSuffix(".SourceError")
        {
            return NSLocalizedString("Check the source address and content. If it is maintained by someone else, contact the source maintainer.", comment: "Source recovery suggestion")
        }
        else if self.domain.hasSuffix(".VerificationError")
        {
            return NSLocalizedString("For your safety, installation was stopped. Download the app again from its trusted original source.", comment: "Verification recovery suggestion")
        }
        else if self.domain.hasSuffix(".AuthenticationError") || self.domain.hasSuffix(".AnisetteError") || self.domain.hasSuffix(".AppleProgramError")
        {
            return NSLocalizedString("Check the Apple ID account status, device date and time, then sign in again.", comment: "Authentication recovery suggestion")
        }
        else if self.domain.hasSuffix(".ProcessError")
        {
            return NSLocalizedString("Open More Details to check the process and exit code, then update the related dependency before retrying.", comment: "Process recovery suggestion")
        }
        else if self.domain.hasSuffix(".MastodonError") || self.domain.hasSuffix(".BlueskyError") || self.domain.hasSuffix(".PatreonAPIError")
        {
            return NSLocalizedString("Check the account status and network connection, then try again.", comment: "Account recovery suggestion")
        }
        else if self.domain.hasSuffix(".DeveloperDiskError") || self.domain.hasSuffix(".PatchAppError")
        {
            return NSLocalizedString("Update AltForge and AltForge Server, then try preparing the app again.", comment: "App preparation recovery suggestion")
        }
        else if self.domain.hasSuffix(".OperationError")
        {
            switch self.code
            {
            case 1003, 1200...1202:
                return NSLocalizedString("Check the connection to AltForge Server, then try again.", comment: "Operation recovery suggestion")
            case 1004:
                return NSLocalizedString("Sign in with your Apple ID, then try again.", comment: "Operation recovery suggestion")
            case 1005, 1007:
                return NSLocalizedString("Choose the app again and make sure it is a complete, unmodified IPA file.", comment: "Operation recovery suggestion")
            case 1006:
                return NSLocalizedString("Reconnect and unlock the device, then trust this computer when prompted.", comment: "Operation recovery suggestion")
            case 1010, 1014:
                return NSLocalizedString("Add a valid source before trying again.", comment: "Operation recovery suggestion")
            case 1401, 1402:
                return NSLocalizedString("Open Settings, reconnect the required account, then try again.", comment: "Operation recovery suggestion")
            default:
                break
            }
        }

        return NSLocalizedString("Try again. If the problem continues, open More Details and include the diagnostic code when reporting it.", comment: "General recovery suggestion")
    }
}

public extension NSError
{
    typealias UserInfoProvider = (Error, String) -> Any?

    @objc
    class func alt_setUserInfoValueProvider(forDomain domain: String, provider: UserInfoProvider?)
    {
        NSError.setUserInfoValueProvider(forDomain: domain) { (error, key) in
            let nsError = error as NSError

            switch key
            {
            case NSLocalizedDescriptionKey:
                if nsError.localizedFailure != nil
                {
                    // Error has localizedFailure, so return nil to construct localizedDescription from it + localizedFailureReason.
                    return nil
                }
                else if let localizedDescription = provider?(error, NSLocalizedDescriptionKey) as? String
                {
                    // Only call provider() if there is no localizedFailure.
                    return localizedDescription
                }

                // Otherwise, return failureReason for localizedDescription to avoid system prepending "Operation Failed" message.
                // Do NOT return provider(NSLocalizedFailureReason), which might be unexpectedly nil if unrecognized error code.
                return nsError.localizedFailureReason

            default:
                let value = provider?(error, key)
                return value
            }
        }
    }
}

public extension Error
{
    var underlyingError: Error? {
        let underlyingError = (self as NSError).userInfo[NSUnderlyingErrorKey] as? Error
        return underlyingError
    }

    var localizedErrorCode: String {
        let nsError = self as NSError
        let localizedErrorCode = String(format: NSLocalizedString("%@ %@", comment: ""), nsError.domain, self.displayCode as NSNumber)
        return localizedErrorCode
    }

    var displayCode: Int {
        guard let serverError = self as? ALTServerError else {
            // Not ALTServerError, so display regular code.
            return (self as NSError).code
        }

        // We want ALTServerError codes to start at 2000,
        // but we can't change them without breaking AltServer compatibility.
        // Instead, we just add 2000 when displaying code to user
        // to make it appear as if codes start at 2000 normally.
        let code = 2000 + serverError.code.rawValue
        return code
    }
}
