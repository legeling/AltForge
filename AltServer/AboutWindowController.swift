//
//  AboutWindowController.swift
//  AltServer
//
//  Copyright © 2026 AltForge contributors.
//

import AppKit

private final class AboutLinkButton: NSButton
{
    private let destinationURL: URL

    init(title: String, systemImageName: String, destinationURL: URL)
    {
        self.destinationURL = destinationURL
        super.init(frame: .zero)

        self.title = title
        self.image = NSImage(systemSymbolName: systemImageName, accessibilityDescription: title)
        self.imagePosition = .imageLeading
        self.bezelStyle = .inline
        self.isBordered = false
        self.contentTintColor = .linkColor
        self.target = self
        self.action = #selector(self.openDestination)
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects()
    {
        super.resetCursorRects()
        self.addCursorRect(self.bounds, cursor: .pointingHand)
    }

    @objc private func openDestination()
    {
        NSWorkspace.shared.open(self.destinationURL)
    }
}

private final class AboutRepositoryLinkField: NSTextField
{
    override func resetCursorRects()
    {
        super.resetCursorRects()
        self.addCursorRect(self.bounds, cursor: .pointingHand)
    }
}

final class AboutWindowController: NSWindowController
{
    private static let repositoryURL = URL(string: "https://github.com/legeling/AltForge")!
    private static let releasesURL = repositoryURL.appendingPathComponent("releases")
    private static let documentationURL = repositoryURL.appendingPathComponent("tree/marketplace/docs")
    private static let issuesURL = repositoryURL.appendingPathComponent("issues")

    init()
    {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("About AltForge Server", comment: "")
        window.isReleasedWhenClosed = false
        window.animationBehavior = .alertPanel
        window.center()

        super.init(window: window)
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
}

private extension AboutWindowController
{
    func configureContent()
    {
        guard let window = self.window else { return }

        let contentView = NSView()
        window.contentView = contentView

        let iconView = NSImageView(image: NSApplication.shared.applicationIconImage)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = NSTextField(labelWithString: NSLocalizedString("AltForge Server", comment: ""))
        nameLabel.font = .systemFont(ofSize: 26, weight: .bold)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
        let versionLabel = NSTextField(labelWithString: String(format: NSLocalizedString("Version %@ (%@)", comment: ""), version, build))
        versionLabel.textColor = .secondaryLabelColor

        let identityStack = NSStackView(views: [nameLabel, versionLabel])
        identityStack.orientation = .vertical
        identityStack.alignment = .leading
        identityStack.spacing = 5

        let headerStack = NSStackView(views: [iconView, identityStack])
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 18

        let summaryLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("AltForge Server is the macOS companion for AltForge. It downloads, signs, and installs AltForge and other IPA files on your Apple devices.", comment: ""))
        summaryLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        summaryLabel.alignment = .center
        summaryLabel.maximumNumberOfLines = 3

        let repositoryTitleLabel = NSTextField(labelWithString: NSLocalizedString("GitHub Repository", comment: ""))
        repositoryTitleLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
        repositoryTitleLabel.textColor = .secondaryLabelColor
        repositoryTitleLabel.alignment = .center

        let repositoryAttributes: [NSAttributedString.Key: Any] = [
            .link: Self.repositoryURL,
            .foregroundColor: NSColor.linkColor,
            .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        ]
        let repositoryLabel = AboutRepositoryLinkField(frame: .zero)
        repositoryLabel.attributedStringValue = NSAttributedString(string: Self.repositoryURL.absoluteString, attributes: repositoryAttributes)
        repositoryLabel.isEditable = false
        repositoryLabel.isBordered = false
        repositoryLabel.drawsBackground = false
        repositoryLabel.isSelectable = true
        repositoryLabel.allowsEditingTextAttributes = true

        let repositoryStack = NSStackView(views: [repositoryTitleLabel, repositoryLabel])
        repositoryStack.orientation = .vertical
        repositoryStack.alignment = .centerX
        repositoryStack.spacing = 4

        let releasesButton = AboutLinkButton(title: NSLocalizedString("Releases", comment: ""), systemImageName: "shippingbox", destinationURL: Self.releasesURL)
        let documentationButton = AboutLinkButton(title: NSLocalizedString("Documentation", comment: ""), systemImageName: "book.closed", destinationURL: Self.documentationURL)
        let issuesButton = AboutLinkButton(title: NSLocalizedString("Report an Issue", comment: ""), systemImageName: "exclamationmark.bubble", destinationURL: Self.issuesURL)
        let linksStack = NSStackView(views: [releasesButton, documentationButton, issuesButton])
        linksStack.orientation = .horizontal
        linksStack.alignment = .centerY
        linksStack.spacing = 22

        let divider = NSBox()
        divider.boxType = .separator

        let creditsLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("AltForge Server is maintained by the AltForge contributors and builds on the AltStore and pymobiledevice3 communities. AltForge is distributed under the GNU AGPL v3.0 license.", comment: ""))
        creditsLabel.textColor = .secondaryLabelColor
        creditsLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        creditsLabel.alignment = .center
        creditsLabel.maximumNumberOfLines = 3

        let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? ""
        let copyrightLabel = NSTextField(wrappingLabelWithString: copyright)
        copyrightLabel.textColor = .tertiaryLabelColor
        copyrightLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        copyrightLabel.alignment = .center
        copyrightLabel.maximumNumberOfLines = 2

        let contentStack = NSStackView(views: [headerStack, summaryLabel, repositoryStack, linksStack, divider, creditsLabel, copyrightLabel])
        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 88),
            iconView.heightAnchor.constraint(equalToConstant: 88),
            summaryLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            divider.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            creditsLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            copyrightLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
        ])
    }
}
