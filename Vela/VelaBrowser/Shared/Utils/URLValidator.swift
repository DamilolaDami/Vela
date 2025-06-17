//
//  URLValidator.swift
//  Vela
//
//  Created by damilola on 6/4/25.
//

import Foundation
#if canImport(Network)
import Network
#endif

/// A comprehensive Vela URL validation utility supporting iOS and macOS
/// Provides multiple validation strategies and detailed error reporting
public final class URLValidator {
    
    // MARK: - Singleton
    
    public static let shared = URLValidator()
    
    // MARK: - Configuration
    
    public struct Configuration {
        /// Allowed URL schemes (default: http, https, ftp, ftps)
        public var allowedSchemes: Set<String>
        /// Maximum URL length (default: 2048)
        public var maxLength: Int
        /// Whether to allow localhost URLs (default: true in debug, false in release)
        public var allowLocalhost: Bool
        /// Whether to allow IP addresses (default: true)
        public var allowIPAddresses: Bool
        /// Whether to require TLD for domain validation (default: true)
        public var requireTLD: Bool
        /// Custom blocked domains
        public var blockedDomains: Set<String>
        /// Custom allowed domains (if set, only these domains are allowed)
        public var allowedDomains: Set<String>?
        /// Whether to perform DNS lookup validation (default: false for performance)
        public var performDNSValidation: Bool
        /// Timeout for network validation in seconds (default: 5.0)
        public var networkTimeout: TimeInterval
        
        public init(
            allowedSchemes: Set<String> = ["http", "https", "ftp", "ftps"],
            maxLength: Int = 2048,
            allowLocalhost: Bool? = nil,
            allowIPAddresses: Bool = true,
            requireTLD: Bool = true,
            blockedDomains: Set<String> = [],
            allowedDomains: Set<String>? = nil,
            performDNSValidation: Bool = false,
            networkTimeout: TimeInterval = 5.0
        ) {
            self.allowedSchemes = allowedSchemes
            self.maxLength = maxLength
            self.allowLocalhost = allowLocalhost ?? {
                #if DEBUG
                return true
                #else
                return false
                #endif
            }()
            self.allowIPAddresses = allowIPAddresses
            self.requireTLD = requireTLD
            self.blockedDomains = blockedDomains
            self.allowedDomains = allowedDomains
            self.performDNSValidation = performDNSValidation
            self.networkTimeout = networkTimeout
        }
    }
    
    // MARK: - Properties
    
    private var configuration: Configuration
    private let ipv4Regex = try! NSRegularExpression(
        pattern: #"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#
    )
    private let ipv6Regex = try! NSRegularExpression(
        pattern: #"^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::1$|^::$"#
    )
    private let domainRegex = try! NSRegularExpression(
        pattern: #"^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"#
    )
    
    // MARK: - Initialization
    
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    // MARK: - Validation Results
    
    public enum ValidationResult {
        case valid
        case invalid(ValidationError)
        
        public var isValid: Bool {
            switch self {
            case .valid: return true
            case .invalid: return false
            }
        }
        
        public var error: ValidationError? {
            switch self {
            case .valid: return nil
            case .invalid(let error): return error
            }
        }
    }
    
    public enum ValidationError: Error, LocalizedError, Equatable {
        case empty
        case tooLong(Int)
        case invalidFormat
        case unsupportedScheme(String)
        case invalidHost
        case localhostNotAllowed
        case ipAddressNotAllowed
        case domainBlocked(String)
        case domainNotAllowed(String)
        case missingTLD
        case dnsResolutionFailed
        case networkTimeout
        case malformedComponents
        
        public var errorDescription: String? {
            switch self {
            case .empty:
                return "URL cannot be empty"
            case .tooLong(let length):
                return "URL is too long (\(length) characters)"
            case .invalidFormat:
                return "URL format is invalid"
            case .unsupportedScheme(let scheme):
                return "Unsupported URL scheme: \(scheme)"
            case .invalidHost:
                return "Invalid host in URL"
            case .localhostNotAllowed:
                return "Localhost URLs are not allowed"
            case .ipAddressNotAllowed:
                return "IP address URLs are not allowed"
            case .domainBlocked(let domain):
                return "Domain is blocked: \(domain)"
            case .domainNotAllowed(let domain):
                return "Domain is not in allowed list: \(domain)"
            case .missingTLD:
                return "Domain must have a valid top-level domain"
            case .dnsResolutionFailed:
                return "DNS resolution failed for domain"
            case .networkTimeout:
                return "Network validation timed out"
            case .malformedComponents:
                return "URL components are malformed"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Validate a URL string with the current configuration
    /// - Parameter urlString: The URL string to validate
    /// - Returns: ValidationResult indicating success or failure with details
    public func validate(_ urlString: String) -> ValidationResult {
        return validate(urlString, configuration: configuration)
    }
    
    /// Validate a URL string with custom configuration
    /// - Parameters:
    ///   - urlString: The URL string to validate
    ///   - configuration: Custom configuration for this validation
    /// - Returns: ValidationResult indicating success or failure with details
    public func validate(_ urlString: String, configuration: Configuration) -> ValidationResult {
        // Basic checks
        if urlString.isEmpty {
            return .invalid(.empty)
        }
        
        if urlString.count > configuration.maxLength {
            return .invalid(.tooLong(urlString.count))
        }
        
        // URL parsing
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .invalid(.invalidFormat)
        }
        
        // Validate URL components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .invalid(.malformedComponents)
        }
        
        // Scheme validation
        if let result = validateScheme(components.scheme, configuration: configuration) {
            return result
        }
        
        // Host validation
        if let result = validateHost(components.host, configuration: configuration) {
            return result
        }
        
        return .valid
    }
    
    /// Validate a URL string asynchronously with network checks
    /// - Parameters:
    ///   - urlString: The URL string to validate
    ///   - completion: Completion handler with validation result
    public func validateAsync(_ urlString: String, completion: @escaping (ValidationResult) -> Void) {
        validateAsync(urlString, configuration: configuration, completion: completion)
    }
    
    /// Validate a URL string asynchronously with custom configuration
    /// - Parameters:
    ///   - urlString: The URL string to validate
    ///   - configuration: Custom configuration for this validation
    ///   - completion: Completion handler with validation result
    public func validateAsync(_ urlString: String, configuration: Configuration, completion: @escaping (ValidationResult) -> Void) {
        // Perform basic validation first
        let basicResult = validate(urlString, configuration: configuration)
        guard basicResult.isValid else {
            completion(basicResult)
            return
        }
        
        // Perform network validation if enabled
        if configuration.performDNSValidation {
            guard let url = URL(string: urlString),
                  let host = url.host else {
                completion(.invalid(.invalidHost))
                return
            }
            
            performDNSValidation(host: host, timeout: configuration.networkTimeout) { success in
                DispatchQueue.main.async {
                    completion(success ? .valid : .invalid(.dnsResolutionFailed))
                }
            }
        } else {
            completion(basicResult)
        }
    }
    
    /// Update the validator's configuration
    /// - Parameter configuration: New configuration to use
    public func updateConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Check if a URL string is valid (convenience method)
    /// - Parameter urlString: The URL string to check
    /// - Returns: Boolean indicating validity
    public func isValid(_ urlString: String) -> Bool {
        return validate(urlString).isValid
    }
    
    /// Sanitize and normalize a URL string
    /// - Parameter urlString: The URL string to sanitize
    /// - Returns: Sanitized URL string or nil if invalid
    public func sanitize(_ urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add scheme if missing
        var normalized = trimmed
        if !trimmed.contains("://") {
            normalized = "https://" + trimmed
        }
        
        // Validate the normalized URL
        guard validate(normalized).isValid else {
            return nil
        }
        
        return normalized
    }
    
    // MARK: - Private Methods
    
    private func validateScheme(_ scheme: String?, configuration: Configuration) -> ValidationResult? {
        guard let scheme = scheme?.lowercased() else {
            return .invalid(.invalidFormat)
        }
        
        if !configuration.allowedSchemes.contains(scheme) {
            return .invalid(.unsupportedScheme(scheme))
        }
        
        return nil
    }
    
    private func validateHost(_ host: String?, configuration: Configuration) -> ValidationResult? {
        guard let host = host?.lowercased() else {
            return .invalid(.invalidHost)
        }
        
        // Check for localhost
        if isLocalhost(host) && !configuration.allowLocalhost {
            return .invalid(.localhostNotAllowed)
        }
        
        // Check for IP addresses
        if isIPAddress(host) {
            if !configuration.allowIPAddresses {
                return .invalid(.ipAddressNotAllowed)
            }
            return nil // IP addresses are valid if allowed
        }
        
        // Domain validation
        if let result = validateDomain(host, configuration: configuration) {
            return result
        }
        
        return nil
    }
    
    private func validateDomain(_ domain: String, configuration: Configuration) -> ValidationResult? {
        // Check blocked domains
        if configuration.blockedDomains.contains(domain) {
            return .invalid(.domainBlocked(domain))
        }
        
        // Check allowed domains (if specified)
        if let allowedDomains = configuration.allowedDomains,
           !allowedDomains.contains(domain) {
            return .invalid(.domainNotAllowed(domain))
        }
        
        // Check domain format
        let range = NSRange(location: 0, length: domain.count)
        if (domainRegex.firstMatch(in: domain, options: [], range: range) == nil) != nil {
            return .invalid(.invalidHost)
        }
        
        // Check for TLD requirement
        if configuration.requireTLD && !domain.contains(".") {
            return .invalid(.missingTLD)
        }
        
        return nil
    }
    
    private func isLocalhost(_ host: String) -> Bool {
        let localhostPatterns = ["localhost", "127.0.0.1", "::1", "0.0.0.0"]
        return localhostPatterns.contains(host) || host.hasSuffix(".local")
    }
    
    private func isIPAddress(_ host: String) -> Bool {
        let range = NSRange(location: 0, length: host.count)
        return ipv4Regex.firstMatch(in: host, options: [], range: range) != nil ||
               ipv6Regex.firstMatch(in: host, options: [], range: range) != nil
    }
    
    #if canImport(Network)
    @available(iOS 12.0, macOS 10.14, *)
    private func performDNSValidation(host: String, timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.vela.dns-validation")

        monitor.pathUpdateHandler = { path in
            monitor.cancel()

            if path.status == .satisfied {
                let hostEndpoint = NWEndpoint.Host.name(host, nil)
                let endpoint = NWEndpoint.hostPort(host: hostEndpoint, port: .http)

                let connection = NWConnection(to: endpoint, using: .tcp)

                let timeoutWork = DispatchWorkItem {
                    connection.cancel()
                    completion(false)
                }

                queue.asyncAfter(deadline: .now() + timeout, execute: timeoutWork)

                connection.stateUpdateHandler = { state in
                    timeoutWork.cancel()
                    connection.cancel()

                    switch state {
                    case .ready, .preparing:
                        completion(true)
                    default:
                        completion(false)
                    }
                }

                connection.start(queue: queue)
            } else {
                completion(false)
            }
        }

        monitor.start(queue: queue)
    }
    #else
    private func performDNSValidation(host: String, timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        // Fallback DNS validation using CFHost (macOS/iOS compatibility)
        DispatchQueue.global(qos: .utility).async {
            var result = false
            let semaphore = DispatchSemaphore(value: 0)
            
            guard let cfHost = CFHostCreateWithName(nil, host as CFString).takeRetainedValue() as CFHost? else {
                completion(false)
                return
            }
            
            var context = CFHostClientContext()
            context.info = Unmanaged.passUnretained(semaphore).toOpaque()
            
            CFHostSetClient(cfHost, { (host, typeInfo, error, info) in
                if let info = info {
                    let semaphore = Unmanaged<DispatchSemaphore>.fromOpaque(info).takeUnretainedValue()
                    semaphore.signal()
                }
            }, &context)
            
            CFHostScheduleWithRunLoop(cfHost, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            
            if CFHostStartInfoResolution(cfHost, .addresses, nil) {
                let timeoutResult = semaphore.wait(timeout: .now() + timeout)
                result = (timeoutResult == .success)
            }
            
            CFHostUnscheduleFromRunLoop(cfHost, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            completion(result)
        }
    }
    #endif
}

