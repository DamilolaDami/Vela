//
//  KeychainHelper.swift
//  Vela
//
//  Created by damilola on 6/4/25.
//

import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save data to keychain
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Unique identifier for the data
    ///   - service: Service identifier (defaults to bundle identifier)
    /// - Returns: Success status
    @discardableResult
    func save(_ data: Data, forKey key: String, service: String? = nil) -> Bool {
        let query = buildQuery(for: key, service: service)
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var newQuery = query
        newQuery[kSecValueData as String] = data
        
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Save string to keychain
    /// - Parameters:
    ///   - string: String to store
    ///   - key: Unique identifier for the string
    ///   - service: Service identifier (defaults to bundle identifier)
    /// - Returns: Success status
    @discardableResult
    func save(_ string: String, forKey key: String, service: String? = nil) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, forKey: key, service: service)
    }
    
    /// Retrieve data from keychain
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - service: Service identifier (defaults to bundle identifier)
    /// - Returns: Retrieved data or nil if not found
    func getData(forKey key: String, service: String? = nil) -> Data? {
        var query = buildQuery(for: key, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    /// Retrieve string from keychain
    /// - Parameters:
    ///   - key: Unique identifier for the string
    ///   - service: Service identifier (defaults to bundle identifier)
    /// - Returns: Retrieved string or nil if not found
    func getString(forKey key: String, service: String? = nil) -> String? {
        guard let data = getData(forKey: key, service: service) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete item from keychain
    /// - Parameters:
    ///   - key: Unique identifier for the item
    ///   - service: Service identifier (defaults to bundle identifier)
    /// - Returns: Success status
    @discardableResult
    func delete(forKey key: String, service: String? = nil) -> Bool {
        let query = buildQuery(for: key, service: service)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Check if item exists in keychain
    /// - Parameters:
    ///   - key: Unique identifier for the item
    ///   - service: Service identifier (defaults to bundle identifier)
    /// - Returns: True if item exists
    func exists(forKey key: String, service: String? = nil) -> Bool {
        var query = buildQuery(for: key, service: service)
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Clear all items for the current service
    /// - Parameter service: Service identifier (defaults to bundle identifier)
    /// - Returns: Success status
    @discardableResult
    func clearAll(service: String? = nil) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service ?? defaultService
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Private Methods
    
    private func buildQuery(for key: String, service: String?) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service ?? defaultService,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
    }
    
    private var defaultService: String {
        return Bundle.main.bundleIdentifier ?? "com.vela.app"
    }
}



// MARK: - Error Handling

extension KeychainHelper {
    
    enum KeychainError: Error, LocalizedError {
        case duplicateItem
        case itemNotFound
        case invalidData
        case unexpectedError(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "Item already exists in keychain"
            case .itemNotFound:
                return "Item not found in keychain"
            case .invalidData:
                return "Invalid data format"
            case .unexpectedError(let status):
                return "Unexpected keychain error: \(status)"
            }
        }
    }
    
    /// Save data with error handling
    func saveWithError(_ data: Data, forKey key: String, service: String? = nil) throws {
        let query = buildQuery(for: key, service: service)
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var newQuery = query
        newQuery[kSecValueData as String] = data
        
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw KeychainError.duplicateItem
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
    
    /// Get data with error handling
    func getDataWithError(forKey key: String, service: String? = nil) throws -> Data {
        var query = buildQuery(for: key, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidData
            }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
}
