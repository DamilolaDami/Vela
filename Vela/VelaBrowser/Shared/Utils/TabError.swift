//
//  TabError.swift
//  Vela
//
//  Created by damilola on 6/20/25.
//


import Foundation
import WebKit
import Combine

// MARK: - Error Types and Categories

enum TabError: Error, LocalizedError {
    case webViewNotInitialized(tabId: UUID)
    case navigationFailed(url: URL?, error: Error)
    case loadingTimeout(url: URL?, duration: TimeInterval)
    case networkError(code: Int, description: String, url: URL?)
    case certificateError(url: URL?, description: String)
    case contentBlockingError(url: URL?, description: String)
    case jsEvaluationError(script: String, error: Error)
    case audioDetectionError(error: Error)
    case faviconLoadError(url: URL, error: Error)
    case zoomError(level: CGFloat, error: Error)
    case memoryPressure(tabId: UUID)
    case webProcessCrash(tabId: UUID)
    case invalidURL(string: String)
    case securityError(url: URL?, description: String)
    
    var errorDescription: String? {
        switch self {
        case .webViewNotInitialized(let tabId):
            return "WebView not initialized for tab \(tabId.uuidString.prefix(8))"
        case .navigationFailed(let url, let error):
            return "Navigation failed for \(url?.absoluteString ?? "unknown URL"): \(error.localizedDescription)"
        case .loadingTimeout(let url, let duration):
            return "Loading timeout after \(duration)s for \(url?.absoluteString ?? "unknown URL")"
        case .networkError(let code, let description, let url):
            return "Network error \(code) for \(url?.absoluteString ?? "unknown URL"): \(description)"
        case .certificateError(let url, let description):
            return "Certificate error for \(url?.absoluteString ?? "unknown URL"): \(description)"
        case .contentBlockingError(let url, let description):
            return "Content blocking error for \(url?.absoluteString ?? "unknown URL"): \(description)"
        case .jsEvaluationError(let script, let error):
            return "JavaScript evaluation failed for script '\(script.prefix(50))...': \(error.localizedDescription)"
        case .audioDetectionError(let error):
            return "Audio detection failed: \(error.localizedDescription)"
        case .faviconLoadError(let url, let error):
            return "Favicon load failed for \(url.absoluteString): \(error.localizedDescription)"
        case .zoomError(let level, let error):
            return "Zoom operation failed at level \(level): \(error.localizedDescription)"
        case .memoryPressure(let tabId):
            return "Memory pressure detected for tab \(tabId.uuidString.prefix(8))"
        case .webProcessCrash(let tabId):
            return "Web process crashed for tab \(tabId.uuidString.prefix(8))"
        case .invalidURL(let string):
            return "Invalid URL: \(string)"
        case .securityError(let url, let description):
            return "Security error for \(url?.absoluteString ?? "unknown URL"): \(description)"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .webProcessCrash, .memoryPressure, .securityError:
            return .critical
        case .navigationFailed, .loadingTimeout, .networkError, .certificateError:
            return .high
        case .contentBlockingError, .jsEvaluationError, .zoomError:
            return .medium
        case .audioDetectionError, .faviconLoadError, .webViewNotInitialized:
            return .low
        case .invalidURL:
            return .medium
        }
    }
}

enum ErrorSeverity: String, CaseIterable {
    case critical = "🔴 CRITICAL"
    case high = "🟠 HIGH"
    case medium = "🟡 MEDIUM"
    case low = "🟢 LOW"
    
    var emoji: String {
        switch self {
        case .critical: return "🔴"
        case .high: return "🟠"
        case .medium: return "🟡"
        case .low: return "🟢"
        }
    }
}

// MARK: - Error Handler Protocol

protocol TabErrorHandling: AnyObject {
    func handleError(_ error: TabError, context: [String: Any]?)
    func logError(_ error: TabError, context: [String: Any]?)
    func shouldRetry(_ error: TabError) -> Bool
    func getRecoveryAction(_ error: TabError) -> ErrorRecoveryAction?
}

enum ErrorRecoveryAction {
    case reload
    case goBack
    case closeTab
    case createNewTab
    case resetWebView
    case clearCache
    case retryWithDelay(TimeInterval)
    case showErrorPage(String)
    case none
}

// MARK: - Enhanced Error Handler

class TabErrorHandler: TabErrorHandling, ObservableObject {
    @Published var recentErrors: [ErrorRecord] = []
    @Published var errorStats: ErrorStatistics = ErrorStatistics()
    
    private let maxRecentErrors = 50
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    
    struct ErrorRecord: Identifiable {
        let id = UUID()
        let error: TabError
        let timestamp: Date
        let context: [String: Any]?
        let tabId: UUID?
        let url: URL?
        
        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }
    }
    
    struct ErrorStatistics {
        var totalErrors: Int = 0
        var errorsByType: [String: Int] = [:]
        var errorsBySeverity: [ErrorSeverity: Int] = [:]
        var averageErrorsPerHour: Double = 0
        var lastResetTime: Date = Date()
        
        mutating func recordError(_ error: TabError) {
            totalErrors += 1
            
            let errorType = String(describing: error).components(separatedBy: "(").first ?? "unknown"
            errorsByType[errorType, default: 0] += 1
            errorsBySeverity[error.severity, default: 0] += 1
            
            let hoursSinceReset = Date().timeIntervalSince(lastResetTime) / 3600
            averageErrorsPerHour = hoursSinceReset > 0 ? Double(totalErrors) / hoursSinceReset : 0
        }
    }
    
    func handleError(_ error: TabError, context: [String: Any]? = nil) {
        logError(error, context: context)
        recordError(error, context: context)
        
        let recoveryAction = getRecoveryAction(error)
        executeRecoveryAction(recoveryAction, error: error, context: context)
    }
    
    func logError(_ error: TabError, context: [String: Any]? = nil) {
        let contextStr = context?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "none"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        print("""
        
        ╔══════════════════════════════════════════════════════════════════════════════════
        ║ \(error.severity.rawValue) TAB ERROR
        ║ Time: \(timestamp)
        ║ Error: \(error.errorDescription ?? "Unknown error")
        ║ Context: \(contextStr)
        ║ Stack: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n║        "))
        ╚══════════════════════════════════════════════════════════════════════════════════
        
        """)
        
        // Additional logging for critical errors
        if error.severity == .critical {
            print("🚨 CRITICAL ERROR DETECTED - Immediate attention required!")
            
            // Log system state for critical errors
            logSystemState()
        }
    }
    
    private func logSystemState() {
        let processInfo = ProcessInfo.processInfo
        let memoryUsage = getMemoryUsage()
        
        print("""
        📊 SYSTEM STATE AT ERROR:
        - Memory Usage: \(memoryUsage.used)MB / \(memoryUsage.total)MB (\(memoryUsage.percentage)%)
        - CPU Usage: \(getCPUUsage())%
        - Active Tabs: \(getActiveTabCount())
        - Uptime: \(processInfo.systemUptime)s
        - Thermal State: \(processInfo.thermalState.rawValue)
        """)
    }
    
    private func recordError(_ error: TabError, context: [String: Any]?) {
        DispatchQueue.main.async {
            let record = ErrorRecord(
                error: error,
                timestamp: Date(),
                context: context,
                tabId: context?["tabId"] as? UUID,
                url: context?["url"] as? URL
            )
            
            self.recentErrors.insert(record, at: 0)
            if self.recentErrors.count > self.maxRecentErrors {
                self.recentErrors.removeLast()
            }
            
            self.errorStats.recordError(error)
        }
    }
    
    func shouldRetry(_ error: TabError) -> Bool {
        let errorKey = String(describing: error)
        let attempts = retryAttempts[errorKey, default: 0]
        
        guard attempts < maxRetryAttempts else {
            return false
        }
        
        switch error {
        case .networkError(let code, _, _):
            // Retry on temporary network errors
            return [408, 429, 500, 502, 503, 504].contains(code)
        case .loadingTimeout:
            return true
        case .jsEvaluationError:
            return attempts == 0 // Only retry once for JS errors
        case .faviconLoadError:
            return true
        case .audioDetectionError:
            return true
        default:
            return false
        }
    }
    
    func getRecoveryAction(_ error: TabError) -> ErrorRecoveryAction? {
        switch error {
        case .webViewNotInitialized:
            return .resetWebView
        case .navigationFailed(_, let underlyingError):
            let nsError = underlyingError as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    return .retryWithDelay(5.0)
                case NSURLErrorTimedOut:
                    return .retryWithDelay(2.0)
                case NSURLErrorBadURL:
                    return .showErrorPage("Invalid URL")
                default:
                    return .showErrorPage("Navigation failed")
                }
            }
            return .reload
        case .loadingTimeout:
            return shouldRetry(error) ? .retryWithDelay(1.0) : .reload
        case .networkError(let code, _, _):
            if [500, 502, 503, 504].contains(code) {
                return .retryWithDelay(3.0)
            } else if code == 404 {
                return .showErrorPage("Page not found")
            }
            return .reload
        case .webProcessCrash:
            return .resetWebView
        case .memoryPressure:
            return .clearCache
        case .certificateError:
            return .showErrorPage("Certificate error - connection not secure")
        case .securityError:
            return .showErrorPage("Security error - cannot load page")
        case .jsEvaluationError, .audioDetectionError, .faviconLoadError:
            return shouldRetry(error) ? .retryWithDelay(0.5) : .none
        case .zoomError:
            return .none
        case .invalidURL:
            return .showErrorPage("Invalid URL")
        case .contentBlockingError:
            return .reload
        }
    }
    
    private func executeRecoveryAction(_ action: ErrorRecoveryAction?, error: TabError, context: [String: Any]?) {
        guard let action = action else { return }
        
        print("🔧 Executing recovery action: \(action) for error: \(error.errorDescription ?? "unknown")")
        
        // Note: These would need to be implemented based on your actual tab management system
        switch action {
        case .reload:
            // Implement reload logic
            break
        case .goBack:
            // Implement go back logic
            break
        case .closeTab:
            // Implement close tab logic
            break
        case .createNewTab:
            // Implement create new tab logic
            break
        case .resetWebView:
            // Implement webview reset logic
            break
        case .clearCache:
            // Implement cache clearing logic
            break
        case .retryWithDelay(let delay):
            let errorKey = String(describing: error)
            retryAttempts[errorKey, default: 0] += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Implement retry logic
                print("🔄 Retrying after \(delay)s delay")
            }
        case .showErrorPage(let message):
            // Implement error page display logic
            print("📄 Showing error page: \(message)")
        case .none:
            break
        }
    }
    
    // MARK: - Utility Methods
    
    private func getMemoryUsage() -> (used: Int, total: Int, percentage: Int) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Int(info.resident_size) / 1024 / 1024
            let totalMB = Int(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
            let percentage = totalMB > 0 ? (usedMB * 100) / totalMB : 0
            return (usedMB, totalMB, percentage)
        } else {
            return (0, 0, 0)
        }
    }
    
    private func getCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Double(info.virtual_size) / 1024.0 / 1024.0 : 0.0
    }
    
    private func getActiveTabCount() -> Int {
        // This would need to be implemented based on your tab management system
        return 0
    }
    
    // MARK: - Error Recovery Helpers
    
    func clearErrorHistory() {
        DispatchQueue.main.async {
            self.recentErrors.removeAll()
            self.errorStats = ErrorStatistics()
            self.retryAttempts.removeAll()
        }
    }
    
    func getErrorSummary() -> String {
        let criticalCount = errorStats.errorsBySeverity[.critical, default: 0]
        let highCount = errorStats.errorsBySeverity[.high, default: 0]
        let totalCount = errorStats.totalErrors
        
        return """
        Error Summary:
        - Total Errors: \(totalCount)
        - Critical: \(criticalCount)
        - High Priority: \(highCount)
        - Average per hour: \(String(format: "%.1f", errorStats.averageErrorsPerHour))
        """
    }
}

// MARK: - Tab Error Handling Integration

extension Tab {
    // Add this property to your Tab class
     static let sharedErrorHandler = TabErrorHandler()
    
    var errorHandler: TabErrorHandler {
        return Tab.sharedErrorHandler
    }
    
    func handleError(_ error: TabError, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        fullContext["tabId"] = self.id
        fullContext["tabTitle"] = self.title
        fullContext["url"] = self.url
        fullContext["isLoading"] = self.isLoading
        fullContext["timestamp"] = Date()
        fullContext["spaceId"] = self.spaceId as Any
        fullContext["isPinned"] = self.isPinned
        fullContext["position"] = self.position
        
        errorHandler.handleError(error, context: fullContext)
    }
    
    // Enhanced favicon loading with error handling
    func loadFaviconWithErrorHandling(for url: URL) {
        guard !isLoadingFavicon else { return }
        
        do {
            isLoadingFavicon = true
            loadFavicon(for: url)
            
            // Add timeout for favicon loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                guard let self = self, self.isLoadingFavicon else { return }
                
                let error = TabError.faviconLoadError(
                    url: url, 
                    error: NSError(domain: "TabError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Favicon loading timeout"])
                )
                self.handleError(error)
                self.isLoadingFavicon = false
            }
        }
    }
    
    // Enhanced JavaScript evaluation with error handling
    func evaluateJavaScriptSafely(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        guard let webView = self.webView else {
            let error = TabError.webViewNotInitialized(tabId: self.id)
            handleError(error)
            completion?(nil, error)
            return
        }
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error = error {
                let tabError = TabError.jsEvaluationError(script: script, error: error)
                self?.handleError(tabError, context: ["script": script])
            }
            completion?(result, error)
        }
    }
    
    // Enhanced zoom with error handling
    func setZoomLevelSafely(_ newZoomLevel: CGFloat) {
        do {
            let clampedZoom = max(0.5, min(newZoomLevel, 2.0))
            guard zoomLevel != clampedZoom else { return }
            
            zoomLevel = clampedZoom
            startZoomIndicator()
            
            guard let webView = webView else {
                let error = TabError.webViewNotInitialized(tabId: self.id)
                handleError(error)
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                do {
                    webView.setMagnification(clampedZoom, centeredAt: .zero)
                } catch {
                    let zoomError = TabError.zoomError(level: clampedZoom, error: error)
                    self?.handleError(zoomError)
                }
            }
        }
    }
    
    // Enhanced audio detection with error handling
    func installEnhancedAudioDetectionSafely() {
        guard let webView = webView else {
            let error = TabError.webViewNotInitialized(tabId: self.id)
            handleError(error)
            return
        }
        
        let enhancedAudioJS = """
        (function() {
            try {
                if (window.tabAudioDetectorInstalled) {
                    return { success: true, message: 'Already installed' };
                }
                
                // Your existing enhanced audio detection code here...
                // (truncated for brevity)
                
                window.tabAudioDetectorInstalled = true;
                return { success: true, message: 'Enhanced audio detector installed' };
            } catch (error) {
                return { success: false, error: error.message };
            }
        })();
        """
        
        evaluateJavaScriptSafely(enhancedAudioJS) { [weak self] result, error in
            if let error = error {
                let audioError = TabError.audioDetectionError(error: error)
                self?.handleError(audioError)
            } else if let result = result as? [String: Any],
                      let success = result["success"] as? Bool,
                      !success,
                      let errorMessage = result["error"] as? String {
                let audioError = TabError.audioDetectionError(
                    error: NSError(domain: "AudioDetection", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                )
                self?.handleError(audioError)
            }
        }
    }
    
    // Memory pressure detection
    func checkMemoryPressure() {
        let memoryUsage = getMemoryUsage()
        if memoryUsage.percentage > 80 { // If using more than 80% memory
            let error = TabError.memoryPressure(tabId: self.id)
            handleError(error, context: [
                "memoryUsage": memoryUsage.used,
                "memoryTotal": memoryUsage.total,
                "memoryPercentage": memoryUsage.percentage
            ])
        }
    }
    
    private func getMemoryUsage() -> (used: Int, total: Int, percentage: Int) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Int(info.resident_size) / 1024 / 1024
            let totalMB = Int(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
            let percentage = totalMB > 0 ? (usedMB * 100) / totalMB : 0
            return (usedMB, totalMB, percentage)
        } else {
            return (0, 0, 0)
        }
    }
}

