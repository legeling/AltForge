//
//  AppleIDCredentialStore.swift
//  AltServer
//
//  Copyright © 2026 AltForge contributors.
//

import Foundation
import KeychainAccess

protocol AppleIDCredentialStoring: AnyObject
{
    func accounts() throws -> [String]
    func password(for account: String) throws -> String?
    func recordSuccessfulAuthentication(account: String, password: String, rememberPassword: Bool) throws
    func removeAccount(_ account: String) throws
}

final class AppleIDCredentialStore: AppleIDCredentialStoring
{
    private struct CredentialArchive: Codable
    {
        let version: Int
        var credentials: [Credential]
    }

    private struct Credential: Codable
    {
        let account: String
        let password: String?
    }

    private enum StoreError: Error
    {
        case invalidArchive
        case invalidCredential
    }

    private static let archiveKey = "credentialArchive"
    private static let archiveVersion = 1
    private static let maximumAccounts = 8
    private static let maximumArchiveSize = 64 * 1024
    private static let maximumAccountLength = 320
    private static let maximumPasswordLength = 1024

    private let keychain = Keychain(service: "com.legeling.AltForge.AltServer.AppleIDCredentials")
        .accessibility(.afterFirstUnlockThisDeviceOnly)

    func accounts() throws -> [String]
    {
        try self.loadArchive().credentials.map(\.account)
    }

    func password(for account: String) throws -> String?
    {
        let credentials = try self.loadArchive().credentials
        return credentials.first(where: { $0.account.compare(account, options: .caseInsensitive) == .orderedSame })?.password
    }

    func recordSuccessfulAuthentication(account: String, password: String, rememberPassword: Bool) throws
    {
        guard let account = self.validatedAccount(account), password.count <= Self.maximumPasswordLength else
        {
            throw StoreError.invalidCredential
        }

        var credentials = try self.loadArchive().credentials
        credentials.removeAll(where: { $0.account.compare(account, options: .caseInsensitive) == .orderedSame })
        credentials.insert(Credential(account: account, password: rememberPassword ? password : nil), at: 0)

        if credentials.count > Self.maximumAccounts
        {
            credentials.removeLast(credentials.count - Self.maximumAccounts)
        }

        try self.save(CredentialArchive(version: Self.archiveVersion, credentials: credentials))
    }

    func removeAccount(_ account: String) throws
    {
        var archive = try self.loadArchive()
        archive.credentials.removeAll(where: { $0.account.compare(account, options: .caseInsensitive) == .orderedSame })
        try self.save(archive)
    }
}

private extension AppleIDCredentialStore
{
    private func loadArchive() throws -> CredentialArchive
    {
        guard let data = try self.keychain.getData(Self.archiveKey) else
        {
            return CredentialArchive(version: Self.archiveVersion, credentials: [])
        }
        guard data.count <= Self.maximumArchiveSize,
              let archive = try? JSONDecoder().decode(CredentialArchive.self, from: data),
              archive.version == Self.archiveVersion,
              archive.credentials.count <= Self.maximumAccounts,
              archive.credentials.allSatisfy({ self.validatedAccount($0.account) == $0.account && ($0.password?.count ?? 0) <= Self.maximumPasswordLength })
        else
        {
            throw StoreError.invalidArchive
        }
        return archive
    }

    private func save(_ archive: CredentialArchive) throws
    {
        if archive.credentials.isEmpty
        {
            try self.keychain.remove(Self.archiveKey)
            return
        }

        let data = try JSONEncoder().encode(archive)
        guard data.count <= Self.maximumArchiveSize else { throw StoreError.invalidArchive }
        try self.keychain.set(data, key: Self.archiveKey)
    }

    func validatedAccount(_ account: String) -> String?
    {
        let value = account.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= Self.maximumAccountLength else { return nil }
        return value
    }
}
