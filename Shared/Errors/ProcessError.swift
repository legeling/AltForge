//
//  ProcessError.swift
//  AltPackage
//
//  Created by Riley Testut on 9/1/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import Foundation

extension ProcessError
{
    enum Code: Int, ALTErrorCode
    {
        typealias Error = ProcessError
        
        case failed
        case timedOut
        case unexpectedOutput
        case terminated
    }
    
    static func failed(executableURL: URL, exitCode: Int32, output: String?, file: StaticString = #file, line: Int = #line) -> ProcessError {
        ProcessError(code: .failed, executableURL: executableURL, exitCode: exitCode, output: output, sourceFile: file, sourceLine: UInt(line))
    }
            
    static func timedOut(executableURL: URL, exitCode: Int32? = nil, output: String? = nil, file: StaticString = #file, line: Int = #line) -> ProcessError {
        ProcessError(code: .timedOut, executableURL: executableURL, exitCode: exitCode, output: output, sourceFile: file, sourceLine: UInt(line))
    }
    
    static func unexpectedOutput(executableURL: URL, output: String, exitCode: Int32? = nil, file: StaticString = #file, line: Int = #line) -> ProcessError {
        ProcessError(code: .unexpectedOutput, executableURL: executableURL, exitCode: exitCode, output: output, sourceFile: file, sourceLine: UInt(line))
    }
    
    static func terminated(executableURL: URL, exitCode: Int32, output: String, file: StaticString = #file, line: Int = #line) -> ProcessError {
        ProcessError(code: .terminated, executableURL: executableURL, exitCode: exitCode, output: output, sourceFile: file, sourceLine: UInt(line))
    }
}

struct ProcessError: ALTLocalizedError
{
    let code: Code
    
    var errorTitle: String?
    var errorFailure: String?
    
    @UserInfoValue var executableURL: URL?
    @UserInfoValue var exitCode: Int32?
    @UserInfoValue var output: String?
    
    var sourceFile: StaticString?
    var sourceLine: UInt?
    
    var errorFailureReason: String {
        switch self.code
        {
        case .failed:
            guard let exitCode else { return String(format: NSLocalizedString("%@ failed.", comment: ""), self.processName) }
            return String(format: NSLocalizedString("%@ failed with code %@.", comment: ""), self.processName, NSNumber(value: exitCode))
            
        case .timedOut: return String(format: NSLocalizedString("%@ timed out.", comment: ""), self.processName)
        case .terminated: return String(format: NSLocalizedString("%@ unexpectedly quit.", comment: ""), self.processName)
        case .unexpectedOutput:
            return String(format: NSLocalizedString("%@ returned unexpected output.", comment: ""), self.processName)
        }
    }
    
    private var processName: String {
        guard let executableName = self.executableURL?.lastPathComponent else { return NSLocalizedString("The process", comment: "") }
        return String(format: NSLocalizedString("The process '%@'", comment: ""), executableName)
    }
    
}
