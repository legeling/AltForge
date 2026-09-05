//
//  InstallAppOperation.swift
//  AltStore
//
//  Created by Riley Testut on 6/19/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation
import Network

import AltStoreCore
import AltSign
import Roxas

@objc(InstallAppOperation)
class InstallAppOperation: ResultOperation<InstalledApp>, @unchecked Sendable
{
    let context: InstallAppOperationContext
    
    private var didCleanUp = false
    private var receiptIdentifier: UUID?
    private let completionLock = NSLock()
    private var didFinish = false
    private var responseTimer: DispatchSourceTimer?

    override func cancel()
    {
        super.cancel()
        if self.isExecuting {
            self.finish(.failure(OperationError.cancelled))
            self.context.installationConnection?.connection.disconnect()
        }
    }

    private func awaitServerResponse()
    {
        self.completionLock.lock()
        defer { self.completionLock.unlock() }
        guard !self.didFinish else { return }
        if let timer = self.responseTimer { timer.schedule(deadline: .now() + 180); return }
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + 180)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.finish(.failure(OperationError.timedOut))
            self.context.installationConnection?.connection.disconnect()
        }
        self.responseTimer = timer
        timer.resume()
    }
    
    init(context: InstallAppOperationContext)
    {
        self.context = context
        
        super.init()
        
        self.progress.totalUnitCount = 100
    }
    
    override func main()
    {
        super.main()
        
        if let error = self.context.error
        {
            self.finish(.failure(error))
            return
        }
        
        guard
            let certificate = self.context.certificate,
            let resignedApp = self.context.resignedApp,
            let connection = self.context.installationConnection
        else { return self.finish(.failure(OperationError.invalidParameters)) }

        self.context.recordDiagnostic(.installingApp, detail: connection.server.connectionType.localizedDiagnosticName)
        
        Logger.sideload.notice("Installing resigned app \(resignedApp.bundleIdentifier, privacy: .public)...")
        
        @Managed var appVersion = self.context.appVersion
        let storeBuildVersion = $appVersion.buildVersion
        
        let backgroundContext = DatabaseManager.shared.persistentContainer.newBackgroundContext()
        backgroundContext.perform {
            guard !self.isCancelled else { self.finish(.failure(OperationError.cancelled)); return }
            
            /* App */
            let installedApp: InstalledApp
            
            // Fetch + update rather than insert + resolve merge conflicts to prevent potential context-level conflicts.
            if let app = InstalledApp.first(satisfying: NSPredicate(format: "%K == %@", #keyPath(InstalledApp.bundleIdentifier), self.context.bundleIdentifier), in: backgroundContext)
            {
                installedApp = app
            }
            else
            {
                installedApp = InstalledApp(resignedApp: resignedApp,
                                            originalBundleIdentifier: self.context.bundleIdentifier,
                                            certificateSerialNumber: certificate.serialNumber,
                                            storeBuildVersion: storeBuildVersion,
                                            context: backgroundContext)
            }
            
            installedApp.update(resignedApp: resignedApp, certificateSerialNumber: certificate.serialNumber, storeBuildVersion: storeBuildVersion)
            installedApp.needsResign = false
            
            if let team = DatabaseManager.shared.activeTeam(in: backgroundContext)
            {
                installedApp.team = team
            }
            
            /* App Extensions */
            var installedExtensions = Set<InstalledExtension>()
            
            if
                let bundle = Bundle(url: resignedApp.fileURL),
                let directory = bundle.builtInPlugInsURL,
                let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
            {
                for case let fileURL as URL in enumerator
                {
                    guard let appExtensionBundle = Bundle(url: fileURL) else { continue }
                    guard let appExtension = ALTApplication(fileURL: appExtensionBundle.bundleURL) else { continue }
                    
                    let parentBundleID = self.context.bundleIdentifier
                    let resignedParentBundleID = resignedApp.bundleIdentifier
                    
                    let resignedBundleID = appExtension.bundleIdentifier
                    let originalBundleID = resignedBundleID.replacingOccurrences(of: resignedParentBundleID, with: parentBundleID)
                    
                    let installedExtension: InstalledExtension
                    
                    if let appExtension = installedApp.appExtensions.first(where: { $0.bundleIdentifier == originalBundleID })
                    {
                        installedExtension = appExtension
                    }
                    else
                    {
                        installedExtension = InstalledExtension(resignedAppExtension: appExtension, originalBundleIdentifier: originalBundleID, context: backgroundContext)
                    }
                    
                    installedExtension.update(resignedAppExtension: appExtension)
                    
                    installedExtensions.insert(installedExtension)
                }
            }
            
            installedApp.appExtensions = installedExtensions
            
            var activeProfiles: Set<String>?
            if let sideloadedAppsLimit = UserDefaults.standard.activeAppsLimit
            {
                // When installing these new profiles, AltServer will remove all non-active profiles to ensure we remain under limit.
                
                let fetchRequest = InstalledApp.activeAppsFetchRequest()
                fetchRequest.includesPendingChanges = false
                
                var activeApps = InstalledApp.fetch(fetchRequest, in: backgroundContext)
                if !activeApps.contains(installedApp)
                {
                    let activeAppsCount = activeApps.map { $0.requiredActiveSlots }.reduce(0, +)
                    
                    let availableActiveApps = max(sideloadedAppsLimit - activeAppsCount, 0)
                    if installedApp.requiredActiveSlots <= availableActiveApps
                    {
                        // This app has not been explicitly activated, but there are enough slots available,
                        // so implicitly activate it.
                        installedApp.isActive = true
                        activeApps.append(installedApp)
                    }
                    else
                    {
                        installedApp.isActive = false
                    }
                }

                activeProfiles = Set(activeApps.flatMap { (installedApp) -> [String] in
                    let appExtensionProfiles = installedApp.appExtensions.map { $0.resignedBundleIdentifier }
                    return [installedApp.resignedBundleIdentifier] + appExtensionProfiles
                })
            }
            
            do
            {
                // Persist recovery metadata before handing installation to the server.
                self.receiptIdentifier = try InstallationReceiptStore.shared.stage(installedApp)
            }
            catch
            {
                self.finish(.failure(error))
                return
            }
            self.context.beginInstallationHandler?(installedApp)
            self.cleanUp()

            let resignedBundleID = installedApp.resignedBundleIdentifier
            
            let request = BeginInstallationRequest(activeProfiles: activeProfiles, bundleIdentifier: resignedBundleID)
            guard !self.isCancelled else { self.finish(.failure(OperationError.cancelled)); return }
            self.awaitServerResponse()
            connection.send(request) { (result) in
                guard !self.isFinished else { return }
                switch result
                {
                case .failure(let error): 
                    Logger.sideload.notice("Failed to send begin installation request for resigned app \(resignedBundleID, privacy: .public). \(error.localizedDescription, privacy: .public)")
                    self.finish(.failure(error))
                    
                case .success:
                    Logger.sideload.notice("Sent begin installation request for resigned app \(resignedBundleID, privacy: .public).")
                    
                    self.receive(from: connection) { (result) in
                        switch result
                        {
                        case .success:
                            backgroundContext.perform {
                                Logger.sideload.notice("Successfully installed resigned app \(resignedBundleID, privacy: .public)!")
                                
                                do
                                {
                                    installedApp.refreshedDate = Date()
                                    // A later cancellation or lost UI must not discard a confirmed install.
                                    try backgroundContext.save()
                                    if let identifier = self.receiptIdentifier {
                                        try? InstallationReceiptStore.shared.remove(bundleIdentifier: self.context.bundleIdentifier, matching: identifier)
                                    }
                                    self.finish(.success(installedApp))
                                }
                                catch { self.finish(.failure(error)) }
                            }
                            
                        case .failure(let error):
                            Logger.sideload.notice("Failed to install resigned app \(resignedBundleID, privacy: .public). \(error.localizedDescription, privacy: .public)")
                            self.finish(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    override func finish(_ result: Result<InstalledApp, Error>)
    {
        self.completionLock.lock()
        guard !self.didFinish else { self.completionLock.unlock(); return }
        self.didFinish = true
        self.responseTimer?.cancel()
        self.responseTimer = nil
        self.completionLock.unlock()
        self.cleanUp()
        
        // Only remove refreshed IPA when finished.
        if let app = self.context.app
        {
            let fileURL = InstalledApp.refreshedIPAURL(for: app)
            
            do
            {
                try FileManager.default.removeItem(at: fileURL)
            }
            catch
            {
                Logger.sideload.error("Failed to remove refreshed .ipa: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        super.finish(result)
        if case .failure = result, self.receiptIdentifier != nil {
            AppManager.shared.update()
        }
    }
}

private extension InstallAppOperation
{
    func receive(from connection: ServerConnection, completionHandler: @escaping (Result<Void, Error>) -> Void)
    {
        self.awaitServerResponse()
        connection.receiveResponse() { (result) in
            guard !self.isFinished else { return }
            do
            {
                let response = try result.get()
                                
                switch response
                {
                case .installationProgress(let response):
                    guard response.progress.isFinite, response.progress >= 0 else
                    {
                        completionHandler(.failure(ALTServerError(.invalidResponse)))
                        return
                    }

                    let fractionCompleted = min(response.progress, 1.0)
                    let percentCompleted = Int((fractionCompleted * 100).rounded())
                    let connectionName = connection.server.connectionType.localizedDiagnosticName
                    self.context.recordDiagnostic(.installingApp, detail: "\(connectionName) / \(percentCompleted)%")
                    Logger.sideload.debug("Installing \(self.context.resignedApp?.bundleIdentifier ?? self.context.bundleIdentifier, privacy: .public)... \(percentCompleted)%")
                    
                    if fractionCompleted >= 1.0
                    {
                        self.progress.completedUnitCount = self.progress.totalUnitCount
                        completionHandler(.success(()))
                    }
                    else
                    {
                        self.progress.completedUnitCount = Int64(percentCompleted)
                        self.receive(from: connection, completionHandler: completionHandler)
                    }
                    
                case .error(let response):
                    completionHandler(.failure(response.error))
                    
                default:
                    completionHandler(.failure(ALTServerError(.unknownRequest)))
                }
            }
            catch
            {
                completionHandler(.failure(ALTServerError(error)))
            }
        }
    }
    
    func cleanUp()
    {
        self.completionLock.lock()
        guard !self.didCleanUp else { self.completionLock.unlock(); return }
        self.didCleanUp = true
        self.completionLock.unlock()
        
        do
        {
            try FileManager.default.removeItem(at: self.context.temporaryDirectory)
        }
        catch
        {
            Logger.sideload.error("Failed to remove temporary directory: \(error.localizedDescription, privacy: .public)")
        }
    }
}
