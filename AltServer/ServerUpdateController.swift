//
//  ServerUpdateController.swift
//  AltServer
//
//  Copyright © 2026 AltForge contributors.
//

import AppKit
import CryptoKit

private enum ServerUpdateConstants
{
    static let latestReleaseURL = URL(string: "https://api.github.com/repos/legeling/AltForge/releases/latest")!
    static let releasesURL = URL(string: "https://github.com/legeling/AltForge/releases")!
    static let installerAssetName = "AltForge-AltServer-macOS.dmg"
    static let maximumMetadataSize = 1_048_576
    static let maximumInstallerSize: Int64 = 512 * 1_024 * 1_024
}

private struct ServerGitHubRelease: Decodable
{
    struct Asset: Decodable
    {
        let name: String
        let size: Int64
        let digest: String?
        let downloadURL: URL

        private enum CodingKeys: String, CodingKey
        {
            case name
            case size
            case digest
            case downloadURL = "browser_download_url"
        }
    }

    let tagName: String
    let htmlURL: URL
    let assets: [Asset]

    private enum CodingKeys: String, CodingKey
    {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }
}

private struct ServerUpdateAsset
{
    let version: String
    let releaseURL: URL
    let downloadURL: URL
    let size: Int64
    let sha256: String
}

private enum ServerUpdateError: LocalizedError
{
    case invalidRelease
    case missingInstaller
    case invalidInstaller
    case downloadsDirectoryUnavailable
    case integrityCheckFailed

    var errorDescription: String?
    {
        switch self
        {
        case .invalidRelease:
            return NSLocalizedString("GitHub returned release information that AltForge Server could not verify.", comment: "")

        case .missingInstaller:
            return NSLocalizedString("The latest release does not include a verified macOS installer.", comment: "")

        case .invalidInstaller:
            return NSLocalizedString("The macOS installer link or integrity metadata is invalid.", comment: "")

        case .downloadsDirectoryUnavailable:
            return NSLocalizedString("AltForge Server could not access your Downloads folder.", comment: "")

        case .integrityCheckFailed:
            return NSLocalizedString("The downloaded installer did not match the size and SHA-256 published by GitHub.", comment: "")
        }
    }
}

final class ServerUpdateController: NSObject
{
    private let metadataSession: URLSession
    private var metadataTask: URLSessionDataTask?
    private var downloadTransfer: ServerUpdateDownloadTransfer?
    private var progressController: ServerUpdateProgressWindowController?
    private var downloadGeneration = 0

    override init()
    {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        self.metadataSession = URLSession(configuration: configuration)
        super.init()
    }

    deinit
    {
        self.metadataSession.invalidateAndCancel()
        self.downloadTransfer?.cancel()
    }

    func checkForUpdates(menuItem: NSMenuItem)
    {
        if let progressController = self.progressController
        {
            progressController.show()
            return
        }

        guard self.metadataTask == nil else { return }

        menuItem.isEnabled = false
        menuItem.title = NSLocalizedString("Checking for Updates…", comment: "")

        var request = URLRequest(url: ServerUpdateConstants.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AltForge-Server", forHTTPHeaderField: "User-Agent")

        let task = self.metadataSession.dataTask(with: request) { [weak self, weak menuItem] data, response, error in
            DispatchQueue.main.async {
                menuItem?.isEnabled = true
                menuItem?.title = NSLocalizedString("Check for Updates…", comment: "")

                guard let self else { return }
                self.metadataTask = nil

                do
                {
                    if let error { throw error }
                    guard let response = response as? HTTPURLResponse,
                          response.statusCode == 200,
                          let data
                    else { throw ServerUpdateError.invalidRelease }
                    guard data.count <= ServerUpdateConstants.maximumMetadataSize else { throw ServerUpdateError.invalidRelease }
                    let release = try JSONDecoder().decode(ServerGitHubRelease.self, from: data)
                    try self.showUpdateResult(release)
                }
                catch
                {
                    self.showUpdateCheckFailure(error)
                }
            }
        }
        self.metadataTask = task
        task.resume()
    }

    func cancel()
    {
        self.metadataTask?.cancel()
        self.metadataTask = nil
        self.cancelDownload()
    }
}

private extension ServerUpdateController
{
    func showUpdateResult(_ release: ServerGitHubRelease) throws
    {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        guard let latestVersion = self.semanticVersion(from: release.tagName) else { throw ServerUpdateError.invalidRelease }

        guard latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending else
        {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("AltForge Server Is Up to Date", comment: "")
            alert.informativeText = String(format: NSLocalizedString("You are using the latest version (%@).", comment: ""), currentVersion)
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            self.activateApplication()
            alert.runModal()
            return
        }

        let asset = try self.validatedInstaller(in: release, version: latestVersion)
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Update Available", comment: "")
        alert.informativeText = String(format: NSLocalizedString("AltForge Server %@ is available. You are using %@.", comment: ""), latestVersion, currentVersion)
            + "\n\n"
            + NSLocalizedString("AltForge Server will download the verified disk image and open the installer automatically.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Download Update", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))

        self.activateApplication()
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        self.startDownload(asset)
    }

    func validatedInstaller(in release: ServerGitHubRelease, version: String) throws -> ServerUpdateAsset
    {
        guard self.isReleasePageURL(release.htmlURL),
              let asset = release.assets.first(where: { $0.name == ServerUpdateConstants.installerAssetName })
        else { throw ServerUpdateError.missingInstaller }

        let expectedPath = "/legeling/AltForge/releases/download/\(release.tagName)/\(ServerUpdateConstants.installerAssetName)"
        guard asset.downloadURL.scheme?.lowercased() == "https",
              asset.downloadURL.host?.lowercased() == "github.com",
              asset.downloadURL.path == expectedPath,
              asset.downloadURL.user == nil,
              asset.downloadURL.password == nil,
              asset.downloadURL.query == nil,
              asset.downloadURL.fragment == nil,
              asset.size > 0,
              asset.size <= ServerUpdateConstants.maximumInstallerSize,
              let digest = asset.digest?.lowercased(),
              digest.hasPrefix("sha256:")
        else { throw ServerUpdateError.invalidInstaller }

        let sha256 = String(digest.dropFirst("sha256:".count))
        guard sha256.count == 64, sha256.allSatisfy(\.isHexDigit) else { throw ServerUpdateError.invalidInstaller }

        return ServerUpdateAsset(version: version, releaseURL: release.htmlURL, downloadURL: asset.downloadURL, size: asset.size, sha256: sha256)
    }

    func startDownload(_ asset: ServerUpdateAsset)
    {
        guard self.downloadTransfer == nil else
        {
            self.progressController?.show()
            return
        }

        let progressController = ServerUpdateProgressWindowController(version: asset.version)
        progressController.cancelHandler = { [weak self] in self?.cancelDownload() }
        self.progressController = progressController
        progressController.show()

        self.downloadGeneration += 1
        let expectedGeneration = self.downloadGeneration
        let transfer = ServerUpdateDownloadTransfer(asset: asset, progressHandler: { [weak progressController] completedBytes, totalBytes in
            DispatchQueue.main.async {
                progressController?.update(completedBytes: completedBytes, totalBytes: totalBytes)
            }
        }, completionHandler: { [weak self] result in
            DispatchQueue.main.async {
                guard let self,
                      self.downloadTransfer != nil,
                      self.downloadGeneration == expectedGeneration
                else { return }
                self.downloadTransfer = nil
                self.progressController?.finish()
                self.progressController = nil

                switch result
                {
                case .success(let fileURL):
                    self.openInstaller(fileURL, releaseURL: asset.releaseURL)

                case .failure(let error):
                    guard (error as? URLError)?.code != .cancelled else { return }
                    self.showDownloadFailure(error, asset: asset)
                }
            }
        })
        self.downloadTransfer = transfer
        transfer.start()
    }

    func cancelDownload()
    {
        let transfer = self.downloadTransfer
        self.downloadTransfer = nil
        self.downloadGeneration += 1
        transfer?.cancel()
        self.progressController?.finish()
        self.progressController = nil
    }

    func openInstaller(_ fileURL: URL, releaseURL: URL)
    {
        guard NSWorkspace.shared.open(fileURL) else
        {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("Unable to Open Installer", comment: "")
            alert.informativeText = NSLocalizedString("The verified disk image remains in Downloads. Open it manually to install the update.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("Show in Finder", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Open Releases", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            self.activateApplication()

            switch alert.runModal()
            {
            case .alertFirstButtonReturn:
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])

            case .alertSecondButtonReturn:
                self.openReleasePage(releaseURL)

            default:
                break
            }
            return
        }
    }

    func showDownloadFailure(_ error: Error, asset: ServerUpdateAsset)
    {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = NSLocalizedString("Unable to Download Update", comment: "")
        alert.informativeText = NSLocalizedString("AltForge Server could not download and verify the update.", comment: "")
            + "\n\n"
            + error.localizedDescription
        alert.addButton(withTitle: NSLocalizedString("Retry", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Open Releases", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        self.activateApplication()

        switch alert.runModal()
        {
        case .alertFirstButtonReturn:
            self.startDownload(asset)

        case .alertSecondButtonReturn:
            self.openReleasePage(asset.releaseURL)

        default:
            break
        }
    }

    func showUpdateCheckFailure(_ error: Error)
    {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = NSLocalizedString("Unable to Check for Updates", comment: "")
        alert.informativeText = NSLocalizedString("AltForge Server could not read the latest release from GitHub. You can open the Releases page and check manually.", comment: "")
            + "\n\n"
            + error.localizedDescription
        alert.addButton(withTitle: NSLocalizedString("Open Releases", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        self.activateApplication()

        if alert.runModal() == .alertFirstButtonReturn
        {
            self.openReleasePage(ServerUpdateConstants.releasesURL)
        }
    }

    func semanticVersion(from tag: String) -> String?
    {
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let components = version.split(separator: ".", omittingEmptySubsequences: false)
        guard version.count <= 32,
              components.count == 3,
              components.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) })
        else { return nil }
        return version
    }

    func isReleasePageURL(_ url: URL) -> Bool
    {
        url.scheme?.lowercased() == "https" &&
        url.host?.lowercased() == "github.com" &&
        url.path.hasPrefix("/legeling/AltForge/releases/tag/") &&
        url.user == nil &&
        url.password == nil &&
        url.query == nil &&
        url.fragment == nil
    }

    func openReleasePage(_ url: URL)
    {
        guard url == ServerUpdateConstants.releasesURL || self.isReleasePageURL(url) else { return }
        NSWorkspace.shared.open(url)
    }

    func activateApplication()
    {
        if #available(macOS 14.0, *)
        {
            NSRunningApplication.current.activate()
        }
        else
        {
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        }
    }
}

private final class ServerUpdateDownloadTransfer: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate
{
    typealias ProgressHandler = (_ completedBytes: Int64, _ totalBytes: Int64?) -> Void
    typealias CompletionHandler = (Result<URL, Error>) -> Void

    private let asset: ServerUpdateAsset
    private let progressHandler: ProgressHandler
    private var completionHandler: CompletionHandler?
    private var session: URLSession!
    private var task: URLSessionDownloadTask?
    private var downloadedFileURL: URL?
    private var fileError: Error?

    init(asset: ServerUpdateAsset, progressHandler: @escaping ProgressHandler, completionHandler: @escaping CompletionHandler)
    {
        self.asset = asset
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        super.init()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 600

        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.qualityOfService = .utility
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    }

    func start()
    {
        guard self.task == nil else { return }
        var request = URLRequest(url: self.asset.downloadURL)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        request.setValue("AltForge-Server", forHTTPHeaderField: "User-Agent")
        let task = self.session.downloadTask(with: request)
        self.task = task
        task.resume()
    }

    func cancel()
    {
        self.task?.cancel()
        self.session.invalidateAndCancel()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    )
    {
        let responseSize = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil
        self.progressHandler(max(totalBytesWritten, 0), responseSize ?? self.asset.size)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        do
        {
            if let response = downloadTask.response as? HTTPURLResponse
            {
                guard (200..<300).contains(response.statusCode) else { throw ServerUpdateError.invalidInstaller }
            }

            let fileSize = try location.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? -1
            guard fileSize == self.asset.size,
                  try self.sha256(of: location) == self.asset.sha256
            else { throw ServerUpdateError.integrityCheckFailed }

            let destinationURL = try self.destinationURL()
            if FileManager.default.fileExists(atPath: destinationURL.path)
            {
                self.downloadedFileURL = destinationURL
            }
            else
            {
                try FileManager.default.moveItem(at: location, to: destinationURL)
                self.downloadedFileURL = destinationURL
            }
        }
        catch
        {
            self.fileError = error
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        let completionHandler = self.completionHandler
        self.completionHandler = nil
        self.task = nil
        session.finishTasksAndInvalidate()

        if let error = self.fileError ?? error
        {
            completionHandler?(.failure(error))
        }
        else if let downloadedFileURL = self.downloadedFileURL
        {
            completionHandler?(.success(downloadedFileURL))
        }
        else
        {
            completionHandler?(.failure(ServerUpdateError.invalidInstaller))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        completionHandler(.performDefaultHandling, nil)
    }
}

private extension ServerUpdateDownloadTransfer
{
    func destinationURL() throws -> URL
    {
        guard let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw ServerUpdateError.downloadsDirectoryUnavailable
        }

        let baseName = "AltForge-AltServer-macOS-v\(self.asset.version)"
        for index in 0..<100
        {
            let suffix = index == 0 ? "" : " (\(index + 1))"
            let candidate = downloadsDirectory.appendingPathComponent(baseName + suffix).appendingPathExtension("dmg")
            guard FileManager.default.fileExists(atPath: candidate.path) else { return candidate }

            let fileSize = try? candidate.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)
            if fileSize == self.asset.size, (try? self.sha256(of: candidate)) == self.asset.sha256
            {
                return candidate
            }
        }

        throw CocoaError(.fileWriteFileExists)
    }

    func sha256(of fileURL: URL) throws -> String
    {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        var hasher = SHA256()
        while let data = try fileHandle.read(upToCount: 1_048_576), !data.isEmpty
        {
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

private final class ServerUpdateProgressWindowController: NSWindowController, NSWindowDelegate
{
    var cancelHandler: (() -> Void)?

    private let version: String
    private let detailLabel = NSTextField(wrappingLabelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    private let transferLabel = NSTextField(labelWithString: "")
    private let percentageLabel = NSTextField(labelWithString: "")
    private let cancelButton = NSButton(title: NSLocalizedString("Cancel", comment: ""), target: nil, action: nil)
    private var isCancelling = false

    init(version: String)
    {
        self.version = version

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 208),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("Downloading Update", comment: "")
        window.isReleasedWhenClosed = false
        window.animationBehavior = .alertPanel
        window.center()

        super.init(window: window)
        window.delegate = self
        self.configureContent()
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    func show()
    {
        guard let window = self.window else { return }
        window.center()
        self.showWindow(nil)
        window.makeKeyAndOrderFront(nil)

        if #available(macOS 14.0, *)
        {
            NSRunningApplication.current.activate()
        }
        else
        {
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        }
    }

    func update(completedBytes: Int64, totalBytes: Int64?)
    {
        guard !self.isCancelling else { return }

        let totalBytes = totalBytes.flatMap { $0 > 0 ? $0 : nil }
        if let totalBytes
        {
            self.progressIndicator.stopAnimation(nil)
            self.progressIndicator.isIndeterminate = false
            self.progressIndicator.doubleValue = min(max(Double(completedBytes) / Double(totalBytes), 0), 1)
            self.transferLabel.stringValue = String(
                format: NSLocalizedString("Downloaded %@ of %@", comment: ""),
                ByteCountFormatter.string(fromByteCount: completedBytes, countStyle: .file),
                ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            )
            self.percentageLabel.stringValue = "\(Int((self.progressIndicator.doubleValue * 100).rounded()))%"
        }
        else
        {
            self.progressIndicator.isIndeterminate = true
            self.progressIndicator.startAnimation(nil)
            self.transferLabel.stringValue = ByteCountFormatter.string(fromByteCount: completedBytes, countStyle: .file)
            self.percentageLabel.stringValue = ""
        }
    }

    func finish()
    {
        self.progressIndicator.stopAnimation(nil)
        self.window?.orderOut(nil)
        self.cancelHandler = nil
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool
    {
        self.requestCancellation()
        return false
    }
}

private extension ServerUpdateProgressWindowController
{
    func configureContent()
    {
        guard let window = self.window else { return }

        let contentView = NSView()
        window.contentView = contentView

        let iconView = NSImageView(image: NSApplication.shared.applicationIconImage)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Downloading Update", comment: ""))
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        self.detailLabel.stringValue = String(format: NSLocalizedString("Downloading AltForge Server %@ from GitHub…", comment: ""), self.version)
        self.detailLabel.textColor = .secondaryLabelColor
        self.detailLabel.maximumNumberOfLines = 2

        self.progressIndicator.minValue = 0
        self.progressIndicator.maxValue = 1
        self.progressIndicator.isIndeterminate = true
        self.progressIndicator.controlSize = .regular
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.progressIndicator.startAnimation(nil)

        for label in [self.transferLabel, self.percentageLabel]
        {
            label.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            label.textColor = .secondaryLabelColor
        }
        self.transferLabel.stringValue = NSLocalizedString("Preparing download…", comment: "")
        self.percentageLabel.alignment = .right

        let progressLabels = NSStackView(views: [self.transferLabel, self.percentageLabel])
        progressLabels.orientation = .horizontal
        progressLabels.distribution = .fill

        self.cancelButton.target = self
        self.cancelButton.action = #selector(self.cancelDownload(_:))
        self.cancelButton.keyEquivalent = "\u{1b}"
        self.cancelButton.bezelStyle = .rounded

        let buttonRow = NSStackView(views: [NSView(), self.cancelButton])
        buttonRow.orientation = .horizontal
        buttonRow.distribution = .fill

        let contentStack = NSStackView(views: [titleLabel, self.detailLabel, self.progressIndicator, progressLabels, buttonRow])
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconView)
        contentView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            contentStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -18),
            self.detailLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            self.progressIndicator.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            progressLabels.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }

    @objc func cancelDownload(_ sender: NSButton)
    {
        self.requestCancellation()
    }

    func requestCancellation()
    {
        guard !self.isCancelling else { return }
        self.isCancelling = true
        self.cancelButton.isEnabled = false
        self.detailLabel.stringValue = NSLocalizedString("Cancelling download…", comment: "")
        self.cancelHandler?()
    }
}
