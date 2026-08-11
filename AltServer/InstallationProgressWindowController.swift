//
//  InstallationProgressWindowController.swift
//  AltServer
//
//  Copyright © 2026 AltForge contributors.
//

import AppKit

struct ALTInstallationDownloadSource: Hashable
{
    let identifier: String
    let title: String
}

final class ALTInstallationDownloadControl
{
    typealias StateHandler = ([ALTInstallationDownloadSource], String) -> Void

    private let lock = NSLock()
    private var sources = [ALTInstallationDownloadSource]()
    private var selectedIdentifier = "automatic"
    private var stateHandler: StateHandler?
    private var selectionHandler: ((String) -> Void)?

    func observe(_ handler: @escaping StateHandler)
    {
        self.lock.lock()
        self.stateHandler = handler
        let sources = self.sources
        let selectedIdentifier = self.selectedIdentifier
        self.lock.unlock()

        DispatchQueue.main.async {
            handler(sources, selectedIdentifier)
        }
    }

    func configure(sources: [ALTInstallationDownloadSource], selectedIdentifier: String = "automatic")
    {
        self.lock.lock()
        self.sources = sources
        self.selectedIdentifier = selectedIdentifier
        let handler = self.stateHandler
        self.lock.unlock()

        DispatchQueue.main.async {
            handler?(sources, selectedIdentifier)
        }
    }

    func setSelectionHandler(_ handler: @escaping (String) -> Void)
    {
        self.lock.lock()
        self.selectionHandler = handler
        self.lock.unlock()
    }

    func select(_ identifier: String)
    {
        self.lock.lock()
        guard self.sources.contains(where: { $0.identifier == identifier }) else
        {
            self.lock.unlock()
            return
        }

        self.selectedIdentifier = identifier
        let stateHandler = self.stateHandler
        let selectionHandler = self.selectionHandler
        let sources = self.sources
        self.lock.unlock()

        stateHandler?(sources, identifier)
        selectionHandler?(identifier)
    }

    func finish()
    {
        self.lock.lock()
        self.selectionHandler = nil
        self.lock.unlock()
    }
}

struct ALTInstallationProgressUpdate
{
    enum Stage
    {
        case fetchingTeam
        case registeringDevice
        case preparingCertificate
        case preparingDevice
        case downloading
        case preparingApplication
        case signing
        case installing
        case completed
    }

    let stage: Stage
    let fractionCompleted: Double?
    let usesMirror: Bool
    let completedBytes: Int64?
    let totalBytes: Int64?
    let bytesPerSecond: Double?
    let downloadSourceTitle: String?

    init(
        stage: Stage,
        fractionCompleted: Double? = nil,
        usesMirror: Bool = false,
        completedBytes: Int64? = nil,
        totalBytes: Int64? = nil,
        bytesPerSecond: Double? = nil,
        downloadSourceTitle: String? = nil
    )
    {
        self.stage = stage
        self.fractionCompleted = fractionCompleted
        self.usesMirror = usesMirror
        self.completedBytes = completedBytes
        self.totalBytes = totalBytes
        self.bytesPerSecond = bytesPerSecond
        self.downloadSourceTitle = downloadSourceTitle
    }
}

final class InstallationProgressWindowController: NSWindowController
{
    private let deviceName: String
    private let downloadControl: ALTInstallationDownloadControl
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    private let transferLabel = NSTextField(labelWithString: "")
    private let percentageLabel = NSTextField(labelWithString: "")
    private let currentSourceLabel = NSTextField(labelWithString: "")
    private let sourcePicker = NSPopUpButton()
    private let downloadInformationStack = NSStackView()
    private let sourceStack = NSStackView()

    init(deviceName: String, downloadControl: ALTInstallationDownloadControl)
    {
        self.deviceName = deviceName
        self.downloadControl = downloadControl

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 190),
            styleMask: [.titled, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("Installation Progress", comment: "")
        window.isReleasedWhenClosed = false
        window.animationBehavior = .alertPanel
        window.center()

        super.init(window: window)
        self.configureContent()
        self.downloadControl.observe { [weak self] sources, selectedIdentifier in
            self?.updateDownloadSources(sources, selectedIdentifier: selectedIdentifier)
        }
        self.update(ALTInstallationProgressUpdate(stage: .fetchingTeam))
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

    func update(_ update: ALTInstallationProgressUpdate)
    {
        if !Thread.isMainThread
        {
            return DispatchQueue.main.async { [weak self] in self?.update(update) }
        }

        switch update.stage
        {
        case .fetchingTeam:
            self.titleLabel.stringValue = NSLocalizedString("Apple ID Verified", comment: "")
            self.detailLabel.stringValue = NSLocalizedString("Checking your developer account…", comment: "")

        case .registeringDevice:
            self.titleLabel.stringValue = NSLocalizedString("Preparing Device", comment: "")
            self.detailLabel.stringValue = String(format: NSLocalizedString("Registering %@ with your developer account…", comment: ""), self.deviceName)

        case .preparingCertificate:
            self.titleLabel.stringValue = NSLocalizedString("Preparing Signing", comment: "")
            self.detailLabel.stringValue = NSLocalizedString("Checking the AltForge signing certificate…", comment: "")

        case .preparingDevice:
            self.titleLabel.stringValue = NSLocalizedString("Preparing Device", comment: "")
            self.detailLabel.stringValue = String(format: NSLocalizedString("Preparing %@ for installation…", comment: ""), self.deviceName)

        case .downloading:
            self.titleLabel.stringValue = NSLocalizedString("Downloading AltForge", comment: "")
            self.detailLabel.stringValue = update.usesMirror
                ? NSLocalizedString("Downloading the verified IPA from the selected mirror…", comment: "")
                : NSLocalizedString("Downloading the IPA from the AltForge GitHub Release…", comment: "")

        case .preparingApplication:
            self.titleLabel.stringValue = NSLocalizedString("Preparing AltForge", comment: "")
            self.detailLabel.stringValue = NSLocalizedString("Reading the IPA and preparing provisioning profiles…", comment: "")

        case .signing:
            self.titleLabel.stringValue = NSLocalizedString("Signing AltForge", comment: "")
            self.detailLabel.stringValue = NSLocalizedString("Signing the app for your device…", comment: "")

        case .installing:
            self.titleLabel.stringValue = NSLocalizedString("Installing AltForge", comment: "")
            self.detailLabel.stringValue = String(format: NSLocalizedString("Sending and installing AltForge on %@…", comment: ""), self.deviceName)

        case .completed:
            self.titleLabel.stringValue = NSLocalizedString("Installation Complete", comment: "")
            self.detailLabel.stringValue = String(format: NSLocalizedString("AltForge was successfully installed on %@.", comment: ""), self.deviceName)
        }

        self.setDownloadControlsVisible(update.stage == .downloading)
        self.setProgress(update)
    }

    func closeProgressWindow()
    {
        self.progressIndicator.stopAnimation(nil)
        self.window?.orderOut(nil)
    }
}

private extension InstallationProgressWindowController
{
    func configureContent()
    {
        guard let window = self.window else { return }

        let contentView = NSView()
        window.contentView = contentView

        let iconView = NSImageView(image: NSApplication.shared.applicationIconImage)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        self.titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        self.titleLabel.lineBreakMode = .byTruncatingTail

        self.detailLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        self.detailLabel.textColor = .secondaryLabelColor
        self.detailLabel.maximumNumberOfLines = 2

        self.progressIndicator.minValue = 0
        self.progressIndicator.maxValue = 1
        self.progressIndicator.controlSize = .regular
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        for label in [self.transferLabel, self.percentageLabel, self.currentSourceLabel]
        {
            label.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            label.textColor = .secondaryLabelColor
        }
        self.percentageLabel.alignment = .right
        self.currentSourceLabel.lineBreakMode = .byTruncatingMiddle

        self.sourcePicker.controlSize = .small
        self.sourcePicker.target = self
        self.sourcePicker.action = #selector(self.selectDownloadSource(_:))
        self.sourcePicker.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = NSStackView(views: [self.titleLabel, self.detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 5
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let headerRow = NSStackView(views: [iconView, textStack])
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 14
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        self.downloadInformationStack.addView(self.transferLabel, in: .leading)
        self.downloadInformationStack.addView(self.percentageLabel, in: .trailing)
        self.downloadInformationStack.orientation = .horizontal
        self.downloadInformationStack.alignment = .centerY
        self.downloadInformationStack.distribution = .fill
        self.downloadInformationStack.translatesAutoresizingMaskIntoConstraints = false

        self.sourceStack.addView(self.currentSourceLabel, in: .leading)
        self.sourceStack.addView(self.sourcePicker, in: .trailing)
        self.sourceStack.orientation = .horizontal
        self.sourceStack.alignment = .centerY
        self.sourceStack.distribution = .fill
        self.sourceStack.spacing = 12
        self.sourceStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(headerRow)
        contentView.addSubview(self.progressIndicator)
        contentView.addSubview(self.downloadInformationStack)
        contentView.addSubview(self.sourceStack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            headerRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerRow.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            self.progressIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            self.progressIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            self.progressIndicator.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 24),
            self.downloadInformationStack.leadingAnchor.constraint(equalTo: self.progressIndicator.leadingAnchor),
            self.downloadInformationStack.trailingAnchor.constraint(equalTo: self.progressIndicator.trailingAnchor),
            self.downloadInformationStack.topAnchor.constraint(equalTo: self.progressIndicator.bottomAnchor, constant: 7),
            self.sourceStack.leadingAnchor.constraint(equalTo: self.progressIndicator.leadingAnchor),
            self.sourceStack.trailingAnchor.constraint(equalTo: self.progressIndicator.trailingAnchor),
            self.sourceStack.topAnchor.constraint(equalTo: self.downloadInformationStack.bottomAnchor, constant: 10),
            self.sourceStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -18),
            self.percentageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            self.sourcePicker.widthAnchor.constraint(greaterThanOrEqualToConstant: 128)
        ])
    }

    func setProgress(_ update: ALTInstallationProgressUpdate)
    {
        guard let fractionCompleted = update.fractionCompleted, fractionCompleted.isFinite else
        {
            self.progressIndicator.isIndeterminate = true
            self.progressIndicator.startAnimation(nil)
            self.transferLabel.stringValue = ""
            self.percentageLabel.stringValue = ""
            self.updateCurrentSourceLabel(update.downloadSourceTitle)
            return
        }

        let boundedFraction = min(max(fractionCompleted, 0), 1)
        self.progressIndicator.stopAnimation(nil)
        self.progressIndicator.isIndeterminate = false
        self.progressIndicator.doubleValue = boundedFraction
        self.percentageLabel.stringValue = NumberFormatter.localizedString(from: NSNumber(value: boundedFraction), number: .percent)
        self.updateTransferLabel(completedBytes: update.completedBytes, totalBytes: update.totalBytes, bytesPerSecond: update.bytesPerSecond)
        self.updateCurrentSourceLabel(update.downloadSourceTitle)
    }

    func updateTransferLabel(completedBytes: Int64?, totalBytes: Int64?, bytesPerSecond: Double?)
    {
        guard let completedBytes, let totalBytes, totalBytes > 0 else
        {
            self.transferLabel.stringValue = ""
            return
        }

        let completed = ByteCountFormatter.string(fromByteCount: max(completedBytes, 0), countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        if let bytesPerSecond, bytesPerSecond.isFinite, bytesPerSecond > 0
        {
            let speed = ByteCountFormatter.string(fromByteCount: Int64(bytesPerSecond), countStyle: .file)
            self.transferLabel.stringValue = String(format: NSLocalizedString("%@ of %@ at %@/s", comment: ""), completed, total, speed)
        }
        else
        {
            self.transferLabel.stringValue = String(format: NSLocalizedString("%@ of %@", comment: ""), completed, total)
        }
    }

    func updateCurrentSourceLabel(_ title: String?)
    {
        guard let title, !title.isEmpty else
        {
            self.currentSourceLabel.stringValue = ""
            return
        }
        self.currentSourceLabel.stringValue = String(format: NSLocalizedString("Current source: %@", comment: ""), title)
    }

    func setDownloadControlsVisible(_ isVisible: Bool)
    {
        self.downloadInformationStack.isHidden = !isVisible
        self.sourceStack.isHidden = !isVisible
    }

    func updateDownloadSources(_ sources: [ALTInstallationDownloadSource], selectedIdentifier: String)
    {
        self.sourcePicker.removeAllItems()
        for source in sources
        {
            let item = NSMenuItem(title: source.title, action: nil, keyEquivalent: "")
            item.representedObject = source.identifier
            self.sourcePicker.menu?.addItem(item)
        }

        if let item = self.sourcePicker.itemArray.first(where: { ($0.representedObject as? String) == selectedIdentifier })
        {
            self.sourcePicker.select(item)
        }
        self.sourcePicker.isEnabled = sources.count > 1
    }

    @objc func selectDownloadSource(_ sender: NSPopUpButton)
    {
        guard let identifier = sender.selectedItem?.representedObject as? String else { return }
        self.downloadControl.select(identifier)
    }
}
