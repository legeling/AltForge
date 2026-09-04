//
//  PluginManager.swift
//  AltServer
//
//  Created by Riley Testut on 9/16/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import Foundation
import AppKit

import STPrivilegedTask

private let pluginDirectoryURL = URL(fileURLWithPath: "/Library/Mail/Bundles", isDirectory: true)
private let pluginURL = pluginDirectoryURL.appendingPathComponent("AltPlugin.mailbundle")

extension PluginError
{
    enum Code: Int, ALTErrorCode
    {
        typealias Error = PluginError
        
        case cancelled
        case unknown
        case taskError
        case taskErrorCode
    }
    
    static let cancelled = PluginError(code: .cancelled)
    
    static func unknown(file: String = #fileID, line: UInt = #line) -> PluginError { PluginError(code: .unknown, sourceFile: file, sourceLine: line) }
    static func taskError(output: String) -> PluginError { PluginError(code: .taskError, taskErrorOutput: output) }
    static func taskErrorCode(_ code: Int) -> PluginError { PluginError(code: .taskErrorCode, taskErrorCode: code) }
}

struct PluginError: ALTLocalizedError
{
    let code: Code
    
    var errorTitle: String?
    var errorFailure: String?
    var sourceFile: String?
    var sourceLine: UInt?
    
    var taskErrorOutput: String?
    var taskErrorCode: Int?
    
    var errorFailureReason: String {
        switch self.code
        {
        case .cancelled: return NSLocalizedString("Mail plug-in installation was cancelled.", comment: "")
        case .unknown: return NSLocalizedString("Failed to install Mail plug-in.", comment: "")
        case .taskError:
            return NSLocalizedString("The Mail plug-in installer returned an error.", comment: "")
            
        case .taskErrorCode:
            let baseMessage = NSLocalizedString("There was an error installing the Mail plug-in.", comment: "")
            guard let errorCode = self.taskErrorCode else { return baseMessage }
            
            let additionalInfo = String(format: NSLocalizedString("(Error Code: %@)", comment: ""), NSNumber(value: errorCode))
            return baseMessage + " " + additionalInfo
        }
    }
}

class PluginManager
{
    var isMailPluginInstalled: Bool {
        let isMailPluginInstalled = FileManager.default.fileExists(atPath: pluginURL.path)
        return isMailPluginInstalled
    }
}

extension PluginManager
{
    func uninstallMailPlugin(completionHandler: @escaping (Result<Void, Error>) -> Void)
    {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Remove Legacy Mail Plug-in", comment: "")
        alert.informativeText = NSLocalizedString("This plug-in was used by older AltServer versions and is no longer needed by AltForge Server. Remove it from Mail?", comment: "")
        
        alert.addButton(withTitle: NSLocalizedString("Remove Plug-in", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return completionHandler(.failure(PluginError.cancelled)) }
        
        DispatchQueue.global().async {
            do
            {
                if FileManager.default.fileExists(atPath: pluginURL.path)
                {
                    // Delete Mail plug-in from privileged directory.
                    try self.run("rm", arguments: ["-rf", pluginURL.path])
                }
                
                completionHandler(.success(()))
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
}

private extension PluginManager
{
    func run(_ program: String, arguments: [String], authorization: AuthorizationRef? = nil) throws
    {
        _ = try self._run(program, arguments: arguments, authorization: authorization, freeAuthorization: true)
    }
    
    @discardableResult
    func runAndKeepAuthorization(_ program: String, arguments: [String], authorization: AuthorizationRef? = nil) throws -> AuthorizationRef
    {
        return try self._run(program, arguments: arguments, authorization: authorization, freeAuthorization: false)
    }
    
    func _run(_ program: String, arguments: [String], authorization: AuthorizationRef? = nil, freeAuthorization: Bool) throws -> AuthorizationRef
    {
        var launchPath = "/usr/bin/" + program
        if !FileManager.default.fileExists(atPath: launchPath)
        {
            launchPath = "/bin/" + program
        }
        
        print("Running program:", launchPath)
        
        let task = STPrivilegedTask()
        task.launchPath = launchPath
        task.arguments = arguments
        task.freeAuthorizationWhenDone = freeAuthorization
        
        let errorCode: OSStatus
        
        if let authorization = authorization
        {
            errorCode = task.launch(withAuthorization: authorization)
        }
        else
        {
            errorCode = task.launch()
        }
        
        guard errorCode == 0 else { throw PluginError.taskErrorCode(Int(errorCode)) }
        
        task.waitUntilExit()
        
        print("Exit code:", task.terminationStatus)
        
        guard task.terminationStatus == 0 else {
            let outputData = task.outputFileHandle.readDataToEndOfFile()
            
            if let outputString = String(data: outputData, encoding: .utf8), !outputString.isEmpty
            {
                throw PluginError.taskError(output: outputString)
            }
            
            throw PluginError.taskErrorCode(Int(task.terminationStatus))
        }
        
        guard let authorization = task.authorization else { throw PluginError.unknown() }
        return authorization
    }
}
