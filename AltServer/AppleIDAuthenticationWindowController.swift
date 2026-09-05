//
//  AppleIDAuthenticationWindowController.swift
//  AltServer
//
//  Copyright © 2026 AltForge contributors.
//

import AppKit

final class AppleIDAuthenticationWindowController: NSWindowController
{
    struct Submission
    {
        let account: String
        let password: String
        let rememberPassword: Bool
    }

    private static let maximumAccountLength = 320
    private static let maximumPasswordLength = 1024

    private let credentialStore: AppleIDCredentialStoring
    private let accountTextField = NSTextField()
    private let accountFieldContainer = NSView()
    private let accountPickerButton = NSButton()
    private let accountPickerPopover = NSPopover()
    private let securePasswordTextField = NSSecureTextField()
    private let visiblePasswordTextField = NSTextField()
    private let passwordVisibilityButton = NSButton()
    private let forgetAccountButton = NSButton()
    private let rememberPasswordButton = NSButton(checkboxWithTitle: NSLocalizedString("Remember password", comment: ""), target: nil, action: nil)
    private let capsLockWarningLabel = NSTextField(labelWithString: NSLocalizedString("Caps Lock is on.", comment: ""))
    private let storageWarningLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("Saved accounts are unavailable. You can still sign in.", comment: ""))
    private let authenticationErrorLabel = NSTextField(wrappingLabelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    private let cancelButton = NSButton(title: NSLocalizedString("Cancel", comment: ""), target: nil, action: nil)
    private let continueButton = NSButton(title: NSLocalizedString("Continue", comment: ""), target: nil, action: nil)
    private var savedAccounts = [AppleIDSavedAccount]()
    private var savedCredentials = [AppleIDSavedCredential]()
    private var loadedAccount: String?
    private var capsLockMonitor: Any?
    private var submissionHandler: ((Submission) -> Void)?
    private var isAuthenticating = false
    private var isPasswordVisible = false
    private weak var contentStackView: NSStackView?

    init(credentialStore: AppleIDCredentialStoring)
    {
        self.credentialStore = credentialStore

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("Apple ID Account", comment: "")
        window.isReleasedWhenClosed = false
        window.animationBehavior = .alertPanel
        window.center()

        super.init(window: window)
        window.delegate = self
        self.configureContent()
        self.loadSavedAccounts()
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    func runModal(submissionHandler: @escaping (Submission) -> Void)
    {
        guard let window = self.window else { return }

        self.submissionHandler = submissionHandler
        self.authenticationErrorLabel.isHidden = true
        self.setAuthenticating(false)
        self.updateCapsLockWarning(with: NSEvent.modifierFlags)
        self.startMonitoringCapsLock()
        defer {
            self.stopMonitoringCapsLock()
            self.submissionHandler = nil
            self.savedCredentials.removeAll(keepingCapacity: false)
            self.savedAccounts.removeAll(keepingCapacity: false)
            self.accountTextField.stringValue = ""
            self.setPassword("")
        }

        window.center()
        window.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *)
        {
            NSRunningApplication.current.activate()
        }
        else
        {
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        }

        if self.accountTextField.stringValue.isEmpty
        {
            window.initialFirstResponder = self.accountTextField
            window.makeFirstResponder(self.accountTextField)
        }
        else
        {
            window.initialFirstResponder = self.securePasswordTextField
            window.makeFirstResponder(self.securePasswordTextField)
        }

        NSApplication.shared.runModal(for: window)
        window.orderOut(nil)
    }

    func authenticationDidSucceed()
    {
        guard self.isAuthenticating else { return }
        NSApplication.shared.stopModal(withCode: .OK)
    }

    func authenticationDidFail(message: String?)
    {
        guard self.isAuthenticating else { return }

        self.authenticationErrorLabel.stringValue = message ?? ""
        self.authenticationErrorLabel.isHidden = message == nil
        self.setAuthenticating(false)
        self.resizeWindowToFitContent()
        self.window?.makeFirstResponder(self.isPasswordVisible ? self.visiblePasswordTextField : self.securePasswordTextField)
    }
}

private extension AppleIDAuthenticationWindowController
{
    var password: String
    {
        self.isPasswordVisible ? self.visiblePasswordTextField.stringValue : self.securePasswordTextField.stringValue
    }

    func configureContent()
    {
        guard let window = self.window else { return }

        let contentView = NSView()
        window.contentView = contentView
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let iconView = NSImageView(image: NSApplication.shared.applicationIconImage)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Sign in with Apple ID", comment: ""))
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let subtitleLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("AltForge Server uses your Apple ID to sign and install apps through Apple Developer services.", comment: ""))
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

        let accountLabel = NSTextField(labelWithString: NSLocalizedString("Account", comment: ""))
        accountLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        self.accountTextField.delegate = self
        self.accountTextField.placeholderString = NSLocalizedString("Apple ID", comment: "")
        self.accountTextField.translatesAutoresizingMaskIntoConstraints = false

        self.accountFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        self.accountFieldContainer.addSubview(self.accountTextField)

        self.accountPickerButton.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: NSLocalizedString("Choose Saved Account", comment: ""))
        self.accountPickerButton.toolTip = NSLocalizedString("Choose Saved Account", comment: "")
        self.accountPickerButton.bezelStyle = .inline
        self.accountPickerButton.isBordered = false
        self.accountPickerButton.contentTintColor = .secondaryLabelColor
        self.accountPickerButton.translatesAutoresizingMaskIntoConstraints = false
        self.accountPickerButton.target = self
        self.accountPickerButton.action = #selector(self.showSavedAccounts(_:))
        self.accountPickerButton.isEnabled = false
        self.accountFieldContainer.addSubview(self.accountPickerButton)

        self.forgetAccountButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: NSLocalizedString("Forget Account", comment: ""))
        self.forgetAccountButton.toolTip = NSLocalizedString("Forget Account", comment: "")
        self.forgetAccountButton.bezelStyle = .inline
        self.forgetAccountButton.isBordered = false
        self.forgetAccountButton.target = self
        self.forgetAccountButton.action = #selector(self.forgetSelectedAccount(_:))
        self.forgetAccountButton.isEnabled = false

        let accountRow = NSStackView(views: [self.accountFieldContainer, self.forgetAccountButton])
        accountRow.orientation = .horizontal
        accountRow.alignment = .centerY
        accountRow.spacing = 8

        let passwordLabel = NSTextField(labelWithString: NSLocalizedString("Password", comment: ""))
        passwordLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        self.configurePasswordTextField(self.securePasswordTextField)
        self.configurePasswordTextField(self.visiblePasswordTextField)
        self.visiblePasswordTextField.isHidden = true

        let passwordFieldContainer = NSView()
        passwordFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        passwordFieldContainer.addSubview(self.securePasswordTextField)
        passwordFieldContainer.addSubview(self.visiblePasswordTextField)

        self.passwordVisibilityButton.bezelStyle = .inline
        self.passwordVisibilityButton.isBordered = false
        self.passwordVisibilityButton.contentTintColor = .secondaryLabelColor
        self.passwordVisibilityButton.target = self
        self.passwordVisibilityButton.action = #selector(self.togglePasswordVisibility(_:))
        self.updatePasswordVisibilityButton()

        let passwordRow = NSStackView(views: [passwordFieldContainer, self.passwordVisibilityButton])
        passwordRow.orientation = .horizontal
        passwordRow.alignment = .centerY
        passwordRow.spacing = 8

        self.capsLockWarningLabel.textColor = .systemOrange
        self.capsLockWarningLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        self.capsLockWarningLabel.isHidden = true

        self.rememberPasswordButton.state = .off

        let keychainLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("Saved passwords stay in Keychain. macOS may ask for your Mac login password to read them, not your Apple ID password.", comment: ""))
        keychainLabel.textColor = .secondaryLabelColor
        keychainLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        keychainLabel.maximumNumberOfLines = 3

        self.storageWarningLabel.textColor = .systemRed
        self.storageWarningLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        self.storageWarningLabel.maximumNumberOfLines = 2
        self.storageWarningLabel.isHidden = true

        self.authenticationErrorLabel.textColor = .systemRed
        self.authenticationErrorLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        self.authenticationErrorLabel.maximumNumberOfLines = 0
        self.authenticationErrorLabel.isSelectable = true
        self.authenticationErrorLabel.isHidden = true

        self.progressIndicator.style = .spinning
        self.progressIndicator.controlSize = .small
        self.progressIndicator.isIndeterminate = true
        self.progressIndicator.isDisplayedWhenStopped = false
        self.progressIndicator.isHidden = true

        self.cancelButton.target = self
        self.cancelButton.action = #selector(self.cancel(_:))
        self.cancelButton.keyEquivalent = "\u{1b}"

        self.continueButton.target = self
        self.continueButton.action = #selector(self.continueAuthentication(_:))
        self.continueButton.keyEquivalent = "\r"
        self.continueButton.isEnabled = false

        let buttonSpacer = NSView()
        let buttonRow = NSStackView(views: [self.progressIndicator, buttonSpacer, self.cancelButton, self.continueButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8

        let stackView = NSStackView(views: [
            header,
            divider,
            accountLabel,
            accountRow,
            passwordLabel,
            passwordRow,
            self.capsLockWarningLabel,
            self.rememberPasswordButton,
            keychainLabel,
            self.storageWarningLabel,
            self.authenticationErrorLabel,
            buttonRow
        ])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(18, after: header)
        stackView.setCustomSpacing(18, after: divider)
        stackView.setCustomSpacing(14, after: accountRow)
        stackView.setCustomSpacing(14, after: keychainLabel)
        self.contentStackView = stackView
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -22),
            header.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            divider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            accountRow.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.accountFieldContainer.heightAnchor.constraint(equalToConstant: 28),
            self.accountTextField.leadingAnchor.constraint(equalTo: self.accountFieldContainer.leadingAnchor),
            self.accountTextField.trailingAnchor.constraint(equalTo: self.accountFieldContainer.trailingAnchor),
            self.accountTextField.topAnchor.constraint(equalTo: self.accountFieldContainer.topAnchor),
            self.accountTextField.bottomAnchor.constraint(equalTo: self.accountFieldContainer.bottomAnchor),
            self.accountPickerButton.trailingAnchor.constraint(equalTo: self.accountFieldContainer.trailingAnchor, constant: -4),
            self.accountPickerButton.centerYAnchor.constraint(equalTo: self.accountFieldContainer.centerYAnchor),
            self.accountPickerButton.widthAnchor.constraint(equalToConstant: 24),
            self.accountPickerButton.heightAnchor.constraint(equalToConstant: 24),
            self.forgetAccountButton.widthAnchor.constraint(equalToConstant: 28),
            self.forgetAccountButton.heightAnchor.constraint(equalToConstant: 28),
            passwordRow.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            passwordFieldContainer.heightAnchor.constraint(equalToConstant: 28),
            self.passwordVisibilityButton.widthAnchor.constraint(equalToConstant: 28),
            self.passwordVisibilityButton.heightAnchor.constraint(equalToConstant: 28),
            self.securePasswordTextField.leadingAnchor.constraint(equalTo: passwordFieldContainer.leadingAnchor),
            self.securePasswordTextField.trailingAnchor.constraint(equalTo: passwordFieldContainer.trailingAnchor),
            self.securePasswordTextField.topAnchor.constraint(equalTo: passwordFieldContainer.topAnchor),
            self.securePasswordTextField.bottomAnchor.constraint(equalTo: passwordFieldContainer.bottomAnchor),
            self.visiblePasswordTextField.leadingAnchor.constraint(equalTo: passwordFieldContainer.leadingAnchor),
            self.visiblePasswordTextField.trailingAnchor.constraint(equalTo: passwordFieldContainer.trailingAnchor),
            self.visiblePasswordTextField.topAnchor.constraint(equalTo: passwordFieldContainer.topAnchor),
            self.visiblePasswordTextField.bottomAnchor.constraint(equalTo: passwordFieldContainer.bottomAnchor),
            keychainLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.storageWarningLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.authenticationErrorLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            self.progressIndicator.widthAnchor.constraint(equalToConstant: 16),
            self.progressIndicator.heightAnchor.constraint(equalToConstant: 16),
            self.cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 88),
            self.continueButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 88)
        ])

        self.accountTextField.nextKeyView = self.securePasswordTextField
        self.securePasswordTextField.nextKeyView = self.rememberPasswordButton
        self.visiblePasswordTextField.nextKeyView = self.rememberPasswordButton
        self.rememberPasswordButton.nextKeyView = self.continueButton
        window.defaultButtonCell = self.continueButton.cell as? NSButtonCell
        contentView.layoutSubtreeIfNeeded()
        self.resizeWindowToFitContent()
    }

    func configurePasswordTextField(_ textField: NSTextField)
    {
        textField.delegate = self
        textField.placeholderString = NSLocalizedString("Password", comment: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
    }

    func loadSavedAccounts()
    {
        do
        {
            self.savedCredentials = try self.credentialStore.credentialSnapshot()
            self.savedAccounts = self.savedCredentials.map(\.account)
            self.accountPickerButton.isEnabled = !self.savedAccounts.isEmpty
            self.storageWarningLabel.isHidden = true

            if let account = self.savedAccounts.first
            {
                self.selectSavedAccount(account)
            }
        }
        catch
        {
            self.savedCredentials = []
            self.savedAccounts = []
            self.loadedAccount = nil
            self.accountPickerButton.isEnabled = false
            self.storageWarningLabel.isHidden = false
        }

        self.updateValidation()
        self.resizeWindowToFitContent()
    }

    func selectSavedAccount(_ account: AppleIDSavedAccount)
    {
        self.loadedAccount = account.identifier
        self.accountTextField.stringValue = account.identifier

        let password = self.savedCredentials.first(where: {
            $0.account.identifier.compare(account.identifier, options: .caseInsensitive) == .orderedSame
        })?.password ?? ""
        self.setPassword(password)
        self.rememberPasswordButton.state = password.isEmpty ? .off : .on
        self.storageWarningLabel.isHidden = true

        self.forgetAccountButton.isEnabled = true
        self.updateValidation()
        self.resizeWindowToFitContent()
    }

    func setPassword(_ password: String)
    {
        self.securePasswordTextField.stringValue = password
        self.visiblePasswordTextField.stringValue = password
    }

    func updateValidation()
    {
        let account = self.accountTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = self.password
        self.continueButton.isEnabled = !self.isAuthenticating && !account.isEmpty && account.count <= Self.maximumAccountLength && !password.isEmpty && password.count <= Self.maximumPasswordLength
        self.forgetAccountButton.isEnabled = !self.isAuthenticating && self.savedAccounts.contains(where: { $0.identifier.compare(account, options: .caseInsensitive) == .orderedSame })
        self.accountPickerButton.isEnabled = !self.isAuthenticating && !self.savedAccounts.isEmpty
    }

    func updateCapsLockWarning(with modifierFlags: NSEvent.ModifierFlags)
    {
        let isHidden = !modifierFlags.contains(.capsLock)
        guard self.capsLockWarningLabel.isHidden != isHidden else { return }

        self.capsLockWarningLabel.isHidden = isHidden
        self.resizeWindowToFitContent()
    }

    func startMonitoringCapsLock()
    {
        guard self.capsLockMonitor == nil else { return }
        self.capsLockMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.updateCapsLockWarning(with: event.modifierFlags)
            return event
        }
    }

    func stopMonitoringCapsLock()
    {
        guard let monitor = self.capsLockMonitor else { return }
        NSEvent.removeMonitor(monitor)
        self.capsLockMonitor = nil
    }

    func updatePasswordVisibilityButton()
    {
        let title = self.isPasswordVisible ? NSLocalizedString("Hide Password", comment: "") : NSLocalizedString("Show Password", comment: "")
        let symbolName = self.isPasswordVisible ? "eye.slash.fill" : "eye.fill"
        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        self.passwordVisibilityButton.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)?.withSymbolConfiguration(configuration)
        self.passwordVisibilityButton.toolTip = title
    }

    func setAuthenticating(_ isAuthenticating: Bool)
    {
        self.isAuthenticating = isAuthenticating
        self.accountTextField.isEnabled = !isAuthenticating
        self.securePasswordTextField.isEnabled = !isAuthenticating
        self.visiblePasswordTextField.isEnabled = !isAuthenticating
        self.passwordVisibilityButton.isEnabled = !isAuthenticating
        self.rememberPasswordButton.isEnabled = !isAuthenticating
        self.cancelButton.isEnabled = !isAuthenticating
        self.window?.standardWindowButton(.closeButton)?.isEnabled = !isAuthenticating
        self.continueButton.title = isAuthenticating ? NSLocalizedString("Signing In…", comment: "") : NSLocalizedString("Continue", comment: "")

        if isAuthenticating
        {
            self.progressIndicator.isHidden = false
            self.progressIndicator.startAnimation(nil)
        }
        else
        {
            self.progressIndicator.stopAnimation(nil)
            self.progressIndicator.isHidden = true
        }

        self.updateValidation()
    }

    func resizeWindowToFitContent()
    {
        guard let window = self.window,
              let contentView = window.contentView,
              let contentStackView = self.contentStackView,
              let bottomView = contentStackView.arrangedSubviews.last
        else { return }

        contentView.layoutSubtreeIfNeeded()

        // NSStackView's fitting size can include space reserved by hidden warning rows.
        // Measure the visible bottom row instead so the window keeps a compact footer.
        let currentHeight = window.contentLayoutRect.height
        let bottomEdge = bottomView.convert(bottomView.bounds, to: contentView).minY
        let height = max(300, ceil(currentHeight - bottomEdge + 22))
        guard abs(window.contentLayoutRect.height - height) > 0.5 else { return }
        window.setContentSize(NSSize(width: 480, height: height))
    }

    @objc func showSavedAccounts(_ sender: NSButton)
    {
        guard !self.savedAccounts.isEmpty else { return }

        if self.accountPickerPopover.isShown
        {
            self.accountPickerPopover.close()
            return
        }

        let contentViewController = NSViewController()
        let contentView = NSView()
        contentViewController.view = contentView

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Saved Accounts", comment: ""))
        titleLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
        titleLabel.textColor = .secondaryLabelColor

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(8, after: titleLabel)

        let selectedAccount = self.accountTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        for (index, account) in self.savedAccounts.enumerated()
        {
            let button = NSButton(title: "", target: self, action: #selector(self.selectAccountFromPicker(_:)))
            let isSelected = account.identifier.compare(selectedAccount, options: .caseInsensitive) == .orderedSame
            let symbolName = isSelected ? "checkmark.circle.fill" : "person.crop.circle"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            button.imagePosition = .imageLeading
            button.alignment = .left
            button.bezelStyle = .inline
            button.isBordered = false
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false

            let accountLabel = NSTextField(labelWithString: account.identifier)
            accountLabel.lineBreakMode = .byTruncatingMiddle
            accountLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            let rowViews: [NSView]
            if let localizedKind = account.kind.localizedName
            {
                let kindLabel = NSTextField(labelWithString: localizedKind)
                kindLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
                kindLabel.textColor = .controlAccentColor
                kindLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                rowViews = [accountLabel, kindLabel]
            }
            else
            {
                rowViews = [accountLabel]
            }

            let rowContent = NSStackView(views: rowViews)
            rowContent.orientation = .horizontal
            rowContent.alignment = .centerY
            rowContent.spacing = 10
            rowContent.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(rowContent)
            NSLayoutConstraint.activate([
                rowContent.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 28),
                rowContent.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8),
                rowContent.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])

            stackView.addArrangedSubview(button)
            button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        }

        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        let width = max(340, self.accountFieldContainer.bounds.width)
        let height = 44 + (self.savedAccounts.count * 38)
        contentViewController.preferredContentSize = NSSize(width: width, height: CGFloat(height))
        self.accountPickerPopover.contentViewController = contentViewController
        self.accountPickerPopover.behavior = .transient
        self.accountPickerPopover.animates = true
        self.accountPickerPopover.show(relativeTo: self.accountFieldContainer.bounds, of: self.accountFieldContainer, preferredEdge: .maxY)
    }

    @objc func selectAccountFromPicker(_ sender: NSButton)
    {
        guard self.savedAccounts.indices.contains(sender.tag) else { return }
        self.accountPickerPopover.close()
        self.selectSavedAccount(self.savedAccounts[sender.tag])
        self.window?.makeFirstResponder(self.securePasswordTextField)
    }

    @objc func togglePasswordVisibility(_ sender: NSButton)
    {
        let password = self.password
        self.isPasswordVisible.toggle()
        self.setPassword(password)
        self.securePasswordTextField.isHidden = self.isPasswordVisible
        self.visiblePasswordTextField.isHidden = !self.isPasswordVisible
        self.updatePasswordVisibilityButton()
        self.window?.makeFirstResponder(self.isPasswordVisible ? self.visiblePasswordTextField : self.securePasswordTextField)
    }

    @objc func forgetSelectedAccount(_ sender: NSButton)
    {
        let account = self.accountTextField.stringValue
        guard let savedAccount = self.savedAccounts.first(where: { $0.identifier.compare(account, options: .caseInsensitive) == .orderedSame }) else { return }

        do
        {
            try self.credentialStore.removeAccount(savedAccount.identifier)
            self.loadSavedAccounts()

            if self.savedAccounts.isEmpty
            {
                self.loadedAccount = nil
                self.accountTextField.stringValue = ""
                self.setPassword("")
                self.rememberPasswordButton.state = .off
                self.window?.makeFirstResponder(self.accountTextField)
            }
        }
        catch
        {
            self.storageWarningLabel.isHidden = false
            self.resizeWindowToFitContent()
        }

        self.updateValidation()
    }

    @objc func continueAuthentication(_ sender: NSButton)
    {
        let account = self.accountTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = self.password
        guard !account.isEmpty, account.count <= Self.maximumAccountLength,
              !password.isEmpty, password.count <= Self.maximumPasswordLength
        else { return }

        let submission = Submission(account: account, password: password, rememberPassword: self.rememberPasswordButton.state == .on)
        self.authenticationErrorLabel.isHidden = true
        self.setAuthenticating(true)
        self.resizeWindowToFitContent()
        self.submissionHandler?(submission)
    }

    @objc func cancel(_ sender: NSButton)
    {
        guard !self.isAuthenticating else
        {
            NSSound.beep()
            return
        }

        NSApplication.shared.stopModal(withCode: .cancel)
    }
}

extension AppleIDAuthenticationWindowController: NSWindowDelegate
{
    func windowShouldClose(_ sender: NSWindow) -> Bool
    {
        guard !self.isAuthenticating else
        {
            NSSound.beep()
            return false
        }

        NSApplication.shared.abortModal()
        return true
    }
}

extension AppleIDAuthenticationWindowController: NSTextFieldDelegate
{
    func controlTextDidChange(_ obj: Notification)
    {
        guard let control = obj.object as? NSControl else { return }

        switch control
        {
        case self.accountTextField:
            if let loadedAccount = self.loadedAccount,
               loadedAccount.compare(self.accountTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), options: .caseInsensitive) != .orderedSame
            {
                self.loadedAccount = nil
                self.setPassword("")
                self.rememberPasswordButton.state = .off
            }
        case self.securePasswordTextField:
            self.visiblePasswordTextField.stringValue = self.securePasswordTextField.stringValue
        case self.visiblePasswordTextField:
            self.securePasswordTextField.stringValue = self.visiblePasswordTextField.stringValue
        default:
            break
        }

        self.updateValidation()
    }
}
