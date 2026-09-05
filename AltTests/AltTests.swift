//
//  AltTests.swift
//  AltTests
//
//  Created by Riley Testut on 10/6/22.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

import XCTest
import CoreData
import UIKit
import Roxas
@testable import AltStore
@testable import AltStoreCore

@testable import AltSign

private final class InstallationFailingSaveContext: NSManagedObjectContext
{
    override func save() throws { throw CocoaError(.persistentStoreSave) }
}

private struct GSAFixture
{
    let status: Int
    var data = Data("<html>PRIVATE_FIXTURE</html>".utf8)
    var error: URLError? = nil
    var elapsed: TimeInterval = 0
}

private final class GSAInvalidationObserver: NSObject, URLSessionDelegate
{
    let expectation: XCTestExpectation

    init(_ expectation: XCTestExpectation) { self.expectation = expectation }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        XCTAssertNil(error)
        expectation.fulfill()
    }
}

// Per-request registrations isolate fixtures; an unregistered request always fails closed.
private final class GSAFixtureProtocol: URLProtocol
{
    private static let lock = NSLock()
    private static var handlers: [String: (URLRequest) -> GSAFixture] = [:]

    static func register(_ identifier: String, handler: @escaping (URLRequest) -> GSAFixture)
    {
        lock.lock()
        defer { lock.unlock() }
        handlers[identifier] = handler
    }

    static func unregister(_ identifier: String)
    {
        lock.lock()
        defer { lock.unlock() }
        handlers.removeValue(forKey: identifier)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading()
    {
        Self.lock.lock()
        let handler = Self.handlers[request.url?.query ?? ""]
        Self.lock.unlock()
        guard let handler = handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let fixture = handler(request)
        let response = HTTPURLResponse(url: url, statusCode: fixture.status, httpVersion: nil,
                                       headerFields: ["Content-Type": "text/html"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let error = fixture.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocol(self, didLoad: fixture.data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

extension String
{
    static let testDomain = "TestErrorDomain"
    
    static let testLocalizedTitle = "AltTest Failed"
    static let testLocalizedFailure = "The AltTest failed to pass."
    
    static let testOriginalLocalizedFailure = "The AltServer operation could not be completed."
    
    static let testUnrecognizedFailureReason = "The alien invasion has begun."
    static let testUnrecognizedRecoverySuggestion = "Find your loved ones and pray the aliens are merciful."
    
    static let testDescription = "The operation could not be completed because an error occured."
    static let testDebugDescription = "The very specific operation could not be completed because a detailed error occured. Code=101."
}

extension [String: String]
{
    static let unrecognizedProvider: Self = [
        NSLocalizedFailureReasonErrorKey: .testUnrecognizedFailureReason,
        NSLocalizedRecoverySuggestionErrorKey: .testUnrecognizedRecoverySuggestion
    ]
}

extension Error
{
    func serialized(provider: [String: String]?) -> NSError
    {
        AltTests.mockUserInfoValueProvider(for: self, values: provider) {
            return (self as NSError).sanitizedForSerialization()
        }
    }
}

extension URL
{
    static let testFileURL = URL(fileURLWithPath: "~/Desktop/TestApp.ipa")
}

final class AltTests: XCTestCase
{
    override func setUpWithError() throws
    {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    private func installationContext(failingSave: Bool = false) throws -> NSManagedObjectContext
    {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: DatabaseManager.shared.persistentContainer.managedObjectModel)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let context: NSManagedObjectContext = failingSave
            ? InstallationFailingSaveContext(concurrencyType: .mainQueueConcurrencyType)
            : NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    @MainActor
    private func installationFixture(in context: NSManagedObjectContext) -> InstalledApp
    {
        let app = NSEntityDescription.insertNewObject(forEntityName: "InstalledApp", into: context) as! InstalledApp
        app.name = "Installation Fixture"
        app.bundleIdentifier = "com.example.installation-fixture"
        app.resignedBundleIdentifier = "com.example.installation-fixture.fixture"
        app.version = "1.0"
        app.buildVersion = "1"
        app.installedDate = Date(timeIntervalSince1970: 1000)
        app.refreshedDate = app.installedDate
        app.expirationDate = Date(timeIntervalSince1970: 100000)
        app.isActive = true
        app.needsResign = false
        app.hasAlternateIcon = false
        app.appExtensions = []
        return app
    }

    @MainActor
    func testInstallationReceiptRecoveryAndIdempotency() throws
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = InstallationReceiptStore(rootURL: root)
        let context = try installationContext()
        let app = installationFixture(in: context)
        let receipt = InstallationReceipt(app: app)
        let directory = root.appendingPathComponent(receipt.bundleIdentifier)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("App.app"), withIntermediateDirectories: true)
        try store.write(receipt)
        context.reset() // The original unsaved installation context was lost.
        XCTAssertEqual(try store.recover(in: context, isInstalled: { _ in false }), 0)
        XCTAssertTrue(InstalledApp.all(in: context).isEmpty)
        XCTAssertNotNil(store.load(in: directory))
        XCTAssertEqual(try store.recover(in: context, isInstalled: { $0 == receipt.resignedBundleIdentifier }), 1)
        context.reset()
        let recovered = try XCTUnwrap(InstalledApp.all(in: context).first)
        XCTAssertEqual(recovered.bundleIdentifier, receipt.bundleIdentifier)
        XCTAssertTrue(recovered.needsResign)
        XCTAssertTrue(recovered.isActive)
        XCTAssertNil(store.load(in: directory))
        XCTAssertEqual(try store.recover(in: context, isInstalled: { _ in true }), 0)
        XCTAssertEqual(InstalledApp.all(in: context).count, 1)
        recovered.version = "existing-version"
        try context.save()
        try store.write(receipt)
        XCTAssertEqual(try store.recover(in: context, isInstalled: { _ in true }), 0)
        XCTAssertEqual(recovered.version, "existing-version")
        try store.remove(bundleIdentifier: receipt.bundleIdentifier, matching: UUID())
        XCTAssertNotNil(store.load(in: directory), "An older completion must not remove another receipt")
        try store.remove(bundleIdentifier: receipt.bundleIdentifier, matching: receipt.identifier)
        XCTAssertNil(store.load(in: directory))
    }

    @MainActor
    func testInstallationReceiptValidationAndSaveFailure() throws
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = InstallationReceiptStore(rootURL: root)
        let context = try installationContext(failingSave: true)
        let receipt = InstallationReceipt(app: installationFixture(in: context))
        let directory = root.appendingPathComponent(receipt.bundleIdentifier)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("App.app"), withIntermediateDirectories: true)
        try store.write(receipt)
        context.reset()
        XCTAssertThrowsError(try store.recover(in: context, isInstalled: { _ in true }))
        XCTAssertTrue(InstalledApp.all(in: context).isEmpty)
        XCTAssertNotNil(store.load(in: directory), "Save failure must retain recovery metadata")
        let goodContext = try installationContext()
        XCTAssertEqual(try store.recover(in: goodContext, isInstalled: { _ in true }), 1)

        for identifier in ["", "..", "../escape", "/absolute", String(repeating: "x", count: 256)] {
            XCTAssertFalse(InstallationReceipt.isValidBundleIdentifier(identifier))
        }
        let receiptURL = directory.appendingPathComponent(InstallationReceiptStore.filename)
        try Data(repeating: 0, count: 65537).write(to: receiptURL)
        XCTAssertNil(store.load(in: directory))
        try Data("not a receipt".utf8).write(to: receiptURL)
        XCTAssertNil(store.load(in: directory))
        try FileManager.default.removeItem(at: receiptURL)
        let outside = root.appendingPathComponent("outside.json")
        try Foundation.JSONEncoder().encode(receipt).write(to: outside)
        try FileManager.default.createSymbolicLink(at: receiptURL, withDestinationURL: outside)
        XCTAssertNil(store.load(in: directory))
    }

    @MainActor
    func testBackgroundInstallationReconcilesDelayedRegistration() throws
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let producer = try installationContext()
        let receipt = InstallationReceipt(app: installationFixture(in: producer))
        let directory = root.appendingPathComponent(receipt.bundleIdentifier)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("App.app"), withIntermediateDirectories: true)
        try InstallationReceiptStore(rootURL: root).write(receipt)
        producer.reset() // The device installs, but the original context never receives/saves success.

        let consumer = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        consumer.persistentStoreCoordinator = producer.persistentStoreCoordinator
        let store = InstallationReceiptStore(rootURL: root)
        var foreground = false
        var registered = false
        var liveProducer = false
        var delays: [TimeInterval] = []
        var checks: [() -> Void] = []
        var recovered = 0
        let coordinator = InstallationRecoveryCoordinator(canRun: { foreground }, attempt: { completion in
            do {
                let result = try store.reconcile(in: consumer, isInstalled: { $0 == receipt.resignedBundleIdentifier && registered },
                                                 isManaging: { _ in liveProducer })
                recovered += result.recoveredCount
                completion(result.pendingCount > 0)
            } catch { XCTFail("Unexpected reconciliation error: \(error)"); completion(false) }
        }, schedule: { delay, action in
            delays.append(delay)
            checks.append(action)
            return {}
        })
        coordinator.start()
        XCTAssertTrue(checks.isEmpty)
        foreground = true
        coordinator.start()
        XCTAssertTrue(InstalledApp.all(in: consumer).isEmpty)
        XCTAssertNotNil(store.load(in: directory))
        registered = true
        liveProducer = true
        try XCTUnwrap(checks.first)()
        checks.removeFirst()
        XCTAssertEqual(recovered, 0, "Do not race an installation still being managed")
        liveProducer = false
        try XCTUnwrap(checks.first)()
        checks.removeFirst()
        XCTAssertEqual(recovered, 1)
        XCTAssertEqual(delays, [1, 2])
        XCTAssertTrue(checks.isEmpty)
        consumer.reset()
        let tracked = try XCTUnwrap(InstalledApp.all(in: consumer).first)
        XCTAssertEqual(tracked.bundleIdentifier, receipt.bundleIdentifier)
        XCTAssertTrue(tracked.needsResign)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("App.app").path))
        coordinator.start()
        XCTAssertEqual(recovered, 1)
        XCTAssertEqual(InstalledApp.all(in: consumer).count, 1)
    }

    @MainActor
    func testInstallationRecoveryCoordinatorLifecycleAndBounds()
    {
        var foreground = true
        var completions: [(Bool) -> Void] = []
        var checks: [() -> Void] = []
        var cancellations = 0
        let coordinator = InstallationRecoveryCoordinator(canRun: { foreground }, attempt: { completions.append($0) }, schedule: { _, action in
            checks.append(action)
            return { cancellations += 1 }
        })
        coordinator.start()
        coordinator.start()
        XCTAssertEqual(completions.count, 1)
        foreground = false
        coordinator.stop()
        foreground = true
        coordinator.start()
        XCTAssertEqual(completions.count, 1, "A foreground transition must not overlap an unfinished database pass")
        completions[0](true)
        XCTAssertEqual(completions.count, 2)
        XCTAssertTrue(checks.isEmpty, "A stale completion must not schedule old-generation work")
        completions[1](true)
        XCTAssertEqual(checks.count, 1)
        coordinator.stop()
        XCTAssertEqual(cancellations, 1)
        coordinator.start()
        checks[0]() // Even an already-dequeued cancelled callback must do nothing.
        XCTAssertEqual(completions.count, 3)
        completions[2](false)

        var attempts = 0
        var delays: [TimeInterval] = []
        var pending: [() -> Void] = []
        let bounded = InstallationRecoveryCoordinator(canRun: { foreground }, attempt: { completion in
            attempts += 1
            completion(true)
        }, schedule: { delay, action in
            delays.append(delay)
            pending.append(action)
            return {}
        })
        bounded.start()
        for _ in 0..<5 {
            XCTAssertFalse(pending.isEmpty)
            guard !pending.isEmpty else { break }
            pending.removeFirst()()
        }
        XCTAssertEqual(attempts, 6)
        XCTAssertEqual(delays, [1, 2, 5, 10, 20])
        XCTAssertTrue(pending.isEmpty)
        foreground = false
        bounded.start()
        XCTAssertEqual(attempts, 6)
    }

    @MainActor
    func testInstallationManagementStateSynchronization()
    {
        let manager = AppManager.shared
        let identifier = "com.example.tracking.\(UUID().uuidString)"
        let app = AnyApp(name: "Tracking Fixture", bundleIdentifier: identifier, url: nil, storeApp: nil)
        let operation = AppManager.AppOperation.install(app)
        let progress = Progress(totalUnitCount: 100)
        manager.set(nil, for: operation)
        defer { manager.set(nil, for: operation) }
        XCTAssertFalse(manager.isActivelyManagingApp(withBundleID: identifier))
        manager.set(progress, for: operation)
        XCTAssertTrue(manager.isActivelyManagingApp(withBundleID: identifier))
        DispatchQueue.concurrentPerform(iterations: 2) { worker in
            for iteration in 0..<100 {
                if worker == 0 {
                    manager.set(iteration.isMultiple(of: 2) ? progress : nil, for: operation)
                } else {
                    _ = manager.isActivelyManagingApp(withBundleID: identifier)
                }
            }
        }
        manager.set(nil, for: operation)
        XCTAssertFalse(manager.isActivelyManagingApp(withBundleID: identifier))
    }

    func testInstallationCacheRetention()
    {
        XCTAssertTrue(InstallationReceiptStore.shouldRemoveCache(hasRecord: false, hasCachedApp: false, hasReceipt: false, isManaging: false))
        for bit in 0..<4 {
            XCTAssertFalse(InstallationReceiptStore.shouldRemoveCache(hasRecord: bit == 0, hasCachedApp: bit == 1, hasReceipt: bit == 2, isManaging: bit == 3))
        }
    }

    @MainActor
    func testInstallationUnconfirmedOutcomeIsStageSpecific()
    {
        XCTAssertTrue(SideloadingStatusView.needsInstallationConfirmation(error: OperationError.timedOut, stage: .installingApp))
        XCTAssertTrue(SideloadingStatusView.needsInstallationConfirmation(error: OperationError.cancelled, stage: .installingApp))
        XCTAssertTrue(SideloadingStatusView.needsInstallationConfirmation(error: ALTServerError(.lostConnection), stage: .installingApp))
        XCTAssertFalse(SideloadingStatusView.needsInstallationConfirmation(error: OperationError.timedOut, stage: .signingApp))
        XCTAssertFalse(SideloadingStatusView.needsInstallationConfirmation(error: ALTAppleAPIError(.incorrectCredentials), stage: .installingApp))
        XCTAssertFalse(SideloadingStatusView.needsInstallationConfirmation(error: ALTServerError(.invalidResponse), stage: .installingApp))
    }

    @MainActor
    func testInstallationScreenActivityLeases()
    {
        for original in [false, true] {
            var value = original
            let controller = InstallationScreenActivity(read: { value }, write: { value = $0 })
            let first = UUID(), second = UUID()
            controller.begin(first)
            controller.begin(first)
            controller.begin(second)
            XCTAssertTrue(value)
            controller.end(first)
            XCTAssertTrue(value)
            controller.end(second)
            XCTAssertEqual(value, original)
            controller.end(second)
            XCTAssertEqual(value, original)
        }
    }

    @MainActor
    func testSideloadingStatusLayoutAndThemes() throws
    {
        let original = UserDefaults.standard.preferredTheme
        defer { UserDefaults.standard.preferredTheme = original }
        for theme in [AltTheme.forgeRed, .oceanBlue] {
            UserDefaults.standard.preferredTheme = theme
            for width in [320.0, 375.0, 844.0] {
                for style in [UIUserInterfaceStyle.light, .dark] {
                    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 1024))
                    let host = UIViewController()
                    window.rootViewController = host
                    window.overrideUserInterfaceStyle = style
                    host.loadViewIfNeeded()
                    host.traitOverrides.userInterfaceStyle = style
                    host.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
                    window.isHidden = false
                    defer { window.isHidden = true; window.rootViewController = nil }
                    let view = SideloadingStatusView()
                    host.view.addSubview(view)
                    view.translatesAutoresizingMaskIntoConstraints = true
                    view.tintColor = .altPrimary
                    let progress = Progress(totalUnitCount: 100)
                    view.begin(title: "正在安装一个名称较长的应用", stage: "正在认证 Apple ID", progress: progress)
                    view.update(stage: "正在安装 App", detail: "正在等待服务器返回安装进度")
                    window.layoutIfNeeded()
                    XCTAssertEqual(view.traitCollection.userInterfaceStyle, style)
                    XCTAssertEqual(view.traitCollection.preferredContentSizeCategory, .accessibilityExtraExtraExtraLarge)
                    let size = view.systemLayoutSizeFitting(CGSize(width: width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
                    XCTAssertTrue(size.height.isFinite && size.height > 90)
                    view.frame = CGRect(origin: .zero, size: size)
                    view.layoutIfNeeded()
                    XCTAssertFalse(view.hasAmbiguousLayout)
                    for child in view.subviews where !child.isHidden {
                        XCTAssertGreaterThanOrEqual(child.frame.minX, -0.5)
                        XCTAssertLessThanOrEqual(child.frame.maxX, width + 0.5)
                        XCTAssertLessThanOrEqual(child.frame.maxY, size.height + 0.5)
                    }
                    view.finish(error: OperationError.timedOut)
                    var dismissCount = 0
                    view.dismissHandler = { dismissCount += 1 }
                    let dismiss = try XCTUnwrap(view.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == NSLocalizedString("Dismiss", comment: "") })
                    XCTAssertFalse(dismiss.isHidden)
                    XCTAssertGreaterThanOrEqual(dismiss.bounds.width, 44)
                    dismiss.sendActions(for: .primaryActionTriggered)
                    XCTAssertEqual(dismissCount, 1)
                    view.finish(error: nil)
                    XCTAssertEqual(view.subviews.compactMap { $0 as? UIProgressView }.first?.progress, 1)
                    view.layoutIfNeeded()
                    var image = UIImage()
                    view.traitCollection.performAsCurrent {
                        image = UIGraphicsImageRenderer(size: size).image { view.layer.render(in: $0.cgContext) }
                    }
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "Install-status-\(theme)-\(width)-\(style.rawValue)"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                    view.end()
                    if theme == .oceanBlue && width == 375 && style == .light {
                        host.traitOverrides.preferredContentSizeCategory = .large
                        progress.completedUnitCount = 65
                        let normalView = SideloadingStatusView()
                        normalView.translatesAutoresizingMaskIntoConstraints = true
                        host.view.addSubview(normalView)
                        normalView.tintColor = .altPrimary
                        normalView.begin(title: "正在安装示例应用", stage: "正在签名 App", progress: progress)
                        let updated = expectation(description: "Main-queue progress applied")
                        DispatchQueue.main.async { updated.fulfill() }
                        wait(for: [updated], timeout: 2)
                        window.layoutIfNeeded()
                        let normalSize = normalView.systemLayoutSizeFitting(CGSize(width: width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
                        XCTAssertLessThan(normalSize.height, 220)
                        normalView.frame.size = normalSize
                        normalView.layoutIfNeeded()
                        let preview = XCTAttachment(image: UIGraphicsImageRenderer(size: normalSize).image { normalView.layer.render(in: $0.cgContext) })
                        preview.name = "Install-status-normal-size"
                        preview.lifetime = .keepAlways
                        add(preview)
                        normalView.end()
                    }
                }
            }
        }
    }

    @MainActor
    func testSideloadingPanelRespectsNavigationSafeArea() throws
    {
        let controller = try XCTUnwrap(UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "myAppsViewController") as? MyAppsViewController)
        let navigation = UINavigationController(rootViewController: controller)
        navigation.navigationBar.prefersLargeTitles = true
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = navigation
        window.isHidden = false
        defer { controller.hideSideloadingStatus(); window.isHidden = true; window.rootViewController = nil }
        controller.loadViewIfNeeded()
        let originalInset = controller.collectionView.contentInset
        controller.showSideloadingStatus(progress: Progress(totalUnitCount: 100), title: "Installing App", stage: "Signing App")
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        let panel = try XCTUnwrap(controller.view.subviews.first { $0.accessibilityIdentifier == "SideloadingStatusContainer" })
        XCTAssertFalse(panel.isHidden)
        let panelFrame = panel.convert(panel.bounds, to: window)
        let barFrame = navigation.navigationBar.convert(navigation.navigationBar.bounds, to: window)
        XCTAssertGreaterThanOrEqual(panelFrame.minY, barFrame.maxY - 1)
        XCTAssertGreaterThan(panelFrame.height, 90)
        XCTAssertLessThan(panelFrame.height, 220)
        XCTAssertGreaterThan(controller.collectionView.contentInset.top, originalInset.top)
        controller.hideSideloadingStatus()
        XCTAssertEqual(controller.collectionView.contentInset, originalInset)
        XCTAssertTrue(panel.isHidden)
    }

    @MainActor
    func testThemeControlsFollowSelectedColor()
    {
        let original = UserDefaults.standard.preferredTheme
        defer { UserDefaults.standard.preferredTheme = original }
        let button = Button(type: .system)
        for theme in AltTheme.allCases {
            UserDefaults.standard.preferredTheme = theme
            button.tintColor = .altPrimary
            button.isEnabled = true
            let traits = UITraitCollection(userInterfaceStyle: .light)
            XCTAssertEqual(button.backgroundColor?.resolvedColor(with: traits), UIColor.altPrimary.resolvedColor(with: traits))
            button.isEnabled = false
            XCTAssertEqual(button.backgroundColor?.resolvedColor(with: traits), UIColor.tertiarySystemFill.resolvedColor(with: traits))
        }
    }

    func testAllKnownErrorsHaveCompleteUserFacingPresentations() throws
    {
        let providerErrors: [NSError] =
            (0...7).map { NSError(domain: AltSignErrorDomain, code: $0) } +
            (3000...3022).map { NSError(domain: ALTAppleAPIErrorDomain, code: $0) } +
            (0...16).map { NSError(domain: AltServerErrorDomain, code: $0) } +
            [100, 101].map { NSError(domain: AltServerErrorDomain, code: $0) } +
            (0...6).map { NSError(domain: AltServerConnectionErrorDomain, code: $0) }

        let errors = AltTests.allRealErrors.map { $0 as NSError } + providerErrors
        for error in errors
        {
            let presentation = error.userFacingPresentation
            XCTAssertFalse(presentation.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, error.localizedErrorCode)
            XCTAssertFalse(presentation.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, error.localizedErrorCode)
            XCTAssertFalse(try XCTUnwrap(presentation.recoverySuggestion, error.localizedErrorCode).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, error.localizedErrorCode)
            XCTAssertFalse(presentation.message.contains(".swift line "), error.localizedErrorCode)
            XCTAssertFalse(presentation.message.contains(".m line "), error.localizedErrorCode)
        }
    }

    func testAuthenticationParsingErrorUsesAuthenticationCopy() throws
    {
        let error = ALTAppleAPIError(.authenticationHandshakeFailed, userInfo: [
            NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: 3840)
        ]) as NSError
        let presentation = error.userFacingPresentation

        XCTAssertEqual(presentation.title, NSLocalizedString("Apple ID Sign-In Failed", comment: "Error presentation title"))
        XCTAssertEqual(presentation.message, NSLocalizedString("The secure sign-in with Apple could not be completed.", comment: ""))
        XCTAssertNotEqual(presentation.message, NSError(domain: NSCocoaErrorDomain, code: 3840).localizedDescription)
        XCTAssertNotNil(presentation.recoverySuggestion)
    }

    func testAuthenticationServiceOutageIdentifiesTokenStepAndHTTPStatus() throws
    {
        let error = ALTAppleAPIError(.authenticationHandshakeFailed, userInfo: [
            ALTAppleAPIRequestOperationErrorKey: "apptokens",
            ALTAppleAPIHTTPStatusCodeErrorKey: NSNumber(value: 503),
            ALTAppleAPIResponseMIMETypeErrorKey: "text/html",
            NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: 3840)
        ]) as NSError
        let presentation = error.userFacingPresentation

        XCTAssertEqual(
            presentation.message,
            String(
                format: NSLocalizedString("Apple's authentication service is temporarily unavailable while %@ (HTTP %ld).", comment: "Apple authentication service outage"),
                NSLocalizedString("issuing the developer token", comment: "Apple authentication step"),
                503
            )
        )
        XCTAssertEqual(
            presentation.recoverySuggestion,
            NSLocalizedString("The sign-in endpoint returned a server error. Wait a few minutes, then retry. If it continues, include the diagnostic details in your report.", comment: "Apple authentication outage recovery")
        )
        XCTAssertEqual(error.userInfo[ALTAppleAPIRequestOperationErrorKey] as? String, "apptokens")
        XCTAssertEqual((error.userInfo[ALTAppleAPIHTTPStatusCodeErrorKey] as? NSNumber)?.intValue, 503)

        let serializedError = error.serialized(provider: nil)
        XCTAssertEqual(serializedError.userInfo[ALTAppleAPIRequestOperationErrorKey] as? String, "apptokens")
        XCTAssertEqual((serializedError.userInfo[ALTAppleAPIHTTPStatusCodeErrorKey] as? NSNumber)?.intValue, 503)
        XCTAssertEqual(serializedError.userInfo[ALTAppleAPIResponseMIMETypeErrorKey] as? String, "text/html")
    }

    func testAuthenticationHTMLResponseIsNotPresentedAsIPAError() throws
    {
        let error = ALTAppleAPIError(.authenticationHandshakeFailed, userInfo: [
            ALTAppleAPIRequestOperationErrorKey: "complete",
            ALTAppleAPIHTTPStatusCodeErrorKey: NSNumber(value: 200),
            ALTAppleAPIResponseMIMETypeErrorKey: "text/html"
        ]) as NSError
        let presentation = error.userFacingPresentation

        XCTAssertEqual(
            presentation.message,
            String(
                format: NSLocalizedString("Apple's authentication service returned a web page instead of sign-in data while %@.", comment: "Apple authentication HTML response"),
                NSLocalizedString("verifying the Apple ID", comment: "Apple authentication step")
            )
        )
        XCTAssertNotNil(presentation.recoverySuggestion)
    }

    func testAuthenticationResponseParserAndPrivacy() throws
    {
        let api = ALTAppleAPI()
        let url = URL(string: "https://gsa.apple.com/grandslam/GsService2")!
        let unavailable = HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil,
                                          headerFields: ["Content-Type": "text/html"])!
        for operation in ["init", "complete", "apptokens", "complete.decrypted", "apptokens.decrypted"]
        {
            XCTAssertThrowsError(try api.authenticationDictionary(from: Data("<html>PRIVATE_FIXTURE</html>".utf8),
                                                                  operation: operation, response: unavailable)) { error in
                let error = error as NSError
                XCTAssertEqual(error.domain, ALTAppleAPIErrorDomain)
                XCTAssertEqual(error.code, 3020)
                XCTAssertEqual(error.userInfo[ALTAppleAPIRequestOperationErrorKey] as? String, operation)
                XCTAssertEqual(error.appleAuthenticationDiagnosticSummary, operation + " · HTTP 503 · text/html")
                XCTAssertFalse(String(describing: error.userInfo).contains("PRIVATE_FIXTURE"))
                XCTAssertTrue(((error.userInfo[NSUnderlyingErrorKey] as? NSError)?.userInfo ?? [:]).isEmpty)
            }
        }
        let rawError = NSError(domain: NSCocoaErrorDomain, code: 3840,
                               userInfo: [NSDebugDescriptionErrorKey: "PRIVATE_FIXTURE"])
        let unexpectedMIME = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                             headerFields: ["Content-Type": "application/private-fixture"])!
        let sanitized = api.authenticationResponseError(operation: "PRIVATE_FIXTURE", response: unexpectedMIME,
                                                          underlyingError: rawError) as NSError
        XCTAssertEqual(sanitized.appleAuthenticationDiagnosticSummary, "unknown · HTTP 200 · other")
        XCTAssertFalse(String(describing: sanitized.userInfo).contains("PRIVATE_FIXTURE"))
    }

    func testAuthenticationStructuredErrorsAndTwoFactorHTTP() throws
    {
        let api = ALTAppleAPI()
        let url = URL(string: "https://gsa.apple.com/grandslam/GsService2")!
        func response(_ code: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
            return HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: headers)!
        }
        let credentials = try PropertyListSerialization.data(fromPropertyList: ["Response": ["Status": ["ec": -20101]]],
                                                              format: .xml, options: 0)
        XCTAssertThrowsError(try api.authenticationServiceDictionary(from: credentials, operation: "init", response: response(401))) {
            XCTAssertEqual(($0 as NSError).code, 3002)
        }
        let success = try PropertyListSerialization.data(fromPropertyList: ["Response": ["Status": ["ec": 0]]],
                                                         format: .binary, options: 0)
        XCTAssertNoThrow(try api.authenticationServiceDictionary(from: success, operation: "complete", response: response(200)))
        XCTAssertThrowsError(try api.authenticationServiceDictionary(from: success, operation: "complete", response: response(503)))
        let missingStatusCode = try PropertyListSerialization.data(fromPropertyList: ["Response": ["Status": [:]]],
                                                                   format: .xml, options: 0)
        XCTAssertThrowsError(try api.authenticationServiceDictionary(from: missingStatusCode, operation: "init", response: response(200)))
        let emptyDictionary = try PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
        XCTAssertThrowsError(try api.validateTrustedDeviceResponse(from: emptyDictionary, response: response(200)))
        let wrongCode = try PropertyListSerialization.data(fromPropertyList: ["ec": -21669], format: .xml, options: 0)
        XCTAssertThrowsError(try api.validateTrustedDeviceResponse(from: wrongCode, response: response(401))) {
            XCTAssertEqual(($0 as NSError).code, 3019)
        }
        for code in [429, 503]
        {
            XCTAssertThrowsError(try api.validateSMSVerificationResponse(response(code))) {
                XCTAssertEqual(($0 as NSError).code, 3020)
            }
        }
        XCTAssertNoThrow(try api.validateSMSVerificationResponse(response(200, headers: ["x-apple-pe-token": "fixture"])))
        XCTAssertThrowsError(try api.validateSMSVerificationResponse(response(200))) {
            XCTAssertEqual(($0 as NSError).code, 3019)
        }
    }

    func testAuthenticationRetriesRecoverOnFreshSessions() throws
    {
        let success = try PropertyListSerialization.data(fromPropertyList: ["Response": ["Status": ["ec": 0]]], format: .xml, options: 0)
        for operation in ["init", "complete", "apptokens"]
        {
            let result = exerciseGSA([GSAFixture(status: 503), GSAFixture(status: 502),
                                      GSAFixture(status: 200, data: success)], operation: operation,
                                     expectedAttempts: 3, expectedDelays: [1, 2])
            XCTAssertNoThrow(try result.get())
        }
    }

    func testAuthenticationRetryLimitAndPrivacy() throws
    {
        let result = exerciseGSA(Array(repeating: GSAFixture(status: 503), count: 5),
                                 expectedAttempts: 5, expectedDelays: [1, 2, 4, 8])
        XCTAssertThrowsError(try result.get()) {
            let error = $0 as NSError
            XCTAssertEqual(error.appleAuthenticationDiagnosticSummary, "apptokens · HTTP 503 · text/html")
            XCTAssertEqual(error.code, 3020)
            XCTAssertFalse(String(describing: error.userInfo).contains("PRIVATE_FIXTURE"))
        }
    }

    func testAuthenticationDoesNotRetryTerminalFailures() throws
    {
        for status in [200, 401, 429]
        {
            let result = exerciseGSA([GSAFixture(status: status)], expectedAttempts: 1, expectedDelays: [])
            XCTAssertThrowsError(try result.get()) { XCTAssertEqual(($0 as NSError).code, 3020) }
        }
        for (appleCode, expectedCode) in [(-20101, 3002), (-22421, 3021), (-9999, -9999)]
        {
            let data = try PropertyListSerialization.data(fromPropertyList: ["Response": ["Status": ["ec": appleCode]]], format: .xml, options: 0)
            let result = exerciseGSA([GSAFixture(status: 503, data: data)], expectedAttempts: 1, expectedDelays: [])
            XCTAssertThrowsError(try result.get()) { XCTAssertEqual(($0 as NSError).code, expectedCode) }
        }
        for code in [URLError.Code.timedOut, .cancelled, .networkConnectionLost]
        {
            let result = exerciseGSA([GSAFixture(status: 503, error: URLError(code))], expectedAttempts: 1, expectedDelays: [])
            XCTAssertThrowsError(try result.get()) {
                XCTAssertEqual(($0 as NSError).domain, NSURLErrorDomain)
                XCTAssertEqual(($0 as NSError).code, code.rawValue)
            }
        }
        for operation in ["unknown", "sms.verify", "trusted-device.verify"]
        {
            let result = exerciseGSA([GSAFixture(status: 503)], operation: operation, expectedAttempts: 1, expectedDelays: [])
            XCTAssertThrowsError(try result.get())
        }
        let result = exerciseGSA([GSAFixture(status: 503)], host: "example.invalid", expectedAttempts: 1, expectedDelays: [])
        XCTAssertThrowsError(try result.get())
    }

    func testAuthenticationRetryDeadline() throws
    {
        let lateResponse = exerciseGSA([GSAFixture(status: 503, elapsed: 58), GSAFixture(status: 503, elapsed: 2)],
                                       expectedAttempts: 2, expectedDelays: [1], expectedTimeouts: [15, 1])
        XCTAssertThrowsError(try lateResponse.get()) { XCTAssertEqual(($0 as NSError).code, 3020) }
        let delayedScheduler = exerciseGSA([GSAFixture(status: 503)], expectedAttempts: 1, expectedDelays: [1], schedulerStall: 61)
        XCTAssertThrowsError(try delayedScheduler.get()) { XCTAssertEqual(($0 as NSError).code, 3020) }
    }

    private func exerciseGSA(_ fixtures: [GSAFixture], operation: String = "apptokens", host: String = "gsa.apple.com",
                             expectedAttempts: Int, expectedDelays: [TimeInterval], expectedTimeouts: [TimeInterval]? = nil,
                             schedulerStall: TimeInterval = 0) -> Result<[String: Any], Error>
    {
        let completed = expectation(description: "GSA completes once")
        completed.assertForOverFulfill = true
        let invalidated = expectation(description: "Every attempt releases its session")
        invalidated.expectedFulfillmentCount = expectedAttempts
        invalidated.assertForOverFulfill = true
        let delegate = GSAInvalidationObserver(invalidated)
        let identifier = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://\(host)/grandslam/GsService2?\(identifier)")!)
        request.httpMethod = "POST"
        let body = Data("SYNTHETIC_GSA_REQUEST".utf8)
        request.httpBody = body
        var attempts = 0
        var sessions: [URLSession] = []
        var delays: [TimeInterval] = []
        var now: TimeInterval = 100
        var result: Result<[String: Any], Error> = .failure(URLError(.unknown))

        GSAFixtureProtocol.register(identifier) { received in
            XCTAssertEqual(received.httpMethod, "POST")
            // URLSession may convert a body into a stream before URLProtocol receives it.
            if let receivedBody = received.httpBody { XCTAssertEqual(receivedBody, body) }
            else if let stream = received.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var bytes = [UInt8](repeating: 0, count: 256)
                let count = stream.read(&bytes, maxLength: bytes.count)
                XCTAssertEqual(count, body.count)
                if count > 0 { XCTAssertEqual(Data(bytes.prefix(count)), body) }
            } else { XCTFail("The retried request lost its body") }
            guard attempts < fixtures.count else {
                XCTFail("GSA exceeded the expected request count")
                return GSAFixture(status: 400)
            }
            let fixture = fixtures[attempts]
            attempts += 1
            now += fixture.elapsed
            return fixture
        }
        defer { GSAFixtureProtocol.unregister(identifier) }

        ALTAppleAPI().sendGSARequest(request, operation: operation, makeSession: { configuration in
            XCTAssertNil(configuration.urlCache)
            XCTAssertNil(configuration.httpCookieStorage)
            XCTAssertNil(configuration.urlCredentialStorage)
            XCTAssertEqual(configuration.requestCachePolicy, .reloadIgnoringLocalCacheData)
            let timeout = expectedTimeouts?[sessions.count] ?? 15
            XCTAssertEqual(configuration.timeoutIntervalForRequest, timeout)
            XCTAssertEqual(configuration.timeoutIntervalForResource, timeout)
            configuration.protocolClasses = [GSAFixtureProtocol.self]
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            sessions.append(session)
            return session
        }, schedule: { delay, work in
            delays.append(delay)
            now += delay + schedulerStall
            work()
        }, uptime: { now }) {
            result = $0
            completed.fulfill()
        }
        wait(for: [completed, invalidated], timeout: 10)
        XCTAssertEqual(attempts, expectedAttempts)
        XCTAssertEqual(delays, expectedDelays)
        XCTAssertEqual(Set(sessions.map { ObjectIdentifier($0) }).count, expectedAttempts)
        return result
    }

    func testALTApplicationIgnoresMalformedOptionalMetadata() throws
    {
        let appURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathExtension("app")
        defer { try? FileManager.default.removeItem(at: appURL) }

        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)

        let infoDictionary: [String: Any] = [
            "CFBundleDisplayName": 42,
            kCFBundleNameKey as String: "Malformed Metadata Fixture",
            kCFBundleIdentifierKey as String: "com.legeling.AltForgeTests.MalformedMetadata",
            "CFBundleShortVersionString": ["invalid"],
            kCFBundleVersionKey as String: ["invalid"],
            "MinimumOSVersion": ["invalid"],
            "UIDeviceFamily": [["invalid": true]],
            "CFBundleIcons": "invalid",
            "CFBundleIconFiles": [42]
        ]
        let infoPlistURL = appURL.appendingPathComponent("Info.plist")
        XCTAssertTrue((infoDictionary as NSDictionary).write(to: infoPlistURL, atomically: true))

        let application = try XCTUnwrap(ALTApplication(fileURL: appURL))
        XCTAssertEqual(application.name, "Malformed Metadata Fixture")
        XCTAssertEqual(application.version, "1.0")
        XCTAssertEqual(application.buildVersion, "1")
        XCTAssertNil(application.icon)
    }

    func testHealthKitCapabilityMapping()
    {
        XCTAssertEqual(ALTEntitlement(feature: .healthKit), .healthKit)
        XCTAssertEqual(ALTFeature(entitlement: .healthKit), .healthKit)

        let healthKitAccess = ALTEntitlement(rawValue: "com.apple.developer.healthkit.access")
        XCTAssertNil(ALTFeature(entitlement: healthKitAccess))
    }

    func testUnsupportedAppleWatchBundleIsRemovedBeforeSigning() throws
    {
        let appURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathExtension("app")
        defer { try? FileManager.default.removeItem(at: appURL) }

        let watchAppURL = appURL
            .appendingPathComponent("Watch", isDirectory: true)
            .appendingPathComponent("Companion.app", isDirectory: true)
        try FileManager.default.createDirectory(at: watchAppURL, withIntermediateDirectories: true)

        XCTAssertTrue(try removeUnsupportedAppleWatchBundle(from: appURL))
        XCTAssertFalse(FileManager.default.fileExists(atPath: watchAppURL.path))
        XCTAssertFalse(try removeUnsupportedAppleWatchBundle(from: appURL))
    }

    func testSigningDiagnosticDetailIsRelativeAndBounded()
    {
        let rawValue = "/private/var/mobile/Payload/WeChat.app/Frameworks/Example.framework/Example (arm64)\n"
        let detail = sanitizedSigningDiagnosticDetail(rawValue)

        XCTAssertEqual(detail, "WeChat.app/Frameworks/Example.framework/Example (arm64)")
        XCTAssertFalse(detail?.contains("/private/var/mobile") == true)
        XCTAssertEqual(sanitizedSigningDiagnosticDetail("*"), NSLocalizedString("Main App Bundle", comment: "Signing diagnostic detail"))
    }

    func testThemePreferenceDefaultsAndRoundTrips()
    {
        let suiteName = "com.legeling.AltForgeTests.Theme.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(userDefaults.preferredTheme, .forgeRed)

        for theme in AltTheme.allCases
        {
            userDefaults.preferredTheme = theme
            XCTAssertEqual(userDefaults.preferredTheme, theme)
        }

        userDefaults.set("unsupported-theme", forKey: "preferredTheme")
        XCTAssertEqual(userDefaults.preferredTheme, .forgeRed)
    }
}

// Helper Methods
extension AltTests
{
    func unbridge<T: ALTLocalizedError>(_ error: NSError, to errorType: T) throws -> Error
    {
        let unbridgedError = try XCTUnwrap(error as? T)
        return unbridgedError
    }
    
    func send(_ error: Error, serverProvider: [String: String]? = nil, clientProvider: [String: String]? = nil) throws -> NSError
    {
        let altserverError = ALTServerError(error)
        
        let codableError = CodableError(error: altserverError)
        
        let jsonData: Data
        if let serverProvider
        {
            jsonData = try AltTests.mockUserInfoValueProvider(for: error, values: serverProvider) {
                return try JSONEncoder().encode(codableError)
            }
        }
        else
        {
            jsonData = try JSONEncoder().encode(codableError)
        }
        
        let decodedError: CodableError
        if let clientProvider
        {
            decodedError = try AltTests.mockUserInfoValueProvider(for: error, values: clientProvider) {
                return try Foundation.JSONDecoder().decode(CodableError.self, from: jsonData)
            }
        }
        else
        {
            decodedError = try Foundation.JSONDecoder().decode(CodableError.self, from: jsonData)
        }
        
        let receivedError = decodedError.error
        return receivedError as NSError
    }
    
    static func mockUserInfoValueProvider<T, Error: Swift.Error>(for error: Error, values: [String: String]?, closure: () throws -> T) rethrows -> T
    {
        let provider = NSError.userInfoValueProvider(forDomain: error._domain)
        NSError.setUserInfoValueProvider(forDomain: error._domain) { (error, key) -> Any? in
            let nsError = error as NSError
            guard nsError.code == error._code else { return provider?(nsError, key) }

            switch key
            {
            case NSLocalizedDescriptionKey:
                guard nsError.localizedFailure == nil else {
                    // Error has localizedFailure, so return nil to construct localizedDescription from it + localizedFailureReason.
                    return nil
                }

                // Otherwise, return failureReason for localizedDescription to avoid system prepending "Operation Failed" message.
                return values?[NSLocalizedFailureReasonErrorKey]
                
            default:
                return values?[key]
            }
        }

        defer {
            NSError.setUserInfoValueProvider(forDomain: error._domain) { (error, key) in
                provider?(error, key)
            }
        }
        
        let value = try closure()
        return value
    }
    
    func ALTAssertErrorsEqual(_ error1: Error, _ error2: Error, ignoring ignoredValues: Set<String> = [], ignoreExtraUserInfoValues: Bool = false, file: StaticString = #file, line: UInt = #line)
    {
        if !ignoredValues.contains(ALTUnderlyingErrorDomainErrorKey)
        {
            XCTAssertEqual(error1._domain, error2._domain, file: file, line: line)
        }
        
        if !ignoredValues.contains(ALTUnderlyingErrorCodeErrorKey)
        {
            XCTAssertEqual(error1._code, error2._code, file: file, line: line)
        }
        
        if !ignoredValues.contains(NSLocalizedDescriptionKey)
        {
            XCTAssertEqual(error1.localizedDescription, error2.localizedDescription, "Localized Descriptions don't match.", file: file, line: line)
        }
        
        let nsError1 = error1 as NSError
        let nsError2 = error2 as NSError
        
        if !ignoredValues.contains(ALTLocalizedTitleErrorKey)
        {
            XCTAssertEqual(nsError1.localizedTitle, nsError2.localizedTitle, "Titles don't match.", file: file, line: line)
        }
        
        if !ignoredValues.contains(NSLocalizedFailureErrorKey)
        {
            XCTAssertEqual(nsError1.localizedFailure, nsError2.localizedFailure, "Failures don't match.", file: file, line: line)
        }
        
        if !ignoredValues.contains(NSLocalizedFailureReasonErrorKey)
        {
            XCTAssertEqual(nsError1.localizedFailureReason, nsError2.localizedFailureReason, "Failure reasons don't match.", file: file, line: line)
        }
        
        if !ignoredValues.contains(NSLocalizedRecoverySuggestionErrorKey)
        {
            XCTAssertEqual(nsError1.localizedRecoverySuggestion, nsError2.localizedRecoverySuggestion, file: file, line: line)
        }
        
        if !ignoredValues.contains(NSDebugDescriptionErrorKey)
        {
            XCTAssertEqual(nsError1.localizedDebugDescription, nsError2.localizedDebugDescription, file: file, line: line)
        }
        
        if !ignoreExtraUserInfoValues
        {
            // Ensure remaining user info values match.
            let standardKeys: Set<String> = [NSLocalizedDescriptionKey, ALTLocalizedTitleErrorKey, NSLocalizedFailureErrorKey, NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey, NSUnderlyingErrorKey, NSDebugDescriptionErrorKey]
            let filteredUserInfo1 = nsError1.userInfo.filter { !standardKeys.contains($0.key) }
            let filteredUserInfo2 = nsError2.userInfo.filter { !standardKeys.contains($0.key) }
            XCTAssertEqual(filteredUserInfo1 as NSDictionary, filteredUserInfo2 as NSDictionary, file: file, line: line)
        }
    }
    
    @discardableResult
    func ALTAssertUnderlyingErrorEqualsError(_ receivedError: Error, _ error: Error, ignoring ignoredValues: Set<String> = [], ignoreExtraUserInfoValues: Bool = false, file: StaticString = #file, line: UInt = #line) throws -> NSError
    {
        // Test receivedError == ALTServerError.underlyingError
        XCTAssertEqual(receivedError._domain, ALTServerError.errorDomain, file: file, line: line)
        
        if !ignoredValues.contains(ALTUnderlyingErrorCodeErrorKey)
        {
            XCTAssertEqual(receivedError._code, ALTServerError.underlyingError.rawValue, file: file, line: line)
        }
        
        // Test underlyingError == error
        let underlyingError = try XCTUnwrap(receivedError.underlyingError)
        ALTAssertErrorsEqual(underlyingError, error, ignoring: ignoredValues, ignoreExtraUserInfoValues: ignoreExtraUserInfoValues, file: file, line: line)
        
        // Test receivedError forwards all properties to underlyingError.
        var ignoredValues = ignoredValues
        ignoredValues.formUnion([ALTUnderlyingErrorDomainErrorKey, ALTUnderlyingErrorCodeErrorKey])
        ALTAssertErrorsEqual(receivedError, underlyingError, ignoring: ignoredValues, ignoreExtraUserInfoValues: true, file: file, line: line) // Always ignore extra user info values.
        
        return underlyingError as NSError
    }
    
    func ALTAssertErrorFailureAndDescription(_ error: Error, failure: String?, baseDescription: String, file: StaticString = #file, line: UInt = #line)
    {
        let localizedDescription: String
        if let failure
        {
            localizedDescription = failure + " " + baseDescription
        }
        else
        {
            localizedDescription = baseDescription
        }
        
        XCTAssertEqual(error.localizedDescription, localizedDescription, file: file, line: line)
        XCTAssertEqual((error as NSError).localizedFailure, failure, file: file, line: line)
    }
}

// Local Errors
extension AltTests
{
    func testToNSErrorBridging() async throws
    {
        for error in AltTests.allLocalErrors
        {
            let nsError = (error as NSError)
            
            XCTAssertEqual(nsError.localizedDescription, error.localizedDescription)
            XCTAssertEqual(nsError.localizedFailure, error.errorFailure)
            XCTAssertEqual(nsError.localizedFailureReason, error.errorFailureReason)
            XCTAssertEqual(nsError.localizedRecoverySuggestion, error.recoverySuggestion)
            
            if let provider = NSError.userInfoValueProvider(forDomain: OperationError.errorDomain),
               let debugDescription = provider(error, NSDebugDescriptionErrorKey) as? String
            {
                XCTAssertEqual(debugDescription, nsError.debugDescription)
            }
        }
    }
    
    func testToNSErrorAndBackBridging() async throws
    {
        for error in AltTests.allLocalErrors
        {
            let nsError = (error as NSError)
            let unbridgedError = try XCTUnwrap(nsError as? any ALTLocalizedError)
            
            XCTAssertEqual(unbridgedError.localizedDescription, error.localizedDescription)
            XCTAssertEqual(unbridgedError.errorFailure, error.errorFailure)
            XCTAssertEqual(unbridgedError.failureReason, error.errorFailureReason)
            XCTAssertEqual(unbridgedError.recoverySuggestion, error.recoverySuggestion)
            
            if let provider = NSError.userInfoValueProvider(forDomain: OperationError.errorDomain),
               let debugDescription = provider(error, NSDebugDescriptionErrorKey) as? String
            {
                let unbridgedDebugDescription = provider(unbridgedError, NSDebugDescriptionErrorKey) as? String
                XCTAssertEqual(debugDescription, unbridgedDebugDescription)
            }
        }
    }
    
    func testDefaultErrorDomain()
    {
        for error in VerificationError.testErrors
        {
            let expectedErrorDomain = "AltStore.VerificationError"
            XCTAssertEqual(error._domain, expectedErrorDomain)
            
            let nsError = (error as NSError)
            XCTAssertEqual(nsError.domain, expectedErrorDomain)
        }
    }
    
    func testCustomErrorDomain() async throws
    {
        for error in allTestErrors
        {
            XCTAssertEqual(error._domain, TestError.errorDomain)
            
            let nsError = (error as NSError)
            XCTAssertEqual(nsError.domain, TestError.errorDomain)
        }
    }
    
    func testLocalizedDescriptionProvider() async throws
    {
        for error in AltTests.allRealErrors
        {
            let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
            let expectedFailureReason = try XCTUnwrap((error as NSError).localizedFailureReason)
            
            if let localizedFailure = (error as NSError).localizedFailure
            {
                // Test localizedDescription == original localizedFailure + localizedFailureReason
                let expectedLocalizedDescription = localizedFailure + " " + expectedFailureReason
                XCTAssertEqual(error.localizedDescription, expectedLocalizedDescription)
            }
            else
            {
                // Test localizedDescription does not start with "The operation couldn't be completed."
                XCTAssert(!error.localizedDescription.starts(with: "The operation couldn’t be completed."), error.localizedDescription)
            }
            
            let expectedLocalizedDescription = String.testLocalizedFailure + " " + expectedFailureReason
            XCTAssertEqual(nsError.localizedDescription, expectedLocalizedDescription)
        }
    }
    
    func testWithLocalizedFailure() async throws
    {
        for error in AltTests.allRealErrors
        {
            let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
            
            let expectedFailureReason = try XCTUnwrap((error as NSError).localizedFailureReason)
            let expectedLocalizedDescription = String.testLocalizedFailure + " " + expectedFailureReason
            
            XCTAssertEqual(nsError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(nsError.localizedFailure, .testLocalizedFailure)
            
            ALTAssertErrorsEqual(nsError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        }
    }
        
    func testWithInitialLocalizedFailure() async throws
    {
        for error in OperationError.testErrors
        {
            var localizedError = OperationError(error, localizedFailure: .testLocalizedFailure)
            localizedError.sourceFile = error.sourceFile
            localizedError.sourceLine = error.sourceLine
            
            let nsError = localizedError as NSError
            
            let expectedLocalizedDescription = String.testLocalizedFailure + " " + error.errorFailureReason
            XCTAssertEqual(nsError.localizedDescription, expectedLocalizedDescription)
            
            XCTAssertEqual(localizedError.errorFailure, .testLocalizedFailure)
            XCTAssertEqual(nsError.localizedFailure, .testLocalizedFailure)
            
            // Test remainder
            ALTAssertErrorsEqual(nsError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        }
    }
    
    func testWithInitialLocalizedTitle() async throws
    {
        for error in OperationError.testErrors
        {
            var localizedError = OperationError(error, localizedTitle: .testLocalizedTitle)
            localizedError.sourceFile = error.sourceFile
            localizedError.sourceLine = error.sourceLine
            
            let nsError = localizedError as NSError
            XCTAssertEqual(nsError.localizedDescription, error.localizedDescription)
            
            XCTAssertEqual(localizedError.errorTitle, .testLocalizedTitle)
            XCTAssertEqual(nsError.localizedTitle, .testLocalizedTitle)
            
            // Test remainder
            ALTAssertErrorsEqual(nsError, error, ignoring: [NSLocalizedDescriptionKey, ALTLocalizedTitleErrorKey])
        }
    }

    func testWithLocalizedFailureAndBack() async throws
    {
        for error in AltTests.allLocalErrors
        {
            let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
            
            func test(_ unbridgedError: Error, against nsError: NSError)
            {
                let unbridgedNSError = (unbridgedError as NSError)
                
                let expectedLocalizedDescription = String.testLocalizedFailure + " " + error.errorFailureReason
                XCTAssertEqual(unbridgedError.localizedDescription, expectedLocalizedDescription)
                
                XCTAssertEqual(unbridgedNSError.localizedFailure, .testLocalizedFailure)
                
                // Test dynamic type matches original error type
                XCTAssert(type(of: unbridgedError) == type(of: error))
                
                // Test remainder
                ALTAssertErrorsEqual(unbridgedNSError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
            }
            
            do
            {
                throw nsError as NSError
            }
            catch let error as VerificationError
            {
                test(error, against: nsError)
            }
            catch let error as OperationError
            {
                test(error, against: nsError)
            }
            catch let error as ALTLocalizedError
            {
                // Make sure VerificationError and OperationError were caught by above handlers.
                XCTAssertNotEqual(error._domain, VerificationError.errorDomain)
                XCTAssertNotEqual(error._domain, OperationError.errorDomain)
                
                let unbridgedError = try self.unbridge(error as NSError, to: error)
                test(unbridgedError, against: nsError)
            }
        }
    }
    
    func testPatternMatchingErrorCode() async throws
    {
        do
        {
            // ALTLocalizedError
            throw OperationError.serverNotFound
        }
        catch ~OperationError.Code.serverNotFound
        {
            // Success
        }
        catch
        {
            XCTFail("Failed to catch error as OperationError.Code.serverNotFound: \(error)")
        }
        
        do
        {
            // ALTErrorEnum
            throw AuthenticationError(.noTeam)
        }
        catch ~AuthenticationErrorCode.noTeam
        {
            // Success
        }
        catch
        {
            XCTFail("Failed to catch error as AuthenticationErrorCode.noTeam: \(error)")
        }
    }
    
    func testWithLocalizedTitle() async throws
    {
        let localizedTitle = "AltTest Failed"

        for error in AltTests.allLocalErrors
        {
            let nsError = (error as NSError).withLocalizedTitle(localizedTitle)
            
            XCTAssertEqual(nsError.localizedTitle, localizedTitle)
            
            ALTAssertErrorsEqual(nsError, error, ignoring: [ALTLocalizedTitleErrorKey])
        }
    }
    
    func testWithLocalizedTitleAndBack() async throws
    {
        for error in AltTests.allLocalErrors
        {
            let nsError = (error as NSError).withLocalizedTitle(.testLocalizedTitle)
            
            let unbridgedError = try self.unbridge(nsError, to: error)
            let unbridgedNSError = (unbridgedError as NSError)
            
            XCTAssertEqual(unbridgedNSError.localizedTitle, .testLocalizedTitle)
            
            ALTAssertErrorsEqual(unbridgedNSError, error, ignoring: [ALTLocalizedTitleErrorKey])
        }
    }
    
    func testWithLocalizedTitleAndFailure() async throws
    {
        for error in AltTests.allRealErrors
        {
            var nsError = (error as NSError).withLocalizedTitle(.testLocalizedTitle)
            nsError = nsError.withLocalizedFailure(.testLocalizedFailure)
            
            XCTAssertEqual(nsError.localizedTitle, .testLocalizedTitle)
            XCTAssertEqual(nsError.localizedFailure, .testLocalizedFailure)
            
            let expectedLocalizedDescription = try String.testLocalizedFailure + " " + XCTUnwrap((error as NSError).localizedFailureReason)
            XCTAssertEqual(nsError.localizedDescription, expectedLocalizedDescription)
            
            // Test remainder
            ALTAssertErrorsEqual(nsError, error, ignoring: [NSLocalizedDescriptionKey, ALTLocalizedTitleErrorKey, NSLocalizedFailureErrorKey])
        }
    }
    
    func testSwiftErrorWithLocalizedFailure() async throws
    {
        enum MyError: Int, LocalizedError, CaseIterable
        {
            case strange
            case nothing
            
            var errorDescription: String? {
                switch self
                {
                case .strange: return "A strange error occured."
                case .nothing: return nil
                }
            }
            
            var recoverySuggestion: String? {
                return "Have you tried turning it off and on again?"
            }
        }
        
        for error in MyError.allCases
        {
            let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
            
            ALTAssertErrorsEqual(nsError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
            ALTAssertErrorFailureAndDescription(nsError, failure: .testLocalizedFailure, baseDescription: error.localizedDescription)
        }
    }
    
    func testNSErrorWithLocalizedFailure() async throws
    {
        let error = NSError(domain: .testDomain, code: 14, userInfo: [NSLocalizedDescriptionKey: String.testDescription])
        let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
        
        ALTAssertErrorsEqual(nsError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        ALTAssertErrorFailureAndDescription(nsError, failure: .testLocalizedFailure, baseDescription: .testDescription)
    }
    
    func testReceivingAltServerError() async throws
    {
        for error in ALTServerError.testErrors
        {
            let codableError = CodableError(error: error)
            let jsonData = try JSONEncoder().encode(codableError)
            
            let decodedError = try Foundation.JSONDecoder().decode(CodableError.self, from: jsonData)
            let receivedError = decodedError.error
            
            ALTAssertErrorsEqual(receivedError, error)
        }
    }
    
    func testReceivingAltServerErrorWithLocalizedFailure() async throws
    {
        for error in ALTServerError.testErrors
        {
            let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
            let altserverError = ALTServerError(nsError)
            
            let codableError = CodableError(error: altserverError)
            let jsonData = try JSONEncoder().encode(codableError)
            
            let decodedError = try Foundation.JSONDecoder().decode(CodableError.self, from: jsonData)
            let receivedError = decodedError.error
            let receivedNSError = receivedError as NSError
            
            let expectedLocalizedDescription = try String.testLocalizedFailure + " " + XCTUnwrap((error as NSError).localizedFailureReason)
            XCTAssertEqual(nsError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(receivedNSError.localizedFailure, .testLocalizedFailure)
            
            ALTAssertErrorsEqual(receivedError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        }
    }
    
    func testReceivingAltServerErrorWithLocalizedTitle() async throws
    {
        for error in ALTServerError.testErrors
        {
            let nsError = (error as NSError).withLocalizedTitle(.testLocalizedTitle)
            let receivedError = try self.send(nsError)
            
            XCTAssertEqual(receivedError.localizedTitle, .testLocalizedTitle)
            ALTAssertErrorsEqual(receivedError, error, ignoring: [ALTLocalizedTitleErrorKey])
        }
    }
    
    func testReceivingAltServerErrorThenAddingLocalizedFailure() async throws
    {
        for error in ALTServerError.testErrors
        {
            let receivedError = try self.send(error)
            let receivedNSError = (receivedError as NSError).withLocalizedFailure(.testLocalizedFailure)
            
            let expectedLocalizedDescription = try String.testLocalizedFailure + " " + XCTUnwrap((error as NSError).localizedFailureReason)
            XCTAssertEqual(receivedNSError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(receivedNSError.localizedFailure, .testLocalizedFailure)
            
            ALTAssertErrorsEqual(receivedNSError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        }
    }
    
    func testReceivingAltServerErrorThenAddingLocalizedTitle() async throws
    {
        for error in ALTServerError.testErrors
        {
            let receivedError = try self.send(error)
            let receivedNSError = (receivedError as NSError).withLocalizedTitle(.testLocalizedTitle)
            
            XCTAssertEqual(receivedNSError.localizedTitle, .testLocalizedTitle)
            
            ALTAssertErrorsEqual(receivedNSError, error, ignoring: [ALTLocalizedTitleErrorKey])
        }
    }
    
    func testReceivingAltServerErrorWithLocalizedFailureThenChangingLocalizedFailure() async throws
    {
        for error in ALTServerError.testErrors
        {
            let nsError = (error as NSError).withLocalizedFailure(.testOriginalLocalizedFailure)
            let receivedError = try self.send(nsError)
            let receivedNSError = (receivedError as NSError).withLocalizedFailure(.testLocalizedFailure)
            
            let expectedLocalizedDescription = try String.testLocalizedFailure + " " + XCTUnwrap(nsError.localizedFailureReason)
            XCTAssertEqual(receivedNSError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(receivedNSError.localizedFailure, .testLocalizedFailure)
            
            // Test that decoded error retains original localized failure.
            XCTAssertEqual((receivedError as NSError).localizedFailure, .testOriginalLocalizedFailure)
            
            ALTAssertErrorsEqual(receivedNSError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        }
    }
    
    func testReceivingAltServerErrorWithLocalizedFailureThenAddingLocalizedTitle() async throws
    {
        for error in ALTServerError.testErrors
        {
            let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
            let receivedError = try self.send(nsError)
            let receivedNSError = (receivedError as NSError).withLocalizedTitle(.testLocalizedTitle)
            
            let expectedLocalizedDescription = try String.testLocalizedFailure + " " + XCTUnwrap(nsError.localizedFailureReason)
            XCTAssertEqual(receivedNSError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(receivedNSError.localizedFailure, .testLocalizedFailure)
            XCTAssertEqual(receivedNSError.localizedTitle, .testLocalizedTitle)
            
            ALTAssertErrorsEqual(receivedNSError, error, ignoring: [NSLocalizedDescriptionKey, ALTLocalizedTitleErrorKey, NSLocalizedFailureErrorKey])
        }
    }
    
    func testReceivingNonAltServerSwiftError() async throws
    {
        for error in allTestErrors
        {
            let receivedError = try self.send(error)
            try ALTAssertUnderlyingErrorEqualsError(receivedError, error)
        }
    }
    
    func testReceivingNonAltServerSwiftErrorWithSourceLocation() async throws
    {
        let file = #fileID
        let line = #line as UInt
        
        let error = OperationError.unknown(file: file, line: line)
        let receivedError = try self.send(error)
        
        XCTAssertEqual(receivedError.userInfo[ALTSourceFileErrorKey] as? String, file)
        
        if let uint = receivedError.userInfo[ALTSourceLineErrorKey] as? UInt
        {
            XCTAssertEqual(uint, line)
        }
        else if let int = receivedError.userInfo[ALTSourceLineErrorKey] as? Int
        {
            XCTAssertEqual(int, Int(line))
        }
        
        try ALTAssertUnderlyingErrorEqualsError(receivedError, error)
    }
    
    func testReceivingNonAltServerSwiftErrorWithLocalizedFailure() async throws
    {
        for error in allTestErrors
        {
            let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
            let receivedError = try self.send(nsError)
            
            let expectedLocalizedDescription = try String.testLocalizedFailure + " " + XCTUnwrap(nsError.localizedFailureReason)
            XCTAssertEqual(receivedError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(receivedError.localizedFailure, .testLocalizedFailure)
            
            let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
            XCTAssertEqual(receivedUnderlyingError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(receivedUnderlyingError.localizedFailure, .testLocalizedFailure)
        }
    }
    
    func testReceivingNonAltServerSwiftErrorThenAddingLocalizedFailure() async throws
    {
        for error in allTestErrors
        {
            let receivedError = try self.send(error)
            let receivedNSError = (receivedError as NSError).withLocalizedFailure(.testLocalizedFailure)
            
            let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedNSError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
            XCTAssertEqual(receivedUnderlyingError.localizedDescription, error.errorFailureReason)
            XCTAssertNil(receivedUnderlyingError.localizedFailure)
            
            let expectedLocalizedDescription = try String.testLocalizedFailure + " " + XCTUnwrap((error as NSError).localizedFailureReason)
            XCTAssertEqual(receivedNSError.localizedDescription, expectedLocalizedDescription)
            XCTAssertEqual(receivedNSError.localizedFailure, .testLocalizedFailure)
        }
    }
    
    func testReceivingNonAltServerSwiftErrorThenAddingLocalizedTitle() async throws
    {
        for error in allTestErrors
        {
            let receivedError = try self.send(error)
            let receivedNSError = (receivedError as NSError).withLocalizedTitle(.testLocalizedTitle)
            
            XCTAssertNil(error.errorTitle)
            XCTAssertEqual(receivedNSError.localizedTitle, .testLocalizedTitle)
            
            let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedNSError, error, ignoring: [ALTLocalizedTitleErrorKey])
            XCTAssertNil(receivedUnderlyingError.localizedTitle)
        }
    }
    
    func testReceivingUnrecognizedNonAltServerSwiftError() async throws
    {
        enum MyError: Int, LocalizedError, CaseIterable
        {
            case strange
            case nothing
            
            var errorDescription: String? {
                switch self
                {
                case .strange: return "A strange error occured."
                case .nothing: return nil
                }
            }
            
            var recoverySuggestion: String? {
                return "Have you tried turning it off and on again?"
            }
        }
        
        for error in MyError.allCases
        {
            let receivedError = try self.send(error, clientProvider: [:])
            try ALTAssertUnderlyingErrorEqualsError(receivedError, error)
        }
    }
    
    func testReceivingUnrecognizedNonAltServerSwiftErrorThenAddingLocalizedFailure() async throws
    {
        enum MyError: Int, LocalizedError, CaseIterable
        {
            case strange
            case nothing
            
            var errorDescription: String? {
                switch self
                {
                case .strange: return "A strange error occured."
                case .nothing: return nil
                }
            }
            
            var recoverySuggestion: String? {
                return "Have you tried turning it off and on again?"
            }
        }
        
        for error in MyError.allCases
        {
            let receivedError = try self.send(error, clientProvider: [:])
            let receivedNSError = receivedError.withLocalizedFailure(.testLocalizedFailure)
            
            let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedNSError, error, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
            ALTAssertErrorFailureAndDescription(receivedNSError, failure: .testLocalizedFailure, baseDescription: error.localizedDescription)
            ALTAssertErrorFailureAndDescription(receivedUnderlyingError, failure: nil, baseDescription: error.localizedDescription)
        }
    }
    
    func testReceivingNonAltServerCocoaError() async throws
    {
        let error = CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: "~/Desktop/TestFile"])
        
        let receivedError = try self.send(error)
        try ALTAssertUnderlyingErrorEqualsError(receivedError, error)
    }
    
    func testReceivingNonAltServerCocoaErrorWithLocalizedFailure() async throws
    {
        let error = CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: "~/Desktop/TestFile"])
        let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
        
        let receivedError = try self.send(nsError)
        try ALTAssertUnderlyingErrorEqualsError(receivedError, nsError)
        
        // Description == .testLocalizedFailure + failureReason ?? description
        ALTAssertErrorFailureAndDescription(receivedError, failure: .testLocalizedFailure, baseDescription: nsError.localizedFailureReason ?? error.localizedDescription)
    }
    
    func testReceivingAltServerConnectionError() async throws
    {
        let error = ALTServerConnectionError(.deviceLocked, userInfo: [ALTDeviceNameErrorKey: "Riley's iPhone"])
        let nsError = error as NSError
        
        let receivedError = try self.send(nsError)
        let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, nsError, ignoring: [ALTUnderlyingErrorCodeErrorKey, NSLocalizedFailureErrorKey, NSLocalizedDescriptionKey])
        
        // Code == ALTServerError.connectionFailed
        XCTAssertEqual(receivedError.code, ALTServerError.connectionFailed.rawValue)
        
        // Underlying Code == ALTServerConnectionError.deviceLocked
        XCTAssertEqual(receivedUnderlyingError.code, ALTServerConnectionError.deviceLocked.rawValue)
        
        // Description == defaultFailure + error.localizedDescription
        let defaultFailure = try XCTUnwrap((ALTServerError(.connectionFailed) as NSError).localizedFailureReason)
        ALTAssertErrorFailureAndDescription(receivedError, failure: defaultFailure, baseDescription: error.localizedDescription)
        
        // Underlying Description = error.localizedDescription
        ALTAssertErrorFailureAndDescription(receivedUnderlyingError, failure: nil, baseDescription: error.localizedDescription)
    }
    
    func testReceivingAppleAPIError() async throws
    {
        let error = ALTAppleAPIError(.incorrectCredentials)
        let nsError = error as NSError
        
        let receivedError = try self.send(nsError, serverProvider: [NSDebugDescriptionErrorKey: .testDebugDescription])

        // Debug Description == .testDebugDescription
        XCTAssertEqual(receivedError.localizedDebugDescription, .testDebugDescription)
        
        let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, error, ignoring: [NSDebugDescriptionErrorKey])
        
        // Debug Description == .testDebugDescription
        XCTAssertEqual(receivedUnderlyingError.localizedDebugDescription, .testDebugDescription)
    }
    
    func testReceivingCodableError() async throws
    {
        let json = "{'name2': 'riley'}"
        
        struct Test: Decodable
        {
            var name: String
        }
        
        let rawData = json.data(using: .utf8)!
        let error: DecodingError
        
        do
        {
            _ = try Foundation.JSONDecoder().decode(Test.self, from: rawData)
            return
        }
        catch let decodingError as DecodingError
        {
            error = decodingError
        }
        catch
        {
            XCTFail("Only DecodingErrors should be thrown.")
            return
        }
        
        let nsError = error as NSError
        
        let receivedError = try self.send(nsError)
        
        // Code == ALTServerError.invalidRequest
        // Description == CocoaError.coderReadCorrupt.localizedDescription
        XCTAssertEqual(receivedError.code, ALTServerError.invalidRequest.rawValue)
        XCTAssertEqual(receivedError.localizedDescription, CocoaError(.coderReadCorrupt).localizedDescription)
        
        let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, nsError, ignoring: [ALTUnderlyingErrorCodeErrorKey, NSLocalizedDescriptionKey])
        
        // Underlying Code == CocoaError.coderReadCorrupt
        // Underlying Description == CocoaError.coderReadCorrupt.localizedDescription
        XCTAssertEqual(receivedUnderlyingError.code, CocoaError.coderReadCorrupt.rawValue)
        XCTAssertEqual(receivedUnderlyingError.localizedDescription, CocoaError(.coderReadCorrupt).localizedDescription)
    }
    
    func testReceivingUnrecognizedAppleAPIError() async throws
    {
        let error = ALTAppleAPIError(.init(rawValue: -27)!) /* Alien Invasion */
        let cachedError = error.serialized(provider: .unrecognizedProvider)
        
        let receivedError = try self.send(error, serverProvider: .unrecognizedProvider)
        
        // Description == .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(receivedError, failure: nil, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(receivedError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
        
        let underlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, cachedError)
        
        // Underlying Description == .testUnrecognizedFailureReason
        // Underlying Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(underlyingError, failure: nil, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(underlyingError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
    }
    
    func testReceivingUnrecognizedAppleAPIErrorWithLocalizedFailure() async throws
    {
        let error = ALTAppleAPIError(.init(rawValue: -27)!) /* Alien Invasion */
        let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
        
        let receivedError = try self.send(nsError, serverProvider: [
            NSLocalizedFailureReasonErrorKey: .testUnrecognizedFailureReason,
            NSLocalizedRecoverySuggestionErrorKey: .testUnrecognizedRecoverySuggestion
        ])
        
        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(receivedError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(receivedError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
        
        let underlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, nsError, ignoring: [NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey, NSLocalizedDescriptionKey])
        
        // Underlying Failure == .testLocalizedFailure
        // Underlying Description == Failure + .testUnrecognizedFailureReason
        // Underlying Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(underlyingError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(underlyingError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
    }
    
    func testReceivingUnrecognizedAppleAPIErrorThenAddingLocalizedFailure() async throws
    {
        let error = ALTAppleAPIError(.init(rawValue: -27)!) /* Alien Invasion */
        
        let receivedError = try self.send(error, serverProvider: [
            NSLocalizedFailureReasonErrorKey: .testUnrecognizedFailureReason,
            NSLocalizedRecoverySuggestionErrorKey: .testUnrecognizedRecoverySuggestion
        ])
        let receivedNSError = (receivedError as NSError).withLocalizedFailure(.testLocalizedFailure)
        
        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(receivedNSError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(receivedNSError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
        
        let underlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedNSError, error, ignoring: [NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey, NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        
        // Underlying Failure == nil
        // Underlying Description == .testUnrecognizedFailureReason
        // Underlying Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(underlyingError, failure: nil, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(underlyingError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
    }
    
    func testReceivingUnrecognizedAppleAPIErrorWithLocalizedFailureThenChangingLocalizedFailure() async throws
    {
        let error = ALTAppleAPIError(.init(rawValue: -27)!) /* Alien Invasion */
        let nsError = (error as NSError).withLocalizedFailure(.testOriginalLocalizedFailure)
        
        let receivedError = try self.send(nsError, serverProvider: [
            NSLocalizedFailureReasonErrorKey: .testUnrecognizedFailureReason,
            NSLocalizedRecoverySuggestionErrorKey: .testUnrecognizedRecoverySuggestion
        ])
        
        // Failure == .testOriginalLocalizedFailure
        XCTAssertEqual(receivedError.localizedFailure, .testOriginalLocalizedFailure)
        
        let receivedNSError = (receivedError as NSError).withLocalizedFailure(.testLocalizedFailure)
        
        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(receivedNSError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(receivedNSError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
        
        let underlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedNSError, nsError, ignoring: [NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey, NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
        
        // Underlying Failure == .testOriginalLocalizedFailure
        // Underlying Description == Underlying Failure + .testUnrecognizedFailureReason
        // Underlying Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(underlyingError, failure: .testOriginalLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(underlyingError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
    }
    
    func testReceivingUnrecognizedObjCErrorsWithLocalizedFailureThenChangingLocalizedFailure() async throws
    {
        // User Info = nil
        var nsErrorWithNoUserInfo = NSError(domain: .testDomain, code: 14)
        nsErrorWithNoUserInfo = nsErrorWithNoUserInfo.withLocalizedFailure(.testOriginalLocalizedFailure)
        
        // User Info = Failure Reason
        var nsErrorWithUserInfoFailureReason = NSError(domain: .testDomain, code: 14, userInfo: [
            NSLocalizedFailureReasonErrorKey: String.testUnrecognizedFailureReason
        ])
        nsErrorWithUserInfoFailureReason = nsErrorWithUserInfoFailureReason.withLocalizedFailure(.testOriginalLocalizedFailure)
        
        // User Info = Description
        var nsErrorWithUserInfoDescription = NSError(domain: .testDomain, code: 14, userInfo: [
            NSLocalizedDescriptionKey: String.testDebugDescription
        ])
        nsErrorWithUserInfoDescription = nsErrorWithUserInfoDescription.withLocalizedFailure(.testOriginalLocalizedFailure)
        
        // User Info = Failure
        let nsErrorWithUserInfoFailure = NSError(domain: .testDomain, code: 14, userInfo: [
            NSLocalizedFailureErrorKey: String.testOriginalLocalizedFailure
        ])
        
        // User Info = Failure, Failure Reason
        let nsErrorWithUserInfoFailureAndFailureReason = NSError(domain: .testDomain, code: 14, userInfo: [
            NSLocalizedFailureErrorKey: String.testOriginalLocalizedFailure,
            NSLocalizedFailureReasonErrorKey: String.testUnrecognizedFailureReason
        ])
                
        // User Info = Failure, Description
        let nsErrorWithUserInfoFailureAndDescription = NSError(domain: .testDomain, code: 14, userInfo: [
            NSLocalizedFailureErrorKey: String.testOriginalLocalizedFailure,
            NSLocalizedDescriptionKey: String.testDebugDescription
        ])
        
        let errors = [nsErrorWithNoUserInfo, nsErrorWithUserInfoFailureReason, nsErrorWithUserInfoDescription, nsErrorWithUserInfoFailure, nsErrorWithUserInfoFailureAndFailureReason, nsErrorWithUserInfoFailureAndDescription]
        for nsError in [errors[0]]
        {
            let provider = [NSLocalizedFailureReasonErrorKey: String.testUnrecognizedFailureReason]
            
            // Use provider only if user info doesn't contain failure reason or localized description.
            let serverProvider = (nsError.userInfo.keys.contains(NSLocalizedFailureReasonErrorKey) || nsError.userInfo.keys.contains(NSLocalizedDescriptionKey)) ? nil : provider
            let baseDescription = serverProvider?[NSLocalizedFailureReasonErrorKey] ?? nsError.localizedFailureReason ?? .testDebugDescription
            
            let receivedError = try self.send(nsError, serverProvider: serverProvider)
            
            // Failure == .testOriginalLocalizedFailure
            XCTAssertEqual(receivedError.localizedFailure, .testOriginalLocalizedFailure)
            
            let receivedNSError = (receivedError as NSError).withLocalizedFailure(.testLocalizedFailure)
                        
            // Failure == .testLocalizedFailure
            // Description == Failure + baseDescription
            ALTAssertErrorFailureAndDescription(receivedNSError, failure: .testLocalizedFailure, baseDescription: baseDescription)
            
            let underlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedNSError, nsError, ignoring: [NSLocalizedFailureReasonErrorKey, NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey])
            
            // Underlying Failure == .testOriginalLocalizedFailure
            // Underlying Description == Underlying Failure + baseDescription
            ALTAssertErrorFailureAndDescription(underlyingError, failure: .testOriginalLocalizedFailure, baseDescription: serverProvider?[NSLocalizedFailureReasonErrorKey] ?? nsError.localizedFailureReason ?? .testDebugDescription)
        }
    }
}

extension AltTests
{
    func testReceivingUnrecognizedAltServerError() async throws
    {
        let error = ALTServerError(.init(rawValue: -27)!) /* Alien Invasion */
        
        let receivedError = try self.send(error, serverProvider: [
            NSLocalizedFailureReasonErrorKey: .testUnrecognizedFailureReason,
            NSLocalizedRecoverySuggestionErrorKey: .testUnrecognizedRecoverySuggestion
        ])
        
        // Description == .testUnrecognizedFailureReason
        // Failure Reason == .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        XCTAssertEqual(receivedError.localizedFailureReason, .testUnrecognizedFailureReason)
        XCTAssertEqual(receivedError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
        ALTAssertErrorFailureAndDescription(receivedError, failure: nil, baseDescription: .testUnrecognizedFailureReason)
        ALTAssertErrorsEqual(receivedError, error, ignoring: [NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey, NSLocalizedDescriptionKey])
    }
    
    func testReceivingUnrecognizedAltServerErrorWithLocalizedFailure() async throws
    {
        let error = ALTServerError(.init(rawValue: -27)!) /* Alien Invasion */
        let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
        
        let receivedError = try self.send(nsError, serverProvider: [
            NSLocalizedFailureReasonErrorKey: .testUnrecognizedFailureReason,
            NSLocalizedRecoverySuggestionErrorKey: .testUnrecognizedRecoverySuggestion
        ])
        
        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        // Failure Reason == .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorFailureAndDescription(receivedError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        XCTAssertEqual(receivedError.localizedFailureReason, .testUnrecognizedFailureReason)
        XCTAssertEqual(receivedError.localizedRecoverySuggestion, .testUnrecognizedRecoverySuggestion)
        ALTAssertErrorsEqual(receivedError, nsError, ignoring: [NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey, NSLocalizedDescriptionKey])
    }
    
    func testReceivingUnrecognizedAltServerErrorWithLocalizedTitle() async throws
    {
        let error = ALTServerError(.init(rawValue: -27)!) /* Alien Invasion */
        let nsError = (error as NSError).withLocalizedTitle(.testLocalizedTitle)
        let referenceError = nsError.serialized(provider: .unrecognizedProvider)
        
        let receivedError = try self.send(nsError, serverProvider: .unrecognizedProvider)
        
        // Title == .testLocalizedTitle
        XCTAssertEqual(receivedError.localizedTitle, .testLocalizedTitle)
        
        ALTAssertErrorsEqual(receivedError, referenceError)
    }
    
    func testReceivingUnrecognizedAltServerErrorThenAddingLocalizedFailure() async throws
    {
        let error = ALTServerError(.init(rawValue: -27)!) /* Alien Invasion */
        let serializedError = (error as NSError).serialized(provider: .unrecognizedProvider)
        
        let receivedError = try self.send(error, serverProvider: .unrecognizedProvider)
        
        // Failure == nil
        XCTAssertEqual(receivedError.localizedFailure, nil)
        
        let receivedNSError = receivedError.withLocalizedFailure(.testLocalizedFailure)
        
        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        ALTAssertErrorFailureAndDescription(receivedNSError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        ALTAssertErrorsEqual(receivedNSError, serializedError, ignoring: [NSLocalizedFailureErrorKey, NSLocalizedDescriptionKey])
    }
    
    func testReceivingUnrecognizedAltServerErrorThenAddingLocalizedTitle() async throws
    {
        let error = ALTServerError(.init(rawValue: -27)!) /* Alien Invasion */
        let serializedError = error.serialized(provider: .unrecognizedProvider)
        
        let receivedError = try self.send(error, serverProvider: .unrecognizedProvider)
        
        // Title == nil
        XCTAssertEqual(receivedError.localizedTitle, nil)
        
        let receivedNSError = receivedError.withLocalizedTitle(.testLocalizedTitle)
        
        // Title == .testLocalizedTitle
        ALTAssertErrorsEqual(receivedNSError, serializedError, ignoring: [ALTLocalizedTitleErrorKey])
    }
    
    func testReceivingUnrecognizedAltServerErrorWithLocalizedFailureThenChangingLocalizedFailure() async throws
    {
        let error = ALTServerError(.init(rawValue: -27)!) /* Alien Invasion */
        let nsError = (error as NSError).withLocalizedFailure(.testOriginalLocalizedFailure)
        let serializedError = nsError.serialized(provider: .unrecognizedProvider)
        
        let receivedError = try self.send(nsError, serverProvider: .unrecognizedProvider)
        
        // Failure == .testOriginalLocalizedFailure
        XCTAssertEqual(receivedError.localizedFailure, .testOriginalLocalizedFailure)
        
        let receivedNSError = receivedError.withLocalizedFailure(.testLocalizedFailure)
        
        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        ALTAssertErrorFailureAndDescription(receivedNSError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        ALTAssertErrorsEqual(receivedNSError, serializedError, ignoring: [NSLocalizedFailureErrorKey, NSLocalizedDescriptionKey])
    }
}

extension AltTests
{
    func testReceivingAltServerErrorWithDifferentErrorMessages() async throws
    {
        let error = ALTServerError(.pluginNotFound)
        let serializedError = error.serialized(provider: .unrecognizedProvider)
        
        let receivedError = try self.send(error, serverProvider: .unrecognizedProvider)
        
        // Description == error.localizedDescription (not .testUnrecognizedFailureReason)
        // Failure Reason == error.localizedFailureReason (not .testUnrecognizedFailureReason)
        // Recovery Suggestion == error.recoverySuggestion (not .testUnrecognizedRecoverySuggestion)
        XCTAssertEqual(receivedError.localizedDescription, error.localizedDescription)
        XCTAssertEqual(receivedError.localizedFailureReason, (error as NSError).localizedFailureReason)
        XCTAssertEqual(receivedError.localizedRecoverySuggestion, (error as NSError).localizedRecoverySuggestion)
        ALTAssertErrorsEqual(receivedError, serializedError, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey])
    }
    
    func testReceivingAltServerErrorWithLocalizedFailureAndDifferentErrorMessages() async throws
    {
        let error = ALTServerError(.pluginNotFound)
        let nsError = (error as NSError).withLocalizedFailure(.testLocalizedFailure)
        let serializedError = nsError.serialized(provider: .unrecognizedProvider)
        
        let receivedError = try self.send(nsError, serverProvider: .unrecognizedProvider)
        
        // Failure == .testLocalizedFailure
        // Description == Failure + error.localizedFailureReason (not .testUnrecognizedFailureReason)
        // Failure Reason == error.localizedFailureReason (not .testUnrecognizedFailureReason)
        // Recovery Suggestion == error.recoverySuggestion (not .testUnrecognizedRecoverySuggestion)
        ALTAssertErrorFailureAndDescription(receivedError, failure: .testLocalizedFailure, baseDescription: try XCTUnwrap(nsError.localizedFailureReason))
        XCTAssertEqual(receivedError.localizedFailureReason, (error as NSError).localizedFailureReason)
        XCTAssertEqual(receivedError.localizedRecoverySuggestion, (error as NSError).localizedRecoverySuggestion)
        ALTAssertErrorsEqual(receivedError, serializedError, ignoring: [NSLocalizedDescriptionKey, NSLocalizedFailureErrorKey, NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey])
    }
}

extension AltTests
{
    func testReceivingUnrecognizedAltServerErrorThenAddingLocalizedFailureBeforeSerializing() async throws
    {
        let error = ALTServerError(.init(rawValue: -27)!) /* Alien Invasion */
        
        let receivedError = try self.send(error, serverProvider: .unrecognizedProvider)
        let receivedNSError = receivedError.withLocalizedFailure(.testLocalizedFailure)
        
        let serializedError = receivedNSError.sanitizedForSerialization()
        
        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        ALTAssertErrorFailureAndDescription(serializedError, failure: .testLocalizedFailure, baseDescription: .testUnrecognizedFailureReason)
        
        // Failure Reason == .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorsEqual(serializedError, receivedNSError, ignoring: [])
    }
    
    func testAddingLocalizedFailureThenSerializing() async throws
    {
        let error = CocoaError(.fileReadNoSuchFile, userInfo: [NSURLErrorKey: URL(fileURLWithPath: "~/Users/rileytestut/delta")])
        let nsError = (error as NSError).withLocalizedFailure(.testOriginalLocalizedFailure)

        let receivedError = try self.send(nsError)
        let receivedNSError = receivedError.withLocalizedFailure(.testLocalizedFailure)

        let serializedError = receivedNSError.sanitizedForSerialization()

        // Failure == .testLocalizedFailure
        // Description == Failure + .testUnrecognizedFailureReason
        ALTAssertErrorFailureAndDescription(serializedError, failure: .testLocalizedFailure, baseDescription: try XCTUnwrap(nsError.localizedFailureReason))

        // Failure Reason == .testUnrecognizedFailureReason
        // Recovery Suggestion == .testUnrecognizedRecoverySuggestion
        ALTAssertErrorsEqual(serializedError, receivedNSError, ignoring: [])
    }
    
    func testSerializingUserInfoValues() async throws
    {
        let userInfo = [
            "RSTString": "test",
            "RSTNumber": -1 as Int,
            "RSTUnsignedNumber": 2 as UInt,
            // "RSTURL": URL(string: "https://rileytestut.com")!, // URLs get converted to Strings
            "RSTArray": [1, "test"],
            "RSTDictionary": ["key1": 11, "key2": "string"]
        ] as [String: Any]
                
        let error = NSError(domain: .testDomain, code: 17, userInfo: userInfo)

        let receivedError = try self.send(error)
        let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, error)
        
        let receivedUserInfo = receivedUnderlyingError.userInfo.filter { $0.key != NSLocalizedDescriptionKey } // Remove added NSLocalizedDescription value for unrecognized error.

//        let receivedURLString = try XCTUnwrap(receivedUserInfo["RSTURL"] as? String)
//        receivedUserInfo["RSTURL"] = URL(string: receivedURLString)
        
        XCTAssertEqual(receivedUserInfo as NSDictionary, userInfo as NSDictionary)
    }
    
    func testSerializingNonCodableUserInfoValues() async throws
    {
        struct MyStruct
        {
            var property = 1
        }
        
        let userInfo = [
            "MyStruct": MyStruct(),
            "RSTDictionary": ["key": MyStruct()],
            "RSTArray": [MyStruct()],
        ] as [String : Any]
                
        let error = NSError(domain: .testDomain, code: 17, userInfo: userInfo)

        let receivedError = try self.send(error)
        let receivedUnderlyingError = try ALTAssertUnderlyingErrorEqualsError(receivedError, error, ignoreExtraUserInfoValues: true)
        
        XCTAssertNil(receivedUnderlyingError.userInfo["MyStruct"])
        XCTAssertFalse(receivedUnderlyingError.userInfo.keys.contains("MyStruct"))
        
        let dictionary = try XCTUnwrap(receivedUnderlyingError.userInfo["RSTDictionary"] as? [String: Any])
        XCTAssertNil(dictionary["key"])
        XCTAssertFalse(dictionary.keys.contains("key"))
        
        let array = try XCTUnwrap(receivedUnderlyingError.userInfo["RSTArray"] as? [Any])
        XCTAssert(array.isEmpty)
    }
}
