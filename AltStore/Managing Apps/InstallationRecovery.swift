import Foundation
import CoreData
import AltStoreCore
import Roxas

struct InstallationReceipt: Codable
{
    private static let bundleCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
    struct ExtensionRecord: Codable
    {
        let name: String
        let bundleIdentifier: String
        let resignedBundleIdentifier: String
        let version: String
        let expirationDate: Date
    }

    var identifier = UUID()
    var formatVersion = 1
    let name: String
    let bundleIdentifier: String
    let resignedBundleIdentifier: String
    let version: String
    let buildVersion: String
    let expirationDate: Date
    let date: Date
    let certificateSerialNumber: String?
    let teamIdentifier: String?
    let isActive: Bool
    let extensions: [ExtensionRecord]

    init(app: InstalledApp)
    {
        name = app.name
        bundleIdentifier = app.bundleIdentifier
        resignedBundleIdentifier = app.resignedBundleIdentifier
        version = app.version
        buildVersion = app.buildVersion
        expirationDate = app.expirationDate
        date = app.refreshedDate
        certificateSerialNumber = app.certificateSerialNumber
        teamIdentifier = app.team?.identifier
        isActive = app.isActive
        extensions = app.appExtensions.map {
            ExtensionRecord(name: $0.name, bundleIdentifier: $0.bundleIdentifier,
                            resignedBundleIdentifier: $0.resignedBundleIdentifier,
                            version: $0.version, expirationDate: $0.expirationDate)
        }
    }

    static func isValidBundleIdentifier(_ identifier: String) -> Bool
    {
        return !identifier.isEmpty && identifier.utf8.count <= 255 && identifier != "." && identifier != ".."
            && identifier.unicodeScalars.allSatisfy { bundleCharacters.contains($0) }
    }

    var isValid: Bool {
        formatVersion == 1 && Self.isValidBundleIdentifier(bundleIdentifier)
            && Self.isValidBundleIdentifier(resignedBundleIdentifier) && !name.isEmpty
            && extensions.count <= 128 && extensions.allSatisfy {
                Self.isValidBundleIdentifier($0.bundleIdentifier) && Self.isValidBundleIdentifier($0.resignedBundleIdentifier)
            }
    }

    func restore(in context: NSManagedObjectContext) -> InstalledApp
    {
        let app = NSEntityDescription.insertNewObject(forEntityName: "InstalledApp", into: context) as! InstalledApp
        app.name = name
        app.bundleIdentifier = bundleIdentifier
        app.resignedBundleIdentifier = resignedBundleIdentifier
        app.version = version
        app.buildVersion = buildVersion
        app.expirationDate = expirationDate
        app.installedDate = date
        app.refreshedDate = date
        app.certificateSerialNumber = certificateSerialNumber
        app.isActive = isActive
        // Presence proves installation, not that the interrupted update reached this exact version.
        app.needsResign = true
        app.hasAlternateIcon = false
        if let teamIdentifier {
            app.team = Team.first(satisfying: NSPredicate(format: "%K == %@", #keyPath(Team.identifier), teamIdentifier), in: context)
        }
        app.storeApp = StoreApp.first(satisfying: NSPredicate(format: "%K == %@", #keyPath(StoreApp.bundleIdentifier), bundleIdentifier), in: context)
        app.appExtensions = Set(extensions.map { record in
            let ext = NSEntityDescription.insertNewObject(forEntityName: "InstalledExtension", into: context) as! InstalledExtension
            ext.name = record.name
            ext.bundleIdentifier = record.bundleIdentifier
            ext.resignedBundleIdentifier = record.resignedBundleIdentifier
            ext.version = record.version
            ext.expirationDate = record.expirationDate
            ext.installedDate = date
            ext.refreshedDate = date
            return ext
        })
        return app
    }
}

final class InstallationReceiptStore
{
    struct ReconciliationResult
    {
        let recoveredCount: Int
        let pendingCount: Int
    }
    static let shared = InstallationReceiptStore(rootURL: InstalledApp.appsDirectoryURL)
    static let filename = "InstallationReceipt.json"
    private let rootURL: URL
    private let lock = NSRecursiveLock()

    init(rootURL: URL) { self.rootURL = rootURL }

    @discardableResult
    func stage(_ app: InstalledApp) throws -> UUID
    {
        let receipt = InstallationReceipt(app: app)
        try write(receipt)
        return receipt.identifier
    }

    func write(_ receipt: InstallationReceipt) throws
    {
        lock.lock()
        defer { lock.unlock() }
        guard receipt.isValid else { throw CocoaError(.fileWriteInvalidFileName) }
        let directory = rootURL.appendingPathComponent(receipt.bundleIdentifier, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard try directory.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        let data = try Foundation.JSONEncoder().encode(receipt)
        guard data.count <= 65536 else { throw CocoaError(.fileWriteOutOfSpace) }
        try data.write(to: directory.appendingPathComponent(Self.filename), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func remove(bundleIdentifier: String, matching identifier: UUID) throws
    {
        lock.lock()
        defer { lock.unlock() }
        guard InstallationReceipt.isValidBundleIdentifier(bundleIdentifier) else { return }
        let directory = rootURL.appendingPathComponent(bundleIdentifier, isDirectory: true)
        guard let receipt = load(in: directory), receipt.identifier == identifier else { return }
        try FileManager.default.removeItem(at: directory.appendingPathComponent(Self.filename))
    }

    func load(in directory: URL) -> InstallationReceipt?
    {
        let url = directory.appendingPathComponent(Self.filename)
        guard let directoryValues = try? directory.resourceValues(forKeys: [.isSymbolicLinkKey]), directoryValues.isSymbolicLink != true,
              let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isSymbolicLinkKey]),
              values.isSymbolicLink != true, let size = values.fileSize, size <= 65536,
              let data = try? Data(contentsOf: url), let receipt = try? Foundation.JSONDecoder().decode(InstallationReceipt.self, from: data),
              receipt.isValid, receipt.bundleIdentifier == directory.lastPathComponent else { return nil }
        return receipt
    }

    // Run on the supplied context's queue. Do not create installed records from App IDs alone.
    @discardableResult
    func recover(in context: NSManagedObjectContext, isInstalled: (String) -> Bool) throws -> Int
    {
        return try reconcile(in: context, isInstalled: isInstalled).recoveredCount
    }

    func reconcile(in context: NSManagedObjectContext, isInstalled: (String) -> Bool,
                   isManaging: (String) -> Bool = { _ in false }) throws -> ReconciliationResult
    {
        lock.lock()
        defer { lock.unlock() }
        let existing = Set(InstalledApp.all(in: context).map(\.bundleIdentifier))
        let directories = try FileManager.default.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        var recovered: [InstallationReceipt] = []
        var pendingCount = 0
        for directory in directories
        {
            guard let receipt = load(in: directory), !existing.contains(receipt.bundleIdentifier) else { continue }
            pendingCount += 1
            guard !isManaging(receipt.bundleIdentifier),
                  FileManager.default.fileExists(atPath: directory.appendingPathComponent("App.app").path),
                  isInstalled(receipt.resignedBundleIdentifier) else { continue }
            // A producer may have saved since this scan's initial fetch.
            if InstalledApp.first(satisfying: NSPredicate(format: "%K == %@", #keyPath(InstalledApp.bundleIdentifier), receipt.bundleIdentifier), in: context) != nil {
                pendingCount -= 1
                continue
            }
            _ = receipt.restore(in: context)
            recovered.append(receipt)
        }
        do { if !recovered.isEmpty { try context.save() } }
        catch { context.rollback(); throw error }
        for receipt in recovered { try remove(bundleIdentifier: receipt.bundleIdentifier, matching: receipt.identifier) }
        return ReconciliationResult(recoveredCount: recovered.count, pendingCount: pendingCount - recovered.count)
    }

    static func shouldRemoveCache(hasRecord: Bool, hasCachedApp: Bool, hasReceipt: Bool, isManaging: Bool) -> Bool
    {
        return !hasRecord && !hasCachedApp && !hasReceipt && !isManaging
    }
}

// Main-thread, coalesced local checks. Delayed registration must not require another relaunch.
final class InstallationRecoveryCoordinator
{
    typealias Schedule = (TimeInterval, @escaping () -> Void) -> (() -> Void)
    private let delays: [TimeInterval] = [1, 2, 5, 10, 20]
    private let canRun: () -> Bool
    private let attempt: (@escaping (Bool) -> Void) -> Void
    private let schedule: Schedule
    private var generation: UUID?
    private var cancelScheduled: (() -> Void)?
    private var isRunningAttempt = false
    private var resumeWhenFinished = false

    init(canRun: @escaping () -> Bool, attempt: @escaping (@escaping (Bool) -> Void) -> Void,
         schedule: @escaping Schedule = { delay, action in
             let work = DispatchWorkItem(block: action)
             DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
             return { work.cancel() }
         })
    {
        self.canRun = canRun
        self.attempt = attempt
        self.schedule = schedule
    }

    func start()
    {
        precondition(Thread.isMainThread)
        guard generation == nil, canRun() else { return }
        guard !isRunningAttempt else { resumeWhenFinished = true; return }
        let token = UUID()
        generation = token
        run(token: token, index: 0)
    }

    func stop()
    {
        precondition(Thread.isMainThread)
        generation = nil
        resumeWhenFinished = false
        cancelScheduled?()
        cancelScheduled = nil
    }

    deinit { cancelScheduled?() }

    private func run(token: UUID, index: Int)
    {
        guard generation == token else { return }
        guard canRun() else { stop(); return }
        cancelScheduled = nil
        isRunningAttempt = true
        attempt { [weak self] hasPending in
            guard let self else { return }
            precondition(Thread.isMainThread)
            self.isRunningAttempt = false
            guard self.generation == token else {
                if self.resumeWhenFinished { self.resumeWhenFinished = false; self.start() }
                return
            }
            guard hasPending, self.canRun(), index < self.delays.count else { self.stop(); return }
            self.cancelScheduled = self.schedule(self.delays[index]) { [weak self] in
                self?.run(token: token, index: index + 1)
            }
        }
    }
}
