// Fixed DownloadItem.swift
import Foundation
import WebKit

class DownloadItem: NSObject, ObservableObject, Identifiable {
    let id = UUID()
    let filename: String
    let url: URL
    @Published var progress: Double = 0.0
    @Published var status: String = "Starting..."
    @Published var isDownloading: Bool = true
    @Published var isCompleted: Bool = false
    @Published var hasError: Bool = false
    @Published var bytesReceived: Int64 = 0
    @Published var totalBytes: Int64 = 0
    
    private var timeoutTimer: Timer?
    private let timeoutInterval: TimeInterval = 300.0 // 5 minutes instead of 30 seconds
    private var hasSetupKVO = false

    // Make download property strong to prevent deallocation
    var download: WKDownload? {
        didSet {
            if let oldDownload = oldValue, hasSetupKVO {
                oldDownload.progress.removeObserver(self, forKeyPath: "fractionCompleted")
                hasSetupKVO = false
            }
            
            if let newDownload = download, !hasSetupKVO {
                setupKVO(for: newDownload)
            }
        }
    }

    init(filename: String, url: URL, download: WKDownload? = nil) {
        self.filename = filename
        self.url = url
        super.init()
        
        // Set download and setup KVO immediately
        if let download = download {
            self.download = download
            setupKVO(for: download)
        }
        
        startTimeoutTimer()
        print("📦 DownloadItem initialized: \(filename)")
    }
    
    private func setupKVO(for download: WKDownload) {
        guard !hasSetupKVO else { return }
        
        do {
            download.progress.addObserver(
                self,
                forKeyPath: "fractionCompleted",
                options: [.new, .initial],
                context: nil
            )
            hasSetupKVO = true
            print("🔍 KVO setup completed for download: \(filename)")
            
            // Get initial progress value
            DispatchQueue.main.async { [weak self] in
                let initialProgress = download.progress.fractionCompleted
                self?.updateProgressInternal(initialProgress)
                print("📈 Initial progress: \(initialProgress * 100)% for \(self?.filename ?? "unknown")")
            }
        } catch {
            print("❌ Failed to setup KVO for download: \(filename), error: \(error)")
        }
    }

    private func startTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("❌ Download timeout for: \(self.filename)")
            self.fail(with: NSError(
                domain: "DownloadError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Download timed out after \(self.timeoutInterval) seconds"]
            ))
        }
    }
    
    private func resetTimeoutTimer() {
        timeoutTimer?.invalidate()
        startTimeoutTimer()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "fractionCompleted" else { return }
        
        if let progress = change?[.newKey] as? Double {
            DispatchQueue.main.async { [weak self] in
                self?.updateProgressInternal(progress)
               
            }
        }
    }
    
    private func updateProgressInternal(_ progress: Double) {
        guard !isCompleted && !hasError else { return }
        
        self.progress = progress
        resetTimeoutTimer() // Reset timeout on any progress
        
        // Update bytes received based on progress
        if totalBytes > 0 {
            let currentBytes = Int64(Double(totalBytes) * progress)
            self.bytesReceived = currentBytes
            
            // Format the status with "X out of Y MB" format
            let (receivedValue, receivedUnit) = formatBytes(currentBytes)
            let (totalValue, totalUnit) = formatBytes(totalBytes)
            
            // Use the larger unit for consistency
            if totalUnit == "GB" || (totalUnit == "MB" && receivedUnit != "GB") {
                let receivedInTargetUnit = convertBytesToUnit(currentBytes, targetUnit: totalUnit)
                let totalInTargetUnit = convertBytesToUnit(totalBytes, targetUnit: totalUnit)
                self.status = String(format: "%.1f out of %.1f %@ (%.0f%%)",
                                   receivedInTargetUnit, totalInTargetUnit, totalUnit, progress * 100)
            } else {
                self.status = String(format: "%.1f %@ out of %.1f %@ (%.0f%%)",
                                   receivedValue, receivedUnit, totalValue, totalUnit, progress * 100)
            }
        } else {
            // Fallback when total bytes is unknown
            if bytesReceived > 0 {
                let (receivedValue, receivedUnit) = formatBytes(bytesReceived)
                self.status = String(format: "%.1f %@ downloaded (%.0f%%)",
                                   receivedValue, receivedUnit, progress * 100)
            } else {
                self.status = String(format: "Downloading... %.0f%%", progress * 100)
            }
        }
    }
    
    // Helper function to format bytes into appropriate units
    private func formatBytes(_ bytes: Int64) -> (Double, String) {
        let kb: Double = 1024
        let mb = kb * 1024
        let gb = mb * 1024
        
        let bytesDouble = Double(bytes)
        
        if bytesDouble >= gb {
            return (bytesDouble / gb, "GB")
        } else if bytesDouble >= mb {
            return (bytesDouble / mb, "MB")
        } else if bytesDouble >= kb {
            return (bytesDouble / kb, "KB")
        } else {
            return (bytesDouble, "bytes")
        }
    }
    
    // Helper function to convert bytes to a specific unit
    private func convertBytesToUnit(_ bytes: Int64, targetUnit: String) -> Double {
        let bytesDouble = Double(bytes)
        switch targetUnit {
        case "GB":
            return bytesDouble / (1024 * 1024 * 1024)
        case "MB":
            return bytesDouble / (1024 * 1024)
        case "KB":
            return bytesDouble / 1024
        default:
            return bytesDouble
        }
    }

    // This method is called from WebViewCoordinator delegate methods
    func updateProgress(_ progress: Double, bytesReceived: Int64 = 0, totalBytes: Int64 = 0) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📈 Manual progress update: \(progress * 100)% (\(bytesReceived)/\(totalBytes) bytes) for \(self.filename)")
            
            // Update total bytes if provided and different
            if totalBytes > 0 && self.totalBytes != totalBytes {
                self.totalBytes = totalBytes
            }
            
            // Update bytes received if provided
            if bytesReceived > 0 {
                self.bytesReceived = bytesReceived
            }
            
            // Update progress using internal method
            self.updateProgressInternal(progress)
        }
    }

    func complete() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("✅ Download completed: \(self.filename)")
            
            self.timeoutTimer?.invalidate()
            self.isDownloading = false
            self.isCompleted = true
            self.progress = 1.0
            
            // Show final size in completed status
            if self.totalBytes > 0 {
                let (totalValue, totalUnit) = self.formatBytes(self.totalBytes)
                self.status = String(format: "Completed (%.1f %@)", totalValue, totalUnit)
            } else {
                self.status = "Completed"
            }
        }
    }

    func fail(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("❌ Download failed: \(self.filename), error: \(error)")
            
            self.timeoutTimer?.invalidate()
            self.isDownloading = false
            self.hasError = true
            self.status = "Failed: \(error.localizedDescription)"
        }
    }

    deinit {
        print("🗑️ Deinit DownloadItem: \(filename)")
        timeoutTimer?.invalidate()
        
        if let download = download, hasSetupKVO {
            download.progress.removeObserver(self, forKeyPath: "fractionCompleted")
        }
    }
}
