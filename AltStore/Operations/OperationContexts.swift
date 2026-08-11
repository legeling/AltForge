//
//  Contexts.swift
//  AltStore
//
//  Created by Riley Testut on 6/20/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation
import CoreData
import Network

import AltStoreCore
import AltSign

import Roxas

enum AppOperationDiagnosticStage: String, Codable
{
    case queued
    case findingServer
    case authenticating
    case authenticated
    case preparingApp
    case verifyingApp
    case preparingProfiles
    case refreshingApp
    case signingApp
    case sendingApp
    case installingApp
    case completed
    case failed

    var localizedName: String {
        switch self
        {
        case .queued: return NSLocalizedString("Queued", comment: "App operation diagnostic stage")
        case .findingServer: return NSLocalizedString("Finding AltForge Server", comment: "App operation diagnostic stage")
        case .authenticating: return NSLocalizedString("Authenticating Apple ID", comment: "App operation diagnostic stage")
        case .authenticated: return NSLocalizedString("Authentication Ready", comment: "App operation diagnostic stage")
        case .preparingApp: return NSLocalizedString("Preparing App", comment: "App operation diagnostic stage")
        case .verifyingApp: return NSLocalizedString("Verifying App", comment: "App operation diagnostic stage")
        case .preparingProfiles: return NSLocalizedString("Preparing Provisioning Profiles", comment: "App operation diagnostic stage")
        case .refreshingApp: return NSLocalizedString("Refreshing App", comment: "App operation diagnostic stage")
        case .signingApp: return NSLocalizedString("Signing App", comment: "App operation diagnostic stage")
        case .sendingApp: return NSLocalizedString("Sending App", comment: "App operation diagnostic stage")
        case .installingApp: return NSLocalizedString("Installing on Device", comment: "App operation diagnostic stage")
        case .completed: return NSLocalizedString("Completed", comment: "App operation diagnostic stage")
        case .failed: return NSLocalizedString("Failed", comment: "App operation diagnostic stage")
        }
    }

    var isTerminal: Bool {
        return self == .completed || self == .failed
    }
}

class OperationContext
{
    var server: Server?
    var error: Error?
    var diagnosticHandler: ((AppOperationDiagnosticStage, String?) -> Void)?
    
    var presentingViewController: UIViewController? {
        get {
            // Return first view controller that is non-nil, on-screen, AND is not currently being dismissed.
            let viewController = [self.primaryViewController, self.secondaryViewController].compactMap { $0 }.first(where: { $0.isViewLoaded && $0.view.window != nil && !$0.isDisappearing })
            return viewController
        }
        set {
            self.primaryViewController = newValue
            
            if let newValue
            {
                rst_dispatch_sync_on_main_thread {
                    self.secondaryViewController = newValue.presentingViewController
                }
            }
        }
    }
    
    private weak var primaryViewController: UIViewController?
    private weak var secondaryViewController: UIViewController?
    
    let operations: NSHashTable<Foundation.Operation>
    
    init(server: Server? = nil, error: Error? = nil, operations: [Foundation.Operation] = [])
    {
        self.server = server
        self.error = error
        
        self.operations = NSHashTable<Foundation.Operation>.weakObjects()
        for operation in operations
        {
            self.operations.add(operation)
        }
    }
    
    convenience init(context: OperationContext)
    {
        self.init(server: context.server, error: context.error, operations: context.operations.allObjects)
        self.diagnosticHandler = context.diagnosticHandler
    }

    func recordDiagnostic(_ stage: AppOperationDiagnosticStage, detail: String? = nil)
    {
        self.diagnosticHandler?(stage, detail)
    }
}

class AuthenticatedOperationContext: OperationContext
{
    var session: ALTAppleAPISession?
    
    var team: ALTTeam?
    var certificate: ALTCertificate?
    
    weak var authenticationOperation: AuthenticationOperation?
    
    convenience init(context: AuthenticatedOperationContext)
    {
        self.init(server: context.server, error: context.error, operations: context.operations.allObjects)
        
        self.session = context.session
        self.team = context.team
        self.certificate = context.certificate
        self.authenticationOperation = context.authenticationOperation
        self.diagnosticHandler = context.diagnosticHandler
    }
}

@dynamicMemberLookup
class AppOperationContext
{
    let bundleIdentifier: String
    let authenticatedContext: AuthenticatedOperationContext
    var diagnosticHandler: ((AppOperationDiagnosticStage, String?) -> Void)?
    
    var app: ALTApplication?
    var provisioningProfiles: [String: ALTProvisioningProfile]?
    
    var isFinished = false
    
    var error: Error? {
        get {
            return _error ?? self.authenticatedContext.error
        }
        set {
            _error = newValue
            
            if self.authenticatedContext.error == nil
            {
                // Assign newValue to authenticatedContext.error if the latter is nil.
                // This fixes some operations continuing even after an error has occured.
                self.authenticatedContext.error = newValue
            }
        }
    }
    private var _error: Error?
    
    init(bundleIdentifier: String, authenticatedContext: AuthenticatedOperationContext)
    {
        self.bundleIdentifier = bundleIdentifier
        self.authenticatedContext = authenticatedContext
    }

    func recordDiagnostic(_ stage: AppOperationDiagnosticStage, detail: String? = nil)
    {
        if let diagnosticHandler = self.diagnosticHandler
        {
            diagnosticHandler(stage, detail)
        }
        else
        {
            self.authenticatedContext.recordDiagnostic(stage, detail: detail)
        }
    }
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<AuthenticatedOperationContext, T>) -> T
    {
        return self.authenticatedContext[keyPath: keyPath]
    }
}

class InstallAppOperationContext: AppOperationContext
{
    lazy var temporaryDirectory: URL = {
        let temporaryDirectory = FileManager.default.uniqueTemporaryURL()
        
        do { try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil) }
        catch { self.error = error }
        
        return temporaryDirectory
    }()
    
    var ipaURL: URL?
    var resignedApp: ALTApplication?
    
    var installationConnection: ServerConnection?
    var installedApp: InstalledApp? {
        didSet {
            self.installedAppContext = self.installedApp?.managedObjectContext
        }
    }
    private var installedAppContext: NSManagedObjectContext?
    
    var beginInstallationHandler: ((InstalledApp) -> Void)?
    
    var alternateIconURL: URL?
    
    // Non-nil when installing from a source.
    @AsyncManaged
    var appVersion: AppVersion?
}
