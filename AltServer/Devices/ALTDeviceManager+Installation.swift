//
//  ALTDeviceManager+Installation.swift
//  AltServer
//
//  Created by Riley Testut on 7/1/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Cocoa
import CryptoKit

let altstoreSourceURL = URL(string: "https://github.com/legeling/AltForge/releases/latest/download/apps.json")!
let altstoreBundleID = "com.legeling.AltForge"

private let appGroupsSemaphore = DispatchSemaphore(value: 1)
private let developerDiskManager = DeveloperDiskManager()
private let githubReleaseMirrorPrefixes = [
    "https://gh-proxy.com/",
    "https://ghproxy.net/"
]

private struct ReleaseDownloadCandidate
{
    let source: ALTInstallationDownloadSource
    let url: URL
    let usesMirror: Bool
}

private let session: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.urlCache = nil
    configuration.timeoutIntervalForRequest = 45
    configuration.timeoutIntervalForResource = 600
    
    let session = URLSession(configuration: configuration)
    return session
}()

private final class ProgressObservationHolder
{
    var observation: NSKeyValueObservation?

    deinit
    {
        self.observation?.invalidate()
    }
}

extension OperationError
{
    enum Code: Int, ALTErrorCode
    {
        typealias Error = OperationError
        
        case cancelled
        case noTeam
        case missingPrivateKey
        case missingCertificate
    }
    
    static let cancelled = OperationError(code: .cancelled)
    static let noTeam = OperationError(code: .noTeam)
    static let missingPrivateKey = OperationError(code: .missingPrivateKey)
    static let missingCertificate = OperationError(code: .missingCertificate)
}

struct OperationError: ALTLocalizedError
{
    var code: Code
    var errorTitle: String?
    var errorFailure: String?
    
    var errorFailureReason: String {
        switch self.code
        {
        case .cancelled: return NSLocalizedString("The operation was cancelled.", comment: "")
        case .noTeam: return NSLocalizedString("You are not a member of any developer teams.", comment: "")
        case .missingPrivateKey: return NSLocalizedString("The developer certificate's private key could not be found.", comment: "")
        case .missingCertificate: return NSLocalizedString("The developer certificate could not be found.", comment: "")
        }
    }
}

private extension ALTDeviceManager
{
    struct Source: Decodable
    {
        struct App: Decodable
        {
            struct Version: Decodable
            {
                var version: String
                var downloadURL: URL
                var size: Int64?
                var sha256: String?
                var downloadMirrors: [URL]?
                
                var minimumOSVersion: OperatingSystemVersion? {
                    return self.minOSVersion.map { OperatingSystemVersion(string: $0) }
                }
                private var minOSVersion: String?
            }
            
            var name: String
            var bundleIdentifier: String
            
            var versions: [Version]?
        }
        
        var name: String
        var identifier: String
        
        var apps: [App]
    }

    struct GitHubRelease: Decodable
    {
        struct Asset: Decodable
        {
            var name: String
            var size: Int64
            var digest: String?
            var downloadURL: URL

            private enum CodingKeys: String, CodingKey
            {
                case name
                case size
                case digest
                case downloadURL = "browser_download_url"
            }
        }

        var assets: [Asset]
    }

    struct ReleaseAssetIntegrity
    {
        let sha256: String
        let size: Int64
    }

    struct ReleaseDownloadDescriptor
    {
        let officialURL: URL
        let integrity: ReleaseAssetIntegrity?
        let configuredMirrorURLs: [URL]
    }
}

extension ALTDeviceManager
{
    func installApplication(at ipaFileURL: URL?, to altDevice: ALTDevice, appleID: String, password: String, authenticationCompletion: @escaping () -> Void, teamCompletion: @escaping (ALTTeam) -> Void, downloadControl: ALTInstallationDownloadControl, progressHandler: @escaping (ALTInstallationProgressUpdate) -> Void, completion: @escaping (Result<ALTApplication, Error>) -> Void)
    {
        let destinationDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        var appName = ipaFileURL?.deletingPathExtension().lastPathComponent ?? NSLocalizedString("AltForge", comment: "")
        
        func finish(_ result: Result<ALTApplication, Error>, failure: String? = nil)
        {
            DispatchQueue.main.async {
                switch result
                {
                case .success(let app): completion(.success(app))
                case .failure(var error as NSError):
                    error = error.withLocalizedTitle(String(format: NSLocalizedString("%@ could not be installed onto %@.", comment: ""), appName, altDevice.name))
                    
                    if let failure, error.localizedFailure == nil
                    {
                        error = error.withLocalizedFailure(failure)
                    }
                    
                    completion(.failure(error))
                }
            }
            
            try? FileManager.default.removeItem(at: destinationDirectoryURL)
        }
        
        AnisetteDataManager.shared.requestAnisetteData { (result) in
            do
            {
                let anisetteData = try result.get()
                
                self.authenticate(appleID: appleID, password: password, anisetteData: anisetteData) { (result) in
                    do
                    {
                        let (account, session) = try result.get()
                        if Thread.isMainThread
                        {
                            authenticationCompletion()
                        }
                        else
                        {
                            DispatchQueue.main.sync {
                                authenticationCompletion()
                            }
                        }

                        progressHandler(ALTInstallationProgressUpdate(stage: .fetchingTeam))
                        
                        self.fetchTeam(for: account, session: session) { (result) in
                            do
                            {
                                let team = try result.get()

                                if Thread.isMainThread
                                {
                                    teamCompletion(team)
                                }
                                else
                                {
                                    DispatchQueue.main.sync {
                                        teamCompletion(team)
                                    }
                                }

                                progressHandler(ALTInstallationProgressUpdate(stage: .registeringDevice))
                                
                                self.register(altDevice, team: team, session: session) { (result) in
                                    do
                                    {
                                        let device = try result.get()
                                        device.osVersion = altDevice.osVersion

                                        progressHandler(ALTInstallationProgressUpdate(stage: .preparingCertificate))
                                        
                                        self.fetchCertificate(for: team, session: session) { (result) in
                                            do
                                            {
                                                let certificate = try result.get()

                                                progressHandler(ALTInstallationProgressUpdate(stage: .preparingDevice))
                                                
                                                self.prepare(device) { (result) in
                                                    switch result
                                                    {
                                                    case .failure(let error):
                                                        print("Failed to install DeveloperDiskImage.dmg to \(device).", error)
                                                        fallthrough // Continue installing app even if we couldn't install Developer disk image.
                                                    
                                                    case .success:
                                                        self.downloadApp(from: ipaFileURL, for: altDevice, downloadControl: downloadControl, progressHandler: progressHandler) { (result) in
                                                            do
                                                            {
                                                                let fileURL = try result.get()

                                                                progressHandler(ALTInstallationProgressUpdate(stage: .preparingApplication))
                                                                
                                                                try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                                                                
                                                                let appBundleURL = try FileManager.default.unzipAppBundle(at: fileURL, toDirectory: destinationDirectoryURL)
                                                                guard let application = ALTApplication(fileURL: appBundleURL) else { throw ALTError(.invalidApp) }
                                                                
                                                                appName = application.name
                                                                
                                                                // Refresh anisette data to prevent session timeouts.
                                                                AnisetteDataManager.shared.requestAnisetteData { (result) in
                                                                    do
                                                                    {
                                                                        let anisetteData = try result.get()
                                                                        session.anisetteData = anisetteData
                                                                        
                                                                        self.prepareAllProvisioningProfiles(for: application, device: device, team: team, session: session) { (result) in
                                                                            do
                                                                            {
                                                                                let profiles = try result.get()
                                                                                
                                                                                self.install(application, to: device, team: team, certificate: certificate, profiles: profiles, progressHandler: progressHandler) { (result) in
                                                                                    finish(result.map { application })
                                                                                }
                                                                            }
                                                                            catch
                                                                            {
                                                                                finish(.failure(error), failure: NSLocalizedString("AltForge Server could not fetch new provisioning profiles.", comment: ""))
                                                                            }
                                                                        }
                                                                    }
                                                                    catch
                                                                    {
                                                                        finish(.failure(error))
                                                                    }
                                                                }
                                                            }
                                                            catch
                                                            {
                                                                let failure = String(format: NSLocalizedString("%@ could not be downloaded.", comment: ""), appName)
                                                                finish(.failure(error), failure: failure)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            catch
                                            {
                                                finish(.failure(error), failure: NSLocalizedString("A valid signing certificate could not be created.", comment: ""))
                                            }
                                        }
                                    }
                                    catch
                                    {
                                        finish(.failure(error), failure: NSLocalizedString("Your device could not be registered with your development team.", comment: ""))
                                    }
                                }
                            }
                            catch
                            {
                                finish(.failure(error))
                            }
                        }
                    }
                    catch
                    {
                        finish(.failure(error), failure: NSLocalizedString("AltForge Server could not sign in with your Apple ID.", comment: ""))
                    }
                }
            }
            catch
            {
                finish(.failure(error))
            }
        }
    }
}

private extension ALTDeviceManager
{
    func prepare(_ device: ALTDevice, completionHandler: @escaping (Result<Void, Error>) -> Void)
    {        
        Task<Void, Never> {
            do
            {
                try await JITManager.shared.prepare(device)
                completionHandler(.success(()))
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
}

private extension ALTDeviceManager
{
    func downloadApp(from url: URL?, for device: ALTDevice, downloadControl: ALTInstallationDownloadControl, progressHandler: @escaping (ALTInstallationProgressUpdate) -> Void, completionHandler: @escaping (Result<URL, Error>) -> Void)
    {
        if let url, url.isFileURL
        {
            return completionHandler(.success(url))
        }
        
        self.fetchAltStoreDownload(for: device) { result in
            switch result
            {
            case .failure(let error):
                completionHandler(.failure(error))

            case .success(let descriptor):
                if let integrity = descriptor.integrity
                {
                    let candidates = self.releaseDownloadCandidates(for: descriptor, allowMirrors: true)
                    self.downloadReleaseAsset(candidates: candidates, integrity: integrity, downloadControl: downloadControl, progressHandler: progressHandler, completionHandler: completionHandler)
                }
                else
                {
                    self.fetchReleaseAssetIntegrity(for: descriptor.officialURL) { integrityResult in
                        let integrity = try? integrityResult.get()
                        let candidates = self.releaseDownloadCandidates(for: descriptor, allowMirrors: integrity != nil)
                        self.downloadReleaseAsset(candidates: candidates, integrity: integrity, downloadControl: downloadControl, progressHandler: progressHandler, completionHandler: completionHandler)
                    }
                }
            }
        }
    }

    func releaseDownloadCandidates(for descriptor: ReleaseDownloadDescriptor, allowMirrors: Bool) -> [ReleaseDownloadCandidate]
    {
        let officialURL = descriptor.officialURL
        let githubSource = ALTInstallationDownloadSource(identifier: "github", title: NSLocalizedString("GitHub (Official)", comment: ""))
        var candidates = [ReleaseDownloadCandidate(source: githubSource, url: officialURL, usesMirror: false)]
        guard allowMirrors, self.isOfficialReleaseURL(officialURL) else { return candidates }

        let configuredCandidates = descriptor.configuredMirrorURLs.prefix(4).enumerated().compactMap { index, url -> ReleaseDownloadCandidate? in
            guard self.isValidConfiguredMirrorURL(url), url != officialURL else { return nil }
            let host = url.host ?? NSLocalizedString("Configured CDN", comment: "")
            let title = String(format: NSLocalizedString("CDN (%@)", comment: ""), host)
            let source = ALTInstallationDownloadSource(identifier: "cdn-\(index)", title: title)
            return ReleaseDownloadCandidate(source: source, url: url, usesMirror: true)
        }

        let publicMirrorCandidates = githubReleaseMirrorPrefixes.enumerated().compactMap { index, prefix -> ReleaseDownloadCandidate? in
            guard let url = URL(string: prefix + officialURL.absoluteString) else { return nil }
            let host = url.host ?? String(format: NSLocalizedString("Mirror %d", comment: ""), index + 1)
            let title = String(format: NSLocalizedString("Mirror %d (%@)", comment: ""), index + 1, host)
            let source = ALTInstallationDownloadSource(identifier: "mirror-\(index)", title: title)
            return ReleaseDownloadCandidate(source: source, url: url, usesMirror: true)
        }

        // A repository-configured CDN is preferred in automatic mode, while GitHub remains the canonical source.
        candidates = configuredCandidates + candidates + publicMirrorCandidates
        return candidates
    }

    func isOfficialReleaseURL(_ url: URL) -> Bool
    {
        url.scheme?.lowercased() == "https" &&
        url.host?.lowercased() == "github.com" &&
        url.path.hasPrefix("/legeling/AltForge/releases/download/")
    }

    func isValidConfiguredMirrorURL(_ url: URL) -> Bool
    {
        url.scheme?.lowercased() == "https" &&
        url.host != nil &&
        url.user == nil &&
        url.password == nil &&
        url.fragment == nil
    }

    func fetchReleaseAssetIntegrity(for downloadURL: URL, completionHandler: @escaping (Result<ReleaseAssetIntegrity, Error>) -> Void)
    {
        let pathComponents = downloadURL.pathComponents.filter { $0 != "/" }
        guard downloadURL.scheme == "https",
              downloadURL.host?.lowercased() == "github.com",
              pathComponents.count == 6,
              pathComponents[0] == "legeling",
              pathComponents[1] == "AltForge",
              pathComponents[2] == "releases",
              pathComponents[3] == "download"
        else
        {
            let error = CocoaError(.fileReadUnsupportedScheme, userInfo: [NSURLErrorKey: downloadURL])
            return completionHandler(.failure(error))
        }

        let tag = pathComponents[4]
        let assetName = pathComponents[5]
        guard let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let metadataURL = URL(string: "https://api.github.com/repos/legeling/AltForge/releases/tags/\(encodedTag)")
        else
        {
            return completionHandler(.failure(CocoaError(.fileReadInvalidFileName)))
        }

        var request = URLRequest(url: metadataURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AltForge-Server", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        session.dataTask(with: request) { data, response, error in
            do
            {
                if let response = response as? HTTPURLResponse
                {
                    guard response.statusCode == 200 else {
                        throw CocoaError(.fileReadUnknown, userInfo: [NSURLErrorKey: metadataURL])
                    }
                }

                let (data, _) = try Result((data, response), error).get()
                guard data.count <= 1024 * 1024 else { throw CocoaError(.fileReadTooLarge) }

                let release = try Foundation.JSONDecoder().decode(GitHubRelease.self, from: data)
                guard let asset = release.assets.first(where: { $0.name == assetName && $0.downloadURL == downloadURL }),
                      asset.size > 0,
                      let digest = asset.digest?.lowercased(),
                      digest.hasPrefix("sha256:")
                else
                {
                    throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: metadataURL])
                }

                let sha256 = String(digest.dropFirst("sha256:".count))
                guard sha256.count == 64, sha256.allSatisfy({ $0.isHexDigit }) else {
                    throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: metadataURL])
                }

                completionHandler(.success(ReleaseAssetIntegrity(sha256: sha256, size: asset.size)))
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }.resume()
    }

    func downloadReleaseAsset(candidates: [ReleaseDownloadCandidate], integrity: ReleaseAssetIntegrity?, downloadControl: ALTInstallationDownloadControl, progressHandler: @escaping (ALTInstallationProgressUpdate) -> Void, completionHandler: @escaping (Result<URL, Error>) -> Void)
    {
        let automaticSource = ALTInstallationDownloadSource(identifier: "automatic", title: NSLocalizedString("Automatic (Recommended)", comment: ""))
        let availableSources = [automaticSource] + candidates.map(\.source)
        let stateLock = NSLock()
        var generation = 0
        var isFinished = false
        var currentTask: URLSessionDownloadTask?
        var currentObservation: NSKeyValueObservation?

        func isCurrent(_ expectedGeneration: Int) -> Bool
        {
            stateLock.lock()
            defer { stateLock.unlock() }
            return !isFinished && generation == expectedGeneration
        }

        func finish(_ result: Result<URL, Error>, expectedGeneration: Int)
        {
            stateLock.lock()
            guard !isFinished, generation == expectedGeneration else
            {
                stateLock.unlock()
                return
            }
            isFinished = true
            generation += 1
            let task = currentTask
            let observation = currentObservation
            currentTask = nil
            currentObservation = nil
            stateLock.unlock()

            observation?.invalidate()
            task?.cancel()
            downloadControl.finish()
            completionHandler(result)
        }

        func attempt(_ sequence: [ReleaseDownloadCandidate], index: Int, expectedGeneration: Int, previousError: Error? = nil)
        {
            guard isCurrent(expectedGeneration) else { return }
            guard sequence.indices.contains(index) else
            {
                let error = previousError ?? CocoaError(.fileNoSuchFile)
                let failure = NSLocalizedString("The selected download sources could not download AltForge.", comment: "")
                return finish(.failure((error as NSError).withLocalizedFailure(failure)), expectedGeneration: expectedGeneration)
            }

            let candidate = sequence[index]
            progressHandler(ALTInstallationProgressUpdate(
                stage: .downloading,
                fractionCompleted: 0,
                usesMirror: candidate.usesMirror,
                completedBytes: 0,
                totalBytes: integrity?.size,
                downloadSourceTitle: candidate.source.title
            ))

            var request = URLRequest(url: candidate.url)
            request.timeoutInterval = 45
            var downloadTask: URLSessionDownloadTask!
            downloadTask = session.downloadTask(with: request) { fileURL, response, error in
                guard isCurrent(expectedGeneration) else { return }

                stateLock.lock()
                guard !isFinished, generation == expectedGeneration, currentTask === downloadTask else
                {
                    stateLock.unlock()
                    return
                }
                let completedObservation = currentObservation
                currentTask = nil
                currentObservation = nil
                stateLock.unlock()
                completedObservation?.invalidate()

                do
                {
                    if let response = response as? HTTPURLResponse
                    {
                        guard (200..<300).contains(response.statusCode) else {
                            throw CocoaError(.fileReadUnknown, userInfo: [NSURLErrorKey: candidate.url])
                        }
                    }

                    let (fileURL, _) = try Result((fileURL, response), error).get()
                    defer { try? FileManager.default.removeItem(at: fileURL) }

                    if let integrity
                    {
                        let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? -1
                        guard fileSize == integrity.size,
                              try self.sha256(of: fileURL) == integrity.sha256
                        else
                        {
                            throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: candidate.url])
                        }
                    }

                    guard isCurrent(expectedGeneration) else { return }
                    progressHandler(ALTInstallationProgressUpdate(
                        stage: .downloading,
                        fractionCompleted: 1,
                        usesMirror: candidate.usesMirror,
                        completedBytes: integrity?.size,
                        totalBytes: integrity?.size,
                        downloadSourceTitle: candidate.source.title
                    ))
                    finish(.success(fileURL), expectedGeneration: expectedGeneration)
                }
                catch
                {
                    guard isCurrent(expectedGeneration) else { return }
                    attempt(sequence, index: index + 1, expectedGeneration: expectedGeneration, previousError: error)
                }
            }

            let speedLock = NSLock()
            let startedAt = ProcessInfo.processInfo.systemUptime
            var lastSampleTime = startedAt
            var lastCompletedBytes: Int64 = 0
            var smoothedBytesPerSecond: Double?
            let observation = downloadTask.progress.observe(\.completedUnitCount, options: [.initial, .new]) { progress, _ in
                guard isCurrent(expectedGeneration) else { return }

                let completedBytes = max(progress.completedUnitCount, 0)
                let totalBytes = integrity?.size ?? (progress.totalUnitCount > 0 ? progress.totalUnitCount : nil)
                let now = ProcessInfo.processInfo.systemUptime

                speedLock.lock()
                let elapsed = now - lastSampleTime
                if elapsed >= 0.25
                {
                    let transferred = max(completedBytes - lastCompletedBytes, 0)
                    let currentSpeed = Double(transferred) / elapsed
                    smoothedBytesPerSecond = smoothedBytesPerSecond.map { ($0 * 0.7) + (currentSpeed * 0.3) } ?? currentSpeed
                    lastSampleTime = now
                    lastCompletedBytes = completedBytes
                }
                let averageSpeed = now > startedAt ? Double(completedBytes) / (now - startedAt) : nil
                let bytesPerSecond = smoothedBytesPerSecond ?? averageSpeed
                speedLock.unlock()

                let fractionCompleted = totalBytes.flatMap { $0 > 0 ? min(Double(completedBytes) / Double($0), 1) : nil }
                progressHandler(ALTInstallationProgressUpdate(
                    stage: .downloading,
                    fractionCompleted: fractionCompleted,
                    usesMirror: candidate.usesMirror,
                    completedBytes: completedBytes,
                    totalBytes: totalBytes,
                    bytesPerSecond: bytesPerSecond,
                    downloadSourceTitle: candidate.source.title
                ))
            }

            stateLock.lock()
            guard !isFinished, generation == expectedGeneration else
            {
                stateLock.unlock()
                observation.invalidate()
                downloadTask.cancel()
                return
            }
            currentTask = downloadTask
            currentObservation = observation
            stateLock.unlock()
            downloadTask.resume()
        }

        func start(_ selectedIdentifier: String)
        {
            let sequence = selectedIdentifier == automaticSource.identifier
                ? candidates
                : candidates.filter { $0.source.identifier == selectedIdentifier }

            stateLock.lock()
            guard !isFinished else
            {
                stateLock.unlock()
                return
            }
            generation += 1
            let expectedGeneration = generation
            let task = currentTask
            let observation = currentObservation
            currentTask = nil
            currentObservation = nil
            stateLock.unlock()

            observation?.invalidate()
            task?.cancel()
            downloadControl.configure(sources: availableSources, selectedIdentifier: selectedIdentifier)
            attempt(sequence, index: 0, expectedGeneration: expectedGeneration)
        }

        downloadControl.setSelectionHandler { identifier in
            start(identifier)
        }
        start(automaticSource.identifier)
    }

    func sha256(of fileURL: URL) throws -> String
    {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        var hasher = SHA256()
        while true
        {
            let data = try fileHandle.read(upToCount: 1024 * 1024) ?? Data()
            guard !data.isEmpty else { break }
            hasher.update(data: data)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
    
    func releaseDownloadDescriptor(for version: Source.App.Version) -> ReleaseDownloadDescriptor
    {
        let normalizedSHA256 = version.sha256?.lowercased()
        let integrity: ReleaseAssetIntegrity?
        if let size = version.size,
           size > 0,
           let normalizedSHA256,
           normalizedSHA256.count == 64,
           normalizedSHA256.allSatisfy({ $0.isHexDigit })
        {
            integrity = ReleaseAssetIntegrity(sha256: normalizedSHA256, size: size)
        }
        else
        {
            integrity = nil
        }

        return ReleaseDownloadDescriptor(
            officialURL: version.downloadURL,
            integrity: integrity,
            configuredMirrorURLs: Array((version.downloadMirrors ?? []).prefix(4))
        )
    }

    func fetchAltStoreDownload(for device: ALTDevice, completion: @escaping (Result<ReleaseDownloadDescriptor, Error>) -> Void)
    {
        let dataTask = session.dataTask(with: altstoreSourceURL) { (data, response, error) in
            
            do
            {
                if let response = response as? HTTPURLResponse
                {
                    guard (200..<300).contains(response.statusCode) else { throw CocoaError(.fileNoSuchFile, userInfo: [NSURLErrorKey: altstoreSourceURL]) }
                }
                
                let (data, _) = try Result((data, response), error).get()
                guard data.count <= 1024 * 1024 else { throw CocoaError(.fileReadTooLarge) }
                let source = try Foundation.JSONDecoder().decode(Source.self, from: data)
                
                guard let altstore = source.apps.first(where: { $0.bundleIdentifier == altstoreBundleID }) else {
                    let debugDescription = String(format: NSLocalizedString("App with bundle ID '%@' does not exist in source JSON.", comment: ""), altstoreBundleID)
                    throw CocoaError(.coderValueNotFound, userInfo: [NSDebugDescriptionErrorKey: debugDescription])
                }
                guard let versions = altstore.versions else {
                    let debugDescription = String(format: NSLocalizedString("There is no 'versions' key for %@.", comment: ""), altstore.bundleIdentifier)
                    throw CocoaError(.coderReadCorrupt, userInfo: [NSDebugDescriptionErrorKey: debugDescription])
                }
                guard let latestVersion = versions.first else {
                    let debugDescription = String(format: NSLocalizedString("The 'versions' array is empty for %@.", comment: ""), altstore.bundleIdentifier)
                    throw CocoaError(.coderValueNotFound, userInfo: [NSDebugDescriptionErrorKey: debugDescription])
                }
                
                let osName = device.type.osName ?? "iOS"
                let minOSVersionString = latestVersion.minimumOSVersion?.stringValue ?? "12.2"
                
                guard let latestSupportedVersion = altstore.versions?.first(where: { appVersion in
                    if let minOSVersion = appVersion.minimumOSVersion, device.osVersion < minOSVersion
                    {
                        return false
                    }
                    
                    return true
                }) else { throw ALTServerError(.unsupportediOSVersion, userInfo: [ALTAppNameErrorKey: "AltForge",
                                                                      ALTOperatingSystemNameErrorKey: osName,
                                                                   ALTOperatingSystemVersionErrorKey: minOSVersionString]) }
                
                guard latestSupportedVersion.version != latestVersion.version else {
                    // The newest version is also the newest compatible version, so return its downloadURL.
                    return completion(.success(self.releaseDownloadDescriptor(for: latestVersion)))
                }
                
                DispatchQueue.main.async {
                    var message = String(format: NSLocalizedString("%@ is running %@ %@, but AltForge requires %@ %@ or later.", comment: ""), device.name, osName, device.osVersion.stringValue, osName, minOSVersionString)
                    message += "\n\n"
                    message += NSLocalizedString("Would you like to download the last version compatible with your device instead?", comment: "")
                    
                    let alert = NSAlert()
                    alert.messageText = String(format: NSLocalizedString("Unsupported %@ Version", comment: ""), osName)
                    alert.informativeText = message
                    
                    let buttonTitle = String(format: NSLocalizedString("Download %@ %@", comment: ""), altstore.name, latestSupportedVersion.version)
                    alert.addButton(withTitle: buttonTitle)
                    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                    
                    let index = alert.runModal()
                    if index == .alertFirstButtonReturn
                    {
                        completion(.success(self.releaseDownloadDescriptor(for: latestSupportedVersion)))
                    }
                    else
                    {
                        completion(.failure(OperationError.cancelled))
                    }
                }
                
            }
            catch let serverError as ALTServerError where serverError.code == .unsupportediOSVersion
            {
                // Don't add localized failure for unsupported iOS version errors.
                completion(.failure(serverError))
            }
            catch let error as NSError
            {
                completion(.failure(error.withLocalizedFailure("The download URL could not be determined.")))
            }
        }
        
        dataTask.resume()
    }
    
    func authenticate(appleID: String, password: String, anisetteData: ALTAnisetteData, completionHandler: @escaping (Result<(ALTAccount, ALTAppleAPISession), Error>) -> Void)
    {
        func handleVerificationCode(_ completionHandler: @escaping (String?) -> Void)
        {
            DispatchQueue.main.async {
                let verificationController = AppleIDVerificationWindowController()
                completionHandler(verificationController.runModal())
            }
        }
        
        ALTAppleAPI.shared.authenticate(appleID: appleID, password: password, anisetteData: anisetteData, verificationHandler: handleVerificationCode) { (account, session, error) in
            if let account = account, let session = session
            {
                completionHandler(.success((account, session)))
            }
            else
            {
                completionHandler(.failure(error ?? ALTAppleAPIError.unknown()))
            }
        }
    }
    
    func fetchTeam(for account: ALTAccount, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTTeam, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchTeams(for: account, session: session) { (teams, error) in
            do
            {
                let teams = try Result(teams, error).get()
                
                if let team = teams.first(where: { $0.type == .individual })
                {
                    return completionHandler(.success(team))
                }
                else if let team = teams.first(where: { $0.type == .organization })
                {
                    return completionHandler(.success(team))
                }
                else if let team = teams.first(where: { $0.type == .free })
                {
                    return completionHandler(.success(team))
                }
                else if let team = teams.first
                {
                    return completionHandler(.success(team))
                }
                else
                {
                    throw OperationError(.noTeam)
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func fetchCertificate(for team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTCertificate, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchCertificates(for: team, session: session) { (certificates, error) in
            do
            {
                let certificates = try Result(certificates, error).get()
                
                let certificateFileURL = FileManager.default.certificatesDirectory.appendingPathComponent(team.identifier + ".p12")
                try FileManager.default.createDirectory(at: FileManager.default.certificatesDirectory, withIntermediateDirectories: true, attributes: nil)
                
                // Only certificates explicitly created by AltForge (or legacy AltStore builds) are managed here.
                let managedCertificates = certificates.filter { certificate in
                    guard let machineName = certificate.machineName else { return false }
                    return machineName.hasPrefix("AltForge") || machineName.hasPrefix("AltStore")
                }

                if FileManager.default.fileExists(atPath: certificateFileURL.path),
                   let data = try? Data(contentsOf: certificateFileURL)
                {
                    for previousCertificate in managedCertificates
                    {
                        guard let machineIdentifier = previousCertificate.machineIdentifier,
                              let certificate = ALTCertificate(p12Data: data, password: machineIdentifier),
                              certificate.serialNumber == previousCertificate.serialNumber
                        else { continue }

                        // Restore the server-side identifier used to encrypt the embedded certificate.
                        certificate.machineIdentifier = machineIdentifier
                        return completionHandler(.success(certificate))
                    }
                }

                func confirmReplacement(of certificate: ALTCertificate) -> Bool
                {
                    var shouldReplace = false

                    func presentAlert()
                    {
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("Replace an existing AltForge development certificate?", comment: "")
                        let certificateName = certificate.machineName ?? NSLocalizedString("AltForge development certificate", comment: "")
                        alert.informativeText = String(
                            format: NSLocalizedString("AltForge Server cannot access the private key for “%@” in the “%@” team. Replacing this AltForge-managed certificate may stop apps installed by another AltForge or AltStore Server until they are reinstalled. Unrelated Xcode and distribution certificates will not be changed.", comment: ""),
                            certificateName,
                            team.name
                        )

                        alert.addButton(withTitle: NSLocalizedString("Replace AltForge Certificate", comment: ""))
                        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))

                        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
                        shouldReplace = alert.runModal() == .alertFirstButtonReturn
                    }

                    if Thread.isMainThread
                    {
                        presentAlert()
                    }
                    else
                    {
                        DispatchQueue.main.sync(execute: presentAlert)
                    }

                    return shouldReplace
                }

                func addCertificate()
                {
                    ALTAppleAPI.shared.addCertificate(machineName: "AltForge", to: team, session: session) { (certificate, error) in
                        do
                        {
                            let certificate = try Result(certificate, error).get()
                            guard let privateKey = certificate.privateKey else { throw OperationError(.missingPrivateKey) }

                            ALTAppleAPI.shared.fetchCertificates(for: team, session: session) { (certificates, error) in
                                do
                                {
                                    let certificates = try Result(certificates, error).get()

                                    guard let certificate = certificates.first(where: { $0.serialNumber == certificate.serialNumber }) else {
                                        throw OperationError(.missingCertificate)
                                    }

                                    certificate.privateKey = privateKey

                                    completionHandler(.success(certificate))

                                    if let machineIdentifier = certificate.machineIdentifier,
                                       let encryptedData = certificate.encryptedP12Data(withPassword: machineIdentifier)
                                    {
                                        // Cache certificate.
                                        do { try encryptedData.write(to: certificateFileURL, options: .atomic) }
                                        catch { print("Failed to cache certificate:", error) }
                                    }
                                }
                                catch
                                {
                                    completionHandler(.failure(error))
                                }
                            }
                        }
                        catch
                        {
                            completionHandler(.failure(error))
                        }
                    }
                }

                if let certificate = managedCertificates.first
                {
                    guard confirmReplacement(of: certificate) else { return completionHandler(.failure(OperationError(.cancelled))) }

                    ALTAppleAPI.shared.revoke(certificate, for: team, session: session) { (success, error) in
                        do
                        {
                            try Result(success, error).get()
                            addCertificate()
                        }
                        catch
                        {
                            completionHandler(.failure(error))
                        }
                    }
                }
                else
                {
                    addCertificate()
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func prepareAllProvisioningProfiles(for application: ALTApplication, device: ALTDevice, team: ALTTeam, session: ALTAppleAPISession,
                                        completion: @escaping (Result<[String: ALTProvisioningProfile], Error>) -> Void)
    {
        self.prepareProvisioningProfile(for: application, parentApp: nil, device: device, team: team, session: session) { (result) in
            do
            {
                let profile = try result.get()
                
                var profiles = [application.bundleIdentifier: profile]
                var error: Error?
                
                let dispatchGroup = DispatchGroup()
                
                for appExtension in application.appExtensions
                {
                    dispatchGroup.enter()
                    
                    self.prepareProvisioningProfile(for: appExtension, parentApp: application, device: device, team: team, session: session) { (result) in
                        switch result
                        {
                        case .failure(let e): error = e
                        case .success(let profile): profiles[appExtension.bundleIdentifier] = profile
                        }
                        
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .global()) {
                    if let error = error
                    {
                        completion(.failure(error))
                    }
                    else
                    {
                        completion(.success(profiles))
                    }
                }
            }
            catch
            {
                completion(.failure(error))
            }
        }
    }
    
    func prepareProvisioningProfile(for application: ALTApplication, parentApp: ALTApplication?, device: ALTDevice, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTProvisioningProfile, Error>) -> Void)
    {
        let parentBundleID = parentApp?.bundleIdentifier ?? application.bundleIdentifier
        let updatedParentBundleID: String
        
        if application.isAltStoreApp
        {
            // Use legacy bundle ID format for AltStore (and its extensions).
            updatedParentBundleID = "com.\(team.identifier).\(parentBundleID)"
        }
        else
        {
            updatedParentBundleID = parentBundleID + "." + team.identifier // Append just team identifier to make it harder to track.
        }
        
        let bundleID = application.bundleIdentifier.replacingOccurrences(of: parentBundleID, with: updatedParentBundleID)
        
        let preferredName: String
        
        if let parentApp = parentApp
        {
            preferredName = parentApp.name + " " + application.name
        }
        else
        {
            preferredName = application.name
        }
        
        self.registerAppID(name: preferredName, bundleID: bundleID, team: team, session: session) { (result) in
            do
            {
                let appID = try result.get()
                
                self.updateFeatures(for: appID, app: application, team: team, session: session) { (result) in
                    do
                    {
                        let appID = try result.get()
                        
                        self.updateAppGroups(for: appID, app: application, team: team, session: session) { (result) in
                            do
                            {
                                let appID = try result.get()
                                
                                self.fetchProvisioningProfile(for: appID, device: device, team: team, session: session) { (result) in
                                    completionHandler(result)
                                }
                            }
                            catch
                            {
                                completionHandler(.failure(error))
                            }
                        }
                    }
                    catch
                    {
                        completionHandler(.failure(error))
                    }
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func registerAppID(name appName: String, bundleID: String, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTAppID, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchAppIDs(for: team, session: session) { (appIDs, error) in
            do
            {
                let appIDs = try Result(appIDs, error).get()
                
                if let appID = appIDs.first(where: { $0.bundleIdentifier == bundleID })
                {
                    completionHandler(.success(appID))
                }
                else
                {
                    ALTAppleAPI.shared.addAppID(withName: appName, bundleIdentifier: bundleID, team: team, session: session) { (appID, error) in
                        completionHandler(Result(appID, error))
                    }
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func updateFeatures(for appID: ALTAppID, app: ALTApplication, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTAppID, Error>) -> Void)
    {
        let requiredFeatures = app.entitlements.compactMap { (entitlement, value) -> (ALTFeature, Any)? in
            guard let feature = ALTFeature(entitlement: entitlement) else { return nil }
            return (feature, value)
        }
        
        var features = requiredFeatures.reduce(into: [ALTFeature: Any]()) { $0[$1.0] = $1.1 }
        
        if let applicationGroups = app.entitlements[.appGroups] as? [String], !applicationGroups.isEmpty
        {
            // App uses app groups, so assign `true` to enable the feature.
            features[.appGroups] = true
        }
        else
        {
            // App has no app groups, so assign `false` to disable the feature.
            features[.appGroups] = false
        }
        
        var updateFeatures = false
        
        // Determine whether the required features are already enabled for the AppID.
        for (feature, value) in features
        {
            if let appIDValue = appID.features[feature] as AnyObject?, (value as AnyObject).isEqual(appIDValue)
            {
                // AppID already has this feature enabled and the values are the same.
                continue
            }
            else if appID.features[feature] == nil, let shouldEnableFeature = value as? Bool, !shouldEnableFeature
            {
                // AppID doesn't already have this feature enabled, but we want it disabled anyway.
                continue
            }
            else
            {
                // AppID either doesn't have this feature enabled or the value has changed,
                // so we need to update it to reflect new values.
                updateFeatures = true
                break
            }
        }
        
        if updateFeatures
        {
            let appID = appID.copy() as! ALTAppID
            appID.features = features
            
            ALTAppleAPI.shared.update(appID, team: team, session: session) { (appID, error) in
                completionHandler(Result(appID, error))
            }
        }
        else
        {
            completionHandler(.success(appID))
        }
    }
    
    func updateAppGroups(for appID: ALTAppID, app: ALTApplication, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTAppID, Error>) -> Void)
    {
        guard let applicationGroups = app.entitlements[.appGroups] as? [String], !applicationGroups.isEmpty else {
            // Assigning an App ID to an empty app group array fails,
            // so just do nothing if there are no app groups.
            return completionHandler(.success(appID))
        }
        
        // Dispatch onto global queue to prevent appGroupsSemaphore deadlock.
        DispatchQueue.global().async {
            
            // Ensure we're not concurrently fetching and updating app groups,
            // which can lead to race conditions such as adding an app group twice.
            appGroupsSemaphore.wait()
            
            func finish(_ result: Result<ALTAppID, Error>)
            {
                appGroupsSemaphore.signal()
                completionHandler(result)
            }
            
            ALTAppleAPI.shared.fetchAppGroups(for: team, session: session) { (groups, error) in
                switch Result(groups, error)
                {
                case .failure(let error): finish(.failure(error))
                case .success(let fetchedGroups):
                    let dispatchGroup = DispatchGroup()
                    
                    var groups = [ALTAppGroup]()
                    var errors = [Error]()
                    
                    for groupIdentifier in applicationGroups
                    {
                        let adjustedGroupIdentifier = groupIdentifier + "." + team.identifier
                        
                        if let group = fetchedGroups.first(where: { $0.groupIdentifier == adjustedGroupIdentifier })
                        {
                            groups.append(group)
                        }
                        else
                        {
                            dispatchGroup.enter()
                            
                            // Not all characters are allowed in group names, so we replace periods with spaces (like Apple does).
                            let name = "AltStore " + groupIdentifier.replacingOccurrences(of: ".", with: " ")
                            
                            ALTAppleAPI.shared.addAppGroup(withName: name, groupIdentifier: adjustedGroupIdentifier, team: team, session: session) { (group, error) in
                                switch Result(group, error)
                                {
                                case .success(let group): groups.append(group)
                                case .failure(let error): errors.append(error)
                                }
                                
                                dispatchGroup.leave()
                            }
                        }
                    }
                    
                    dispatchGroup.notify(queue: .global()) {
                        if let error = errors.first
                        {
                            finish(.failure(error))
                        }
                        else
                        {
                            ALTAppleAPI.shared.assign(appID, to: Array(groups), team: team, session: session) { (success, error) in
                                let result = Result(success, error)
                                finish(result.map { _ in appID })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func register(_ device: ALTDevice, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTDevice, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchDevices(for: team, types: device.type, session: session) { (devices, error) in
            do
            {
                let devices = try Result(devices, error).get()
                
                if let device = devices.first(where: { $0.identifier == device.identifier })
                {
                    completionHandler(.success(device))
                }
                else
                {
                    ALTAppleAPI.shared.registerDevice(name: device.name, identifier: device.identifier, type: device.type, team: team, session: session) { (device, error) in
                        completionHandler(Result(device, error))
                    }
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func fetchProvisioningProfile(for appID: ALTAppID, device: ALTDevice, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTProvisioningProfile, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchProvisioningProfile(for: appID, deviceType: device.type, team: team, session: session) { (profile, error) in
            completionHandler(Result(profile, error))
        }
    }
    
    func install(_ application: ALTApplication, to device: ALTDevice, team: ALTTeam, certificate: ALTCertificate, profiles: [String: ALTProvisioningProfile], progressHandler: @escaping (ALTInstallationProgressUpdate) -> Void, completionHandler: @escaping (Result<Void, Error>) -> Void)
    {
        func prepare(_ bundle: Bundle, additionalInfoDictionaryValues: [String: Any] = [:]) throws
        {
            guard let identifier = bundle.bundleIdentifier else { throw ALTError(.missingAppBundle) }
            guard let profile = profiles[identifier] else { throw ALTError(.missingProvisioningProfile) }
            guard var infoDictionary = bundle.completeInfoDictionary else { throw ALTError(.missingInfoPlist) }
            
            infoDictionary[kCFBundleIdentifierKey as String] = profile.bundleIdentifier
            infoDictionary[Bundle.Info.altBundleID] = identifier
            
            if (infoDictionary.keys.contains(Bundle.Info.deviceID)) {
                infoDictionary[Bundle.Info.deviceID] = device.identifier
            }

            for (key, value) in additionalInfoDictionaryValues
            {
                infoDictionary[key] = value
            }
            
            if let appGroups = profile.entitlements[.appGroups] as? [String]
            {
                infoDictionary[Bundle.Info.appGroups] = appGroups
            }
            
            try (infoDictionary as NSDictionary).write(to: bundle.infoPlistURL)
        }
        
        DispatchQueue.global().async {
            do
            {
                guard let appBundle = Bundle(url: application.fileURL) else { throw ALTError(.missingAppBundle) }
                guard let infoDictionary = appBundle.completeInfoDictionary else { throw ALTError(.missingInfoPlist) }
                
                let openAppURL = URL(string: "altstore-" + application.bundleIdentifier + "://")!
                
                var allURLSchemes = infoDictionary[Bundle.Info.urlTypes] as? [[String: Any]] ?? []
                
                // Embed open URL so AltBackup can return to AltStore.
                let altstoreURLScheme = ["CFBundleTypeRole": "Editor",
                                         "CFBundleURLName": application.bundleIdentifier,
                                         "CFBundleURLSchemes": [openAppURL.scheme!]] as [String : Any]
                allURLSchemes.append(altstoreURLScheme)
                
                var additionalValues: [String: Any] = [Bundle.Info.urlTypes: allURLSchemes]
                
                if application.isAltStoreApp
                {
                    additionalValues[Bundle.Info.deviceID] = device.identifier
                    additionalValues[Bundle.Info.serverID] = UserDefaults.standard.serverID
                    
                    if
                        let machineIdentifier = certificate.machineIdentifier,
                        let encryptedData = certificate.encryptedP12Data(withPassword: machineIdentifier)
                    {
                        additionalValues[Bundle.Info.certificateID] = certificate.serialNumber
                        
                        let certificateURL = application.fileURL.appendingPathComponent("ALTCertificate.p12")
                        try encryptedData.write(to: certificateURL, options: .atomic)
                    }
                }
                else if infoDictionary.keys.contains(Bundle.Info.deviceID)
                {
                    // There is an ALTDeviceID entry, so assume the app is using AltKit and replace it with the device's UDID.
                    additionalValues[Bundle.Info.deviceID] = device.identifier
                    additionalValues[Bundle.Info.serverID] = UserDefaults.standard.serverID
                }
                
                try prepare(appBundle, additionalInfoDictionaryValues: additionalValues)
                
                for appExtension in application.appExtensions
                {
                    guard let bundle = Bundle(url: appExtension.fileURL) else { throw ALTError(.missingAppBundle) }
                    try prepare(bundle)
                }
                
                let resigner = ALTSigner(team: team, certificate: certificate)
                progressHandler(ALTInstallationProgressUpdate(stage: .signing))
                resigner.signApp(at: application.fileURL, provisioningProfiles: Array(profiles.values)) { (success, error) in
                    do
                    {
                        try Result(success, error).get()
                        
                        let activeProfiles: Set<String>? = (team.type == .free && application.isAltStoreApp) ? Set(profiles.values.map(\.bundleIdentifier)) : nil
                        progressHandler(ALTInstallationProgressUpdate(stage: .installing))

                        let observationHolder = ProgressObservationHolder()
                        let progress = ALTDeviceManager.shared.installApp(at: application.fileURL, toDeviceWithUDID: device.identifier, activeProvisioningProfiles: activeProfiles) { (success, error) in
                            observationHolder.observation?.invalidate()
                            observationHolder.observation = nil
                            completionHandler(Result(success, error))
                        }

                        observationHolder.observation = progress.observe(\.fractionCompleted, options: [.initial, .new]) { progress, _ in
                            progressHandler(ALTInstallationProgressUpdate(stage: .installing, fractionCompleted: progress.fractionCompleted))
                        }
                    }
                    catch
                    {
                        print("Failed to install app", error)
                        completionHandler(.failure(error))
                    }
                }
            }
            catch
            {
                print("Failed to install AltForge", error)
                completionHandler(.failure(error))
            }
        }
    }
    
}
