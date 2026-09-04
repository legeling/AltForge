//
//  AppDelegate.swift
//  AltServer
//
//  Created by Riley Testut on 5/24/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Cocoa
import ServiceManagement
import UserNotifications

import AltSign

import LaunchAtLogin

extension ALTDevice: MenuDisplayable {}

private enum PreferredLanguage: String, CaseIterable
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

    var menuItemTag: Int
    {
        switch self
        {
        case .system: return 0
        case .english: return 1
        case .simplifiedChinese: return 2
        }
    }
}

private final class ActiveInstallation
{
    let authenticationController: AppleIDAuthenticationWindowController
    let progressController: InstallationProgressWindowController

    init(authenticationController: AppleIDAuthenticationWindowController, progressController: InstallationProgressWindowController)
    {
        self.authenticationController = authenticationController
        self.progressController = progressController
    }

    func focus()
    {
        if let window = self.authenticationController.window, window.isVisible
        {
            window.makeKeyAndOrderFront(nil)
        }
        else
        {
            self.progressController.show()
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let pluginManager = PluginManager()
    private let appleIDCredentialStore = AppleIDCredentialStore()
    private let aboutWindowController = AboutWindowController()
    private let serverUpdateController = ServerUpdateController()
    private var activeInstallations = [String: ActiveInstallation]()
    private static let languagePreferenceKey = "AltForgePreferredLanguage"
    
    private var statusItem: NSStatusItem?
    
    private var connectedDevices = [ALTDevice]()
    private var wiredDeviceIdentifiers = Set<String>()
    
    @IBOutlet private var appMenu: NSMenu!
    @IBOutlet private var connectedDevicesMenu: NSMenu!
    @IBOutlet private var sideloadIPAConnectedDevicesMenu: NSMenu!
    @IBOutlet private var enableJITMenu: NSMenu!
    
    @IBOutlet private var launchAtLoginMenuItem: NSMenuItem!
    @IBOutlet private var installMailPluginMenuItem: NSMenuItem!
    @IBOutlet private var installAltStoreMenuItem: NSMenuItem!
    @IBOutlet private var sideloadAppMenuItem: NSMenuItem!
    @IBOutlet private var settingsMenuItem: NSMenuItem!
    @IBOutlet private var checkForUpdatesMenuItem: NSMenuItem!
    @IBOutlet private var systemLanguageMenuItem: NSMenuItem!
    @IBOutlet private var englishLanguageMenuItem: NSMenuItem!
    @IBOutlet private var simplifiedChineseLanguageMenuItem: NSMenuItem!
    
    private var connectedDevicesMenuController: MenuController<ALTDevice>!
    private var sideloadIPAConnectedDevicesMenuController: MenuController<ALTDevice>!
    private var enableJITMenuController: MenuController<ALTDevice>!
    
    private var _jitAppListMenuControllers = [AnyObject]()
    
    private var isAltPluginUpdateAvailable = false
    
    private var popoverController: NSPopover?
    private var popoverError: NSError?
    private var errorAlert: NSAlert?
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        UserDefaults.standard.registerDefaults()
        
        UNUserNotificationCenter.current().delegate = self
        
        ServerConnectionManager.shared.start()
        ALTDeviceManager.shared.start()
        
        let item = NSStatusBar.system.statusItem(withLength: -1)
        item.menu = self.appMenu
        let menuBarImage = NSImage(named: "MenuBarIcon")
        menuBarImage?.isTemplate = true
        item.button?.image = menuBarImage
        self.statusItem = item
        
        self.appMenu.delegate = self
        
        self.sideloadAppMenuItem.keyEquivalentModifierMask = .option
        self.sideloadAppMenuItem.isAlternate = true

        let installImage = NSImage(systemSymbolName: "arrow.down.app", accessibilityDescription: self.installAltStoreMenuItem.title)
            ?? NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: self.installAltStoreMenuItem.title)
        installImage?.isTemplate = true
        self.installAltStoreMenuItem.image = installImage

        let menuIcons: [(menuItem: NSMenuItem, symbolName: String)] = [
            (self.settingsMenuItem, "gearshape"),
            (self.checkForUpdatesMenuItem, "arrow.clockwise")
        ]
        for (menuItem, symbolName) in menuIcons
        {
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: menuItem.title)
            image?.isTemplate = true
            menuItem.image = image
        }
        
        let placeholder = NSLocalizedString("No Connected Devices", comment: "")
        
        self.connectedDevicesMenuController = MenuController<ALTDevice>(menu: self.connectedDevicesMenu, items: [])
        self.connectedDevicesMenuController.placeholder = placeholder
        self.connectedDevicesMenuController.titleHandler = { [weak self] device in
            self?.menuTitle(for: device) ?? device.name
        }
        self.connectedDevicesMenuController.imageHandler = { [weak self] device in
            self?.connectionImage(for: device)
        }
        self.connectedDevicesMenuController.action = { [weak self] device in
            self?.installAltStore(to: device)
        }
        
        self.sideloadIPAConnectedDevicesMenuController = MenuController<ALTDevice>(menu: self.sideloadIPAConnectedDevicesMenu, items: [])
        self.sideloadIPAConnectedDevicesMenuController.placeholder = placeholder
        self.sideloadIPAConnectedDevicesMenuController.titleHandler = { [weak self] device in
            self?.menuTitle(for: device) ?? device.name
        }
        self.sideloadIPAConnectedDevicesMenuController.imageHandler = { [weak self] device in
            self?.connectionImage(for: device)
        }
        self.sideloadIPAConnectedDevicesMenuController.action = { [weak self] device in
            self?.sideloadIPA(to: device)
        }
        
        self.enableJITMenuController = MenuController<ALTDevice>(menu: self.enableJITMenu, items: [])
        self.enableJITMenuController.placeholder = placeholder
        self.enableJITMenuController.titleHandler = { [weak self] device in
            self?.menuTitle(for: device) ?? device.name
        }
        self.enableJITMenuController.imageHandler = { [weak self] device in
            self?.connectionImage(for: device)
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (success, error) in
            guard success else { return }
            
            if !UserDefaults.standard.didPresentInitialNotification
            {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("AltForge Server Running", comment: "")
                content.body = NSLocalizedString("AltForge Server runs in the background as a menu bar app listening for AltForge.", comment: "")
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
                
                UserDefaults.standard.didPresentInitialNotification = true
            }
        }
    }

    @IBAction func checkForUpdates(_ sender: NSMenuItem)
    {
        self.serverUpdateController.checkForUpdates(menuItem: sender)
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        self.serverUpdateController.cancel()
    }
}

private extension AppDelegate
{
    var preferredLanguage: PreferredLanguage
    {
        guard let value = UserDefaults.standard.string(forKey: Self.languagePreferenceKey) else { return .system }
        return PreferredLanguage(rawValue: value) ?? .system
    }

    func refreshPreferredLanguageMenuItems()
    {
        let selectedLanguage = self.preferredLanguage
        let menuItems = [
            (PreferredLanguage.system, self.systemLanguageMenuItem),
            (PreferredLanguage.english, self.englishLanguageMenuItem),
            (PreferredLanguage.simplifiedChinese, self.simplifiedChineseLanguageMenuItem)
        ]

        for (language, menuItem) in menuItems
        {
            menuItem?.state = language == selectedLanguage ? .on : .off
        }
    }

    func refreshLaunchAtLoginMenuItem(legacyRequestedState: Bool? = nil)
    {
        if #available(macOS 13, *)
        {
            switch SMAppService.mainApp.status
            {
            case .enabled:
                self.launchAtLoginMenuItem.state = .on
                self.launchAtLoginMenuItem.title = NSLocalizedString("Launch at Login (On)", comment: "")

            case .requiresApproval:
                self.launchAtLoginMenuItem.state = .mixed
                self.launchAtLoginMenuItem.title = NSLocalizedString("Launch at Login (Requires Approval)", comment: "")

            case .notRegistered, .notFound:
                self.launchAtLoginMenuItem.state = .off
                self.launchAtLoginMenuItem.title = NSLocalizedString("Launch at Login (Off)", comment: "")

            @unknown default:
                self.launchAtLoginMenuItem.state = .off
                self.launchAtLoginMenuItem.title = NSLocalizedString("Launch at Login (Off)", comment: "")
            }
        }
        else
        {
            let isEnabled = legacyRequestedState ?? LaunchAtLogin.isEnabled
            self.launchAtLoginMenuItem.state = isEnabled ? .on : .off
            self.launchAtLoginMenuItem.title = isEnabled
                ? NSLocalizedString("Launch at Login (On)", comment: "")
                : NSLocalizedString("Launch at Login (Off)", comment: "")
        }
    }

    @available(macOS 13, *)
    func showLaunchAtLoginApproval()
    {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Login Item Approval Required", comment: "")
        alert.informativeText = NSLocalizedString("Allow AltForge Server in System Settings > General > Login Items to finish enabling launch at login.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Open Login Items", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))

        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        if alert.runModal() == .alertFirstButtonReturn
        {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    func showLaunchAtLoginFailure(_ error: Error)
    {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = NSLocalizedString("Unable to Change Launch at Login", comment: "")
        alert.informativeText = NSLocalizedString("AltForge Server could not update its login item. Install the app in Applications and try again.", comment: "") + "\n\n" + error.userFacingPresentation.message
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))

        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        alert.runModal()
    }

    func promptToRestartForLanguageChange()
    {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Restart Required", comment: "")
        alert.informativeText = NSLocalizedString("Restart AltForge Server to apply the selected language.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Restart Now", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))

        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let relauncher = Process()
        relauncher.executableURL = URL(fileURLWithPath: "/bin/sh")
        relauncher.arguments = ["-c", "sleep 0.5; exec /usr/bin/open -n \"$ALT_FORGE_RELAUNCH_PATH\""]
        var environment = ProcessInfo.processInfo.environment
        environment["ALT_FORGE_RELAUNCH_PATH"] = Bundle.main.bundlePath
        relauncher.environment = environment

        do
        {
            try relauncher.run()
            NSApplication.shared.terminate(nil)
        }
        catch
        {
            self.showErrorAlert(error: error)
        }
    }

    func menuTitle(for device: ALTDevice) -> String
    {
        let connection = self.wiredDeviceIdentifiers.contains(device.identifier) ? NSLocalizedString("USB", comment: "") : NSLocalizedString("Wi-Fi", comment: "")
        return String(format: NSLocalizedString("%@ (%@)", comment: ""), device.name, connection)
    }

    func connectionImage(for device: ALTDevice) -> NSImage?
    {
        let isWired = self.wiredDeviceIdentifiers.contains(device.identifier)
        let description = isWired ? NSLocalizedString("USB", comment: "") : NSLocalizedString("Wi-Fi", comment: "")
        return NSImage(systemSymbolName: isWired ? "cable.connector" : "wifi", accessibilityDescription: description)
    }

    @objc func installAltStore(to device: ALTDevice)
    {
        self.installApplication(at: nil, to: device)
    }
    
    @objc func sideloadIPA(to device: ALTDevice)
    {
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["ipa"]
        openPanel.begin { (response) in
            guard let fileURL = openPanel.url, response == .OK else { return }
            self.installApplication(at: fileURL, to: device)
        }
    }
    
    func enableJIT(for app: InstalledApp, on device: ALTDevice)
    {
        Task<Void, Never> {
            do
            {
                try await JITManager.shared.enableUnsignedCodeExecution(process: .name(app.executableName), device: device)
                
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = String(format: NSLocalizedString("Successfully enabled JIT for %@.", comment: ""), app.name)
                    alert.informativeText = String(format: NSLocalizedString("JIT will remain enabled until you quit the app. You can now disconnect %@ from your computer.", comment: ""), device.name)
                    
                    NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
                    
                    alert.runModal()
                }
            }
            catch let error as JITError where error.code == .dependencyNotFound
            {
                let errorMessage = error.userFacingPresentation.combinedMessage
                
                await MainActor.run { [errorMessage] in
                    let alert = NSAlert()
                    alert.alertStyle = .critical
                    alert.messageText = NSLocalizedString("Missing AltJIT Dependencies", comment: "")
                    alert.informativeText = errorMessage
                    
                    alert.addButton(withTitle: NSLocalizedString("View Instructions", comment: ""))
                    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                    
                    NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn
                    {
                        let faqURL = URL(string: "https://github.com/legeling/AltForge/blob/marketplace/docs/guides/altjit.md")!
                        NSWorkspace.shared.open(faqURL)
                    }
                }
            }
            catch let error as NSError
            {
                await MainActor.run {
                    let localizedTitle = String(format: NSLocalizedString("JIT could not be enabled for %@.", comment: ""), app.name)
                    self.showErrorAlert(error: error.withLocalizedTitle(localizedTitle))
                }
            }
        }
    }
    
    func installApplication(at fileURL: URL?, to device: ALTDevice)
    {
        if let activeInstallation = self.activeInstallations[device.identifier]
        {
            activeInstallation.focus()
            return
        }

        let authenticationController = AppleIDAuthenticationWindowController(credentialStore: self.appleIDCredentialStore)
        let downloadControl = ALTInstallationDownloadControl()
        let progressController = InstallationProgressWindowController(deviceName: device.name, downloadControl: downloadControl)
        let activeInstallation = ActiveInstallation(authenticationController: authenticationController, progressController: progressController)
        self.activeInstallations[device.identifier] = activeInstallation
        var didAuthenticate = false

        func finishActiveInstallation()
        {
            guard self.activeInstallations[device.identifier] === activeInstallation else { return }
            self.activeInstallations[device.identifier] = nil
        }

        func notifyAccountSaveFailure()
        {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("Account Could Not Be Saved", comment: "")
            content.body = NSLocalizedString("The login succeeded, but AltForge Server could not update saved accounts in this Mac's Keychain.", comment: "")
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }

        authenticationController.runModal { [weak self, weak authenticationController] submission in
            guard let self, let authenticationController else { return }

            ALTDeviceManager.shared.installApplication(
                at: fileURL,
                to: device,
                appleID: submission.account,
                password: submission.password,
                authenticationCompletion: {
                    didAuthenticate = true

                    do
                    {
                        try self.appleIDCredentialStore.recordSuccessfulAuthentication(
                            account: submission.account,
                            password: submission.password,
                            rememberPassword: submission.rememberPassword
                        )
                    }
                    catch
                    {
                        notifyAccountSaveFailure()
                    }

                    progressController.update(ALTInstallationProgressUpdate(stage: .fetchingTeam))
                    progressController.show()
                    authenticationController.authenticationDidSucceed()
                },
                teamCompletion: { team in
                    let kind: AppleIDAccountKind
                    switch team.type
                    {
                    case .free: kind = .free
                    case .individual: kind = .individual
                    case .organization: kind = .organization
                    case .unknown: fallthrough
                    @unknown default: kind = .unknown
                    }

                    guard kind != .unknown else { return }

                    do
                    {
                        try self.appleIDCredentialStore.updateAccountKind(kind, for: submission.account)
                    }
                    catch
                    {
                        notifyAccountSaveFailure()
                    }
                },
                downloadControl: downloadControl,
                progressHandler: { update in
                    progressController.update(update)
                }
            ) { (result) in
                switch result
                {
                case .success(let application):
                    progressController.showCompletion {
                        finishActiveInstallation()
                    }

                    let content = UNMutableNotificationContent()
                    content.title = NSLocalizedString("Installation Succeeded", comment: "")
                    content.body = String(format: NSLocalizedString("%@ was successfully installed on %@.", comment: ""), application.name, device.name)

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request)

                case .failure(OperationError.cancelled), .failure(ALTAppleAPIError.requiresTwoFactorAuthentication):
                    progressController.closeProgressWindow()
                    if didAuthenticate
                    {
                        finishActiveInstallation()
                    }
                    else
                    {
                        authenticationController.authenticationDidFail(message: nil)
                    }

                case .failure(let error):
                    progressController.closeProgressWindow()
                    if didAuthenticate
                    {
                        finishActiveInstallation()
                        self.showErrorAlert(error: error)
                    }
                    else
                    {
                        let message = self.localizedAuthenticationFailure(for: error)
                        authenticationController.authenticationDidFail(message: message)
                    }
                }
            }
        }

        if !didAuthenticate
        {
            finishActiveInstallation()
        }
    }

    func localizedAuthenticationFailure(for error: Error) -> String
    {
        return error.userFacingPresentation.combinedMessage
    }
    
    func showErrorAlert(error: Error)
    {
        self.popoverError = error as NSError
        
        let nsError = error as NSError
        
        let presentation = nsError.userFacingPresentation
        
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = presentation.title
        alert.informativeText = presentation.combinedMessage
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("View More Details", comment: ""))
        
        if let viewMoreButton = alert.buttons.last
        {
            viewMoreButton.target = self
            viewMoreButton.action = #selector(AppDelegate.showDetailedErrorDescription)
            
            self.errorAlert = alert
        }
        
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        
        alert.runModal()
        
        self.popoverController = nil
        self.errorAlert = nil
        self.popoverError = nil
    }
    
    @objc func showDetailedErrorDescription()
    {
        guard let errorAlert, let contentView = errorAlert.window.contentView else { return }
        
        let errorDetailsViewController = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: "errorDetailsViewController") as! ErrorDetailsViewController
        errorDetailsViewController.error = self.popoverError
        
        let fittingSize = errorDetailsViewController.view.fittingSize
        errorDetailsViewController.view.frame.size = fittingSize
        
        let popoverController = NSPopover()
        popoverController.contentViewController = errorDetailsViewController
        popoverController.contentSize = fittingSize
        popoverController.behavior = .transient
        popoverController.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .maxX)
        self.popoverController = popoverController
    }
    
    @objc func toggleLaunchAtLogin(_ item: NSMenuItem)
    {
        if #available(macOS 13, *)
        {
            let service = SMAppService.mainApp

            do
            {
                switch service.status
                {
                case .enabled:
                    try service.unregister()

                case .requiresApproval:
                    self.showLaunchAtLoginApproval()
                    return

                case .notRegistered, .notFound:
                    try service.register()

                @unknown default:
                    try service.register()
                }

                self.refreshLaunchAtLoginMenuItem()
                if service.status == .requiresApproval
                {
                    self.showLaunchAtLoginApproval()
                }
            }
            catch
            {
                self.refreshLaunchAtLoginMenuItem()
                self.showLaunchAtLoginFailure(error)
            }
        }
        else
        {
            let isEnabled = !LaunchAtLogin.isEnabled
            LaunchAtLogin.isEnabled = isEnabled
            self.refreshLaunchAtLoginMenuItem(legacyRequestedState: isEnabled)
        }
    }

    @IBAction func selectPreferredLanguage(_ item: NSMenuItem)
    {
        guard let language = PreferredLanguage.allCases.first(where: { $0.menuItemTag == item.tag }) else { return }

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

        UserDefaults.standard.synchronize()
        self.refreshPreferredLanguageMenuItems()
        self.promptToRestartForLanguageChange()
    }
    
    @IBAction private func uninstallMailPlugin(_ sender: NSMenuItem)
    {
        self.pluginManager.uninstallMailPlugin { (result) in
            DispatchQueue.main.async {
                switch result
                {
                case .failure(PluginError.cancelled): break
                case .failure(let error):
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Failed to Remove Legacy Mail Plug-in", comment: "")
                    alert.informativeText = error.userFacingPresentation.combinedMessage
                    alert.runModal()
                    
                case .success:
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Legacy Mail Plug-in Removed", comment: "")
                    alert.informativeText = NSLocalizedString("The legacy plug-in is no longer used by AltForge Server. Restart Mail to finish removing it.", comment: "")
                    alert.runModal()
                }
            }
        }
    }
    
    @IBAction private func showAboutPanel(_ sender: NSMenuItem)
    {
        self.aboutWindowController.show()
    }
}

extension AppDelegate: NSMenuDelegate
{
    func menuWillOpen(_ menu: NSMenu)
    {
        guard menu == self.appMenu else { return }
        
        // Clear any cached _jitAppListMenuControllers.
        self._jitAppListMenuControllers.removeAll()

        self.wiredDeviceIdentifiers = Set(ALTDeviceManager.shared.connectedDevices.map(\.identifier))
        self.connectedDevices = ALTDeviceManager.shared.availableDevices
        
        self.connectedDevicesMenuController.items = self.connectedDevices
        self.sideloadIPAConnectedDevicesMenuController.items = self.connectedDevices
        self.enableJITMenuController.items = self.connectedDevices

        self.launchAtLoginMenuItem.target = self
        self.launchAtLoginMenuItem.action = #selector(AppDelegate.toggleLaunchAtLogin(_:))
        self.refreshLaunchAtLoginMenuItem()
        self.refreshPreferredLanguageMenuItems()

        if !self.pluginManager.isMailPluginInstalled
        {
            // Hide "Install Mail Plug-In" option now that it's not required.
            self.installMailPluginMenuItem.isHidden = true
        }
        
        // Need to re-set this every time menu appears so we can refresh device app list.
        self.enableJITMenuController.submenuHandler = { [weak self] device in
            let submenu = NSMenu(title: NSLocalizedString("Sideloaded Apps", comment: ""))
            
            guard let `self` = self else { return submenu }

            let submenuController = MenuController<InstalledApp>(menu: submenu, items: [])
            submenuController.placeholder = NSLocalizedString("Loading...", comment: "")
            submenuController.action = { [weak self] (appInfo) in
                self?.enableJIT(for: appInfo, on: device)
            }
            
            // Keep strong reference
            self._jitAppListMenuControllers.append(submenuController)

            ALTDeviceManager.shared.fetchInstalledApps(on: device) { (installedApps, error) in
                DispatchQueue.main.async {
                    guard let installedApps = installedApps else {
                        print("Failed to fetch installed apps from \(device).", error!)
                        submenuController.placeholder = error?.userFacingPresentation.message
                        return
                    }
                    
                    print("Fetched \(installedApps.count) apps for \(device).")
                    
                    let sortedApps = installedApps.sorted { (app1, app2) in
                        if app1.name == app2.name
                        {
                            return app1.bundleIdentifier < app2.bundleIdentifier
                        }
                        else
                        {
                            return app1.name < app2.name
                        }
                    }
                    
                    submenuController.items = sortedApps
                    
                    if submenuController.items.isEmpty
                    {
                        submenuController.placeholder = NSLocalizedString("No Sideloaded Apps", comment: "")
                    }
                }
            }

            return submenu
        }
    }
    
    func menuDidClose(_ menu: NSMenu)
    {
        guard menu == self.appMenu else { return }
        
        // Clearing _jitAppListMenuControllers now prevents action handler from being called.
        // self._jitAppListMenuControllers = []
        
        // Set `submenuHandler` to nil to prevent prematurely fetching installed apps in menuWillOpen(_:)
        // when assigning self.connectedDevices to `items` (which implicitly calls `submenuHandler`)
        self.enableJITMenuController.submenuHandler = nil
    }
    
    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?)
    {
        guard menu == self.appMenu else { return }
        
        // The submenu won't update correctly if the user holds/releases
        // the Option key while the submenu is visible.
        // Workaround: temporarily set submenu to nil to dismiss it,
        // which will then cause the correct submenu to appear.
        
        let previousItem: NSMenuItem
        switch item
        {
        case self.sideloadAppMenuItem: previousItem = self.installAltStoreMenuItem
        case self.installAltStoreMenuItem: previousItem = self.sideloadAppMenuItem
        default: return
        }

        let submenu = previousItem.submenu
        previousItem.submenu = nil
        previousItem.submenu = submenu
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .sound, .badge])
    }
}
