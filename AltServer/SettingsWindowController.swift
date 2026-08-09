//
//  SettingsWindowController.swift
//  AltServer
//
//  Copyright © 2026 AltForge contributors.
//

import AppKit
import LaunchAtLogin

final class SettingsWindowController: NSWindowController
{
    private enum Language: String, CaseIterable
    {
        case system
        case english
        case simplifiedChinese

        var localeIdentifier: String?
        {
            switch self
            {
            case .system: return nil
            case .english: return "en"
            case .simplifiedChinese: return "zh-Hans"
            }
        }

        var title: String
        {
            switch self
            {
            case .system: return NSLocalizedString("System Default", comment: "")
            case .english: return NSLocalizedString("English", comment: "")
            case .simplifiedChinese: return NSLocalizedString("Simplified Chinese", comment: "")
            }
        }
    }

    private static let languagePreferenceKey = "AltForgePreferredLanguage"

    private let languagePopUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
    private let launchAtLoginButton = NSButton(checkboxWithTitle: NSLocalizedString("Launch at Login", comment: ""), target: nil, action: nil)
    private let restartLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("Language changes take effect after you quit and reopen AltForge Server.", comment: ""))
    private let quitButton = NSButton(title: NSLocalizedString("Quit to Apply", comment: ""), target: nil, action: nil)
    private var initialLanguage = Language.system

    init()
    {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 230),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("AltForge Server Settings", comment: "")
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        self.initialLanguage = self.preferredLanguage
        self.configureContent()
        self.refresh()
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    func present()
    {
        self.refresh()
        self.showWindow(nil)
        self.window?.makeKeyAndOrderFront(nil)
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
    }
}

private extension SettingsWindowController
{
    private var preferredLanguage: Language
    {
        guard let value = UserDefaults.standard.string(forKey: Self.languagePreferenceKey) else { return .system }
        return Language(rawValue: value) ?? .system
    }

    func configureContent()
    {
        let contentView = NSView()
        self.window?.contentView = contentView

        let headingLabel = NSTextField(labelWithString: NSLocalizedString("General", comment: ""))
        headingLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let languageLabel = NSTextField(labelWithString: NSLocalizedString("Language", comment: ""))
        languageLabel.alignment = .right
        languageLabel.setContentHuggingPriority(.required, for: .horizontal)

        self.languagePopUpButton.addItems(withTitles: Language.allCases.map(\.title))
        self.languagePopUpButton.target = self
        self.languagePopUpButton.action = #selector(self.changeLanguage(_:))

        let languageRow = NSStackView(views: [languageLabel, self.languagePopUpButton])
        languageRow.orientation = .horizontal
        languageRow.alignment = .centerY
        languageRow.spacing = 12

        self.launchAtLoginButton.target = self
        self.launchAtLoginButton.action = #selector(self.toggleLaunchAtLogin(_:))

        self.restartLabel.textColor = .secondaryLabelColor
        self.restartLabel.maximumNumberOfLines = 2

        self.quitButton.target = self
        self.quitButton.action = #selector(self.quitToApply(_:))
        self.quitButton.bezelStyle = .rounded

        let buttonRow = NSStackView(views: [NSView(), self.quitButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY

        let stackView = NSStackView(views: [headingLabel, languageRow, self.launchAtLoginButton, self.restartLabel, buttonRow])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            languageLabel.widthAnchor.constraint(equalToConstant: 80),
            self.languagePopUpButton.widthAnchor.constraint(equalToConstant: 220),
            self.restartLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    func refresh()
    {
        let language = self.preferredLanguage
        self.languagePopUpButton.selectItem(at: Language.allCases.firstIndex(of: language) ?? 0)
        self.launchAtLoginButton.state = LaunchAtLogin.isEnabled ? .on : .off
        self.restartLabel.isHidden = true
        self.quitButton.isHidden = true
    }

    @objc func changeLanguage(_ sender: NSPopUpButton)
    {
        let language = Language.allCases[sender.indexOfSelectedItem]
        if let identifier = language.localeIdentifier
        {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languagePreferenceKey)
            UserDefaults.standard.set([identifier], forKey: "AppleLanguages")
        }
        else
        {
            UserDefaults.standard.removeObject(forKey: Self.languagePreferenceKey)
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }

        let requiresRestart = language != self.initialLanguage
        self.restartLabel.isHidden = !requiresRestart
        self.quitButton.isHidden = !requiresRestart
    }

    @objc func toggleLaunchAtLogin(_ sender: NSButton)
    {
        LaunchAtLogin.isEnabled = sender.state == .on
    }

    @objc func quitToApply(_ sender: NSButton)
    {
        NSApplication.shared.terminate(sender)
    }
}
