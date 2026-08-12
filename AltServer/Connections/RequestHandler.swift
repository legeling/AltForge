//
//  RequestHandler.swift
//  AltServer
//
//  Created by Riley Testut on 5/23/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation

typealias ServerConnectionManager = ConnectionManager<ServerRequestHandler>

private let connectionManager = ConnectionManager(requestHandler: ServerRequestHandler(),
                                                  connectionHandlers: [WirelessConnectionHandler(), WiredConnectionHandler()])

private final class InstallationResponseCoordinator
{
    typealias CompletionHandler = (Result<Void, ALTServerError>) -> Void

    private let connection: Connection
    private let completionHandler: CompletionHandler
    private let queue = DispatchQueue(label: "com.altforge.ConnectionManager.installResponseQueue", qos: .default)

    private var isSending = false
    private var pendingProgress: Double?
    private var terminalResult: Result<Void, ALTServerError>?
    private var didFinish = false

    init(connection: Connection, completionHandler: @escaping CompletionHandler)
    {
        self.connection = connection
        self.completionHandler = completionHandler
    }

    func reportProgress(_ progress: Double)
    {
        self.queue.async {
            guard progress.isFinite, !self.didFinish, self.terminalResult == nil else { return }

            // Installation completion is sent exactly once through finish(_:).
            // Keeping progress below 1 prevents a KVO update from racing that
            // terminal response on the same connection.
            let boundedProgress = min(max(progress, 0), 0.99)
            self.pendingProgress = max(self.pendingProgress ?? 0, boundedProgress)
            self.sendNext()
        }
    }

    func finish(_ result: Result<Void, ALTServerError>)
    {
        self.queue.async {
            guard !self.didFinish, self.terminalResult == nil else { return }

            // A terminal response supersedes queued progress, but waits for any
            // response already being written before using the connection.
            self.pendingProgress = nil
            self.terminalResult = result
            self.sendNext()
        }
    }

    private func sendNext()
    {
        dispatchPrecondition(condition: .onQueue(self.queue))
        guard !self.isSending, !self.didFinish else { return }

        if let terminalResult = self.terminalResult
        {
            self.didFinish = true
            self.completionHandler(terminalResult)
            return
        }

        guard let progress = self.pendingProgress else { return }
        self.pendingProgress = nil
        self.isSending = true

        let response = InstallationProgressResponse(progress: progress)
        self.connection.send(response) { result in
            self.queue.async {
                self.isSending = false

                if case .failure(let error) = result, self.terminalResult == nil
                {
                    self.terminalResult = .failure(error)
                }

                self.sendNext()
            }
        }
    }
}

extension ServerConnectionManager
{
    static var shared: ConnectionManager {
        return connectionManager
    }
}

struct ServerRequestHandler: RequestHandler
{
    func handleAnisetteDataRequest(_ request: AnisetteDataRequest, for connection: Connection, completionHandler: @escaping (Result<AnisetteDataResponse, Error>) -> Void)
    {
        AnisetteDataManager.shared.requestAnisetteData { (result) in
            switch result
            {
            case .failure(let error): completionHandler(.failure(error))
            case .success(let anisetteData):
                let response = AnisetteDataResponse(anisetteData: anisetteData)
                completionHandler(.success(response))
            }
        }
    }
    
    func handlePrepareAppRequest(_ request: PrepareAppRequest, for connection: Connection, completionHandler: @escaping (Result<InstallationProgressResponse, Error>) -> Void)
    {
        var temporaryURL: URL?
        
        func finish(_ result: Result<InstallationProgressResponse, Error>)
        {
            if let temporaryURL = temporaryURL
            {
                do { try FileManager.default.removeItem(at: temporaryURL) }
                catch { print("Failed to remove .ipa.", error) }
            }
            
            completionHandler(result)
        }
        
        self.receiveApp(for: request, from: connection) { (result) in
            print("Received app with result:", result)
            
            switch result
            {
            case .failure(let error): finish(.failure(error))
            case .success(let fileURL):
                temporaryURL = fileURL
                
                print("Awaiting begin installation request...")
                
                connection.receiveRequest() { (result) in
                    print("Received begin installation request with result:", result)
                    
                    switch result
                    {
                    case .failure(let error): finish(.failure(error))
                    case .success(.beginInstallation(let installRequest)):
                        print("Installing app to device \(request.udid)...")
                        
                        self.installApp(at: fileURL, toDeviceWithUDID: request.udid, activeProvisioningProfiles: installRequest.activeProfiles, connection: connection) { (result) in
                            print("Installed app to device with result:", result)
                            switch result
                            {
                            case .failure(let error): finish(.failure(error))
                            case .success:
                                let response = InstallationProgressResponse(progress: 1.0)
                                finish(.success(response))
                            }
                        }
                        
                    case .success: finish(.failure(ALTServerError(.unknownRequest)))
                    }
                }
            }
        }
    }
    
    func handleInstallProvisioningProfilesRequest(_ request: InstallProvisioningProfilesRequest, for connection: Connection,
                                                  completionHandler: @escaping (Result<InstallProvisioningProfilesResponse, Error>) -> Void)
    {
        ALTDeviceManager.shared.installProvisioningProfiles(request.provisioningProfiles, toDeviceWithUDID: request.udid, activeProvisioningProfiles: request.activeProfiles) { (success, error) in
            if let error = error, !success
            {
                print("Failed to install profiles \(request.provisioningProfiles.map { $0.bundleIdentifier }):", error)
                completionHandler(.failure(ALTServerError(error)))
            }
            else
            {
                print("Installed profiles:", request.provisioningProfiles.map { $0.bundleIdentifier })
                
                let response = InstallProvisioningProfilesResponse()
                completionHandler(.success(response))
            }
        }
    }
    
    func handleRemoveProvisioningProfilesRequest(_ request: RemoveProvisioningProfilesRequest, for connection: Connection,
                                                 completionHandler: @escaping (Result<RemoveProvisioningProfilesResponse, Error>) -> Void)
    {
        ALTDeviceManager.shared.removeProvisioningProfiles(forBundleIdentifiers: request.bundleIdentifiers, fromDeviceWithUDID: request.udid) { (success, error) in
            if let error = error, !success
            {
                print("Failed to remove profiles \(request.bundleIdentifiers):", error)
                completionHandler(.failure(ALTServerError(error)))
            }
            else
            {
                print("Removed profiles:", request.bundleIdentifiers)
                
                let response = RemoveProvisioningProfilesResponse()
                completionHandler(.success(response))
            }
        }
    }
    
    func handleRemoveAppRequest(_ request: RemoveAppRequest, for connection: Connection, completionHandler: @escaping (Result<RemoveAppResponse, Error>) -> Void)
    {
        ALTDeviceManager.shared.removeApp(forBundleIdentifier: request.bundleIdentifier, fromDeviceWithUDID: request.udid) { (success, error) in
            if let error = error, !success
            {
                print("Failed to remove app \(request.bundleIdentifier):", error)
                completionHandler(.failure(ALTServerError(error)))
            }
            else
            {
                print("Removed app:", request.bundleIdentifier)
                
                let response = RemoveAppResponse()
                completionHandler(.success(response))
            }
        }
    }
    
    func handleEnableUnsignedCodeExecutionRequest(_ request: EnableUnsignedCodeExecutionRequest, for connection: Connection, completionHandler: @escaping (Result<EnableUnsignedCodeExecutionResponse, Error>) -> Void)
    {
        guard let device = ALTDeviceManager.shared.availableDevices.first(where: { $0.identifier == request.udid }) else { return completionHandler(.failure(ALTServerError(.deviceNotFound))) }
                
        let process: AppProcess
        
        if let processID = request.processID
        {
            process = .pid(processID)
        }
        else if let processName = request.processName
        {
            process = .name(processName)
        }
        else
        {
            return completionHandler(.failure(ALTServerError(.invalidRequest)))
        }
        
        Task<Void, Never> {
            do
            {
                try await JITManager.shared.enableUnsignedCodeExecution(process: process, device: device)
                
                print("Enabled unsigned code execution for process:", request.processID ?? request.processName ?? "nil")
                
                let response = EnableUnsignedCodeExecutionResponse()
                completionHandler(.success(response))
            }
            catch
            {
                print("Failed to enable unsigned code execution for process \(request.processID?.description ?? request.processName ?? "nil"):", error)
                completionHandler(.failure(ALTServerError(error)))
            }
        }
    }
}

private extension RequestHandler
{
    func receiveApp(for request: PrepareAppRequest, from connection: Connection, completionHandler: @escaping (Result<URL, ALTServerError>) -> Void)
    {
        connection.receiveData(expectedSize: request.contentSize) { (result) in
            do
            {
                print("Received app data!")
                
                let data = try result.get()
                                
                guard ALTDeviceManager.shared.availableDevices.contains(where: { $0.identifier == request.udid }) else { throw ALTServerError(.deviceNotFound) }
                
                print("Writing app data...")
                
                let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
                try data.write(to: temporaryURL, options: .atomic)
                
                print("Wrote app to URL:", temporaryURL)
                
                completionHandler(.success(temporaryURL))
            }
            catch
            {
                print("Error processing app data:", error)
                
                completionHandler(.failure(ALTServerError(error)))
            }
        }
    }

    func installApp(at fileURL: URL, toDeviceWithUDID udid: String, activeProvisioningProfiles: Set<String>?, connection: Connection, completionHandler: @escaping (Result<Void, ALTServerError>) -> Void)
    {
        var observation: NSKeyValueObservation?
        let responseCoordinator = InstallationResponseCoordinator(connection: connection, completionHandler: completionHandler)
        
        let progress = ALTDeviceManager.shared.installApp(at: fileURL, toDeviceWithUDID: udid, activeProvisioningProfiles: activeProvisioningProfiles) { (success, error) in
            print("Installed app with result:", error == nil ? "Success" : error!.localizedDescription)

            observation?.invalidate()
            observation = nil
            
            if let error = error.map({ ALTServerError($0) })
            {
                responseCoordinator.finish(.failure(error))
            }
            else
            {
                responseCoordinator.finish(.success(()))
            }
        }
        
        observation = progress.observe(\.fractionCompleted, changeHandler: { (progress, change) in
            print("Progress:", progress.fractionCompleted)
            responseCoordinator.reportProgress(progress.fractionCompleted)
        })
    }
}
