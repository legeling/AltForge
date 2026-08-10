//
//  AppleIDVerificationWindowController.swift
//  AltServer
//
//  Copyright © 2026 AltForge contributors.
//

import AppKit

final class AppleIDVerificationWindowController: NSWindowController
{
    private static let verificationCodeLength = 6

    private let codeTextField = NSTextField()
    private let continueButton = NSButton(title: NSLocalizedString("Continue", comment: ""), target: nil, action: nil)
    private var verificationCode: String?

    init()
    {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 292),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("Apple ID Verification", comment: "")
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

    func runModal() -> String?
    {
        guard let window = self.window else { return nil }

        self.verificationCode = nil
        self.codeTextField.stringValue = ""
        self.updateValidation()

        window.center()
        window.makeKeyAndOrderFront(nil)
        window.initialFirstResponder = self.codeTextField
        window.makeFirstResponder(self.codeTextField)

        if #available(macOS 14.0, *)
        {
            NSRunningApplication.current.activate()
        }
        else
        {
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        }

        let response = NSApplication.shared.runModal(for: window)
        window.orderOut(nil)
        return response == .OK ? self.verificationCode : nil
    }
}

private extension AppleIDVerificationWindowController
{
    func configureContent()
    {
        guard let window = self.window else { return }

        let contentView = NSView()
        window.contentView = contentView
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let iconView = NSImageView(image: NSApplication.shared.applicationIconImage)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Two-Factor Authentication", comment: ""))
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let subtitleLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("Please enter the 6-digit verification code that was sent to your Apple devices.", comment: ""))
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2

        let headerText = NSStackView(views: [titleLabel, subtitleLabel])
        headerText.orientation = .vertical
        headerText.alignment = .leading
        headerText.spacing = 5

        let header = NSStackView(views: [iconView, headerText])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 16

        let divider = NSBox()
        divider.boxType = .separator

        let codeLabel = NSTextField(labelWithString: NSLocalizedString("Verification Code", comment: ""))
        codeLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        self.codeTextField.delegate = self
        self.codeTextField.alignment = .center
        self.codeTextField.font = .monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        self.codeTextField.placeholderString = NSLocalizedString("123456", comment: "")
        self.codeTextField.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = NSButton(title: NSLocalizedString("Cancel", comment: ""), target: self, action: #selector(self.cancel(_:)))
        cancelButton.keyEquivalent = "\u{1b}"

        self.continueButton.target = self
        self.continueButton.action = #selector(self.continueVerification(_:))
        self.continueButton.keyEquivalent = "\r"
        self.continueButton.isEnabled = false

        let buttonSpacer = NSView()
        let buttonRow = NSStackView(views: [buttonSpacer, cancelButton, self.continueButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8

        let stackView = NSStackView(views: [header, divider, codeLabel, self.codeTextField, buttonRow])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(18, after: header)
        stackView.setCustomSpacing(18, after: divider)
        stackView.setCustomSpacing(18, after: self.codeTextField)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -22),
            header.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            divider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.codeTextField.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.codeTextField.heightAnchor.constraint(equalToConstant: 38),
            buttonRow.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 88),
            self.continueButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 88)
        ])

        self.codeTextField.nextKeyView = self.continueButton
        window.defaultButtonCell = self.continueButton.cell as? NSButtonCell
    }

    func updateValidation()
    {
        self.continueButton.isEnabled = self.codeTextField.stringValue.count == Self.verificationCodeLength
    }

    @objc func continueVerification(_ sender: NSButton)
    {
        let code = self.codeTextField.stringValue
        guard code.count == Self.verificationCodeLength else { return }

        self.verificationCode = code
        NSApplication.shared.stopModal(withCode: .OK)
    }

    @objc func cancel(_ sender: NSButton)
    {
        NSApplication.shared.stopModal(withCode: .cancel)
    }
}

extension AppleIDVerificationWindowController: NSWindowDelegate
{
    func windowShouldClose(_ sender: NSWindow) -> Bool
    {
        NSApplication.shared.abortModal()
        return true
    }
}

extension AppleIDVerificationWindowController: NSTextFieldDelegate
{
    func controlTextDidChange(_ obj: Notification)
    {
        let digits = self.codeTextField.stringValue.filter { "0123456789".contains($0) }
        let code = String(digits.prefix(Self.verificationCodeLength))

        if self.codeTextField.stringValue != code
        {
            self.codeTextField.stringValue = code
            self.codeTextField.currentEditor()?.selectedRange = NSRange(location: code.utf16.count, length: 0)
        }

        self.updateValidation()
    }
}
