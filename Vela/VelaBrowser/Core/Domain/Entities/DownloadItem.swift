// Updated DownloadItem.swift
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
    
    weak var download: WKDownload? {
        didSet {
            if let download = download {
                // Observe download progress
                download.progress.addObserver(self, forKeyPath: "fractionCompleted", options: [.new], context: nil)
            }
        }
    }
    
    init(filename: String, url: URL, download: WKDownload? = nil) {
        self.filename = filename
        self.url = url
        super.init()
        self.download = download
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "fractionCompleted" {
            DispatchQueue.main.async {
                if let progress = self.download?.progress.fractionCompleted {
                    self.progress = progress
                    self.status = "Downloading... \(Int(progress * 100))%"
                }
            }
        }
    }
    
    func updateProgress(_ progress: Double, bytesReceived: Int64 = 0, totalBytes: Int64 = 0) {
        DispatchQueue.main.async {
            self.progress = progress
            self.bytesReceived = bytesReceived
            self.totalBytes = totalBytes
            
            if totalBytes > 0 {
                let mbReceived = Double(bytesReceived) / 1024.0 / 1024.0
                let mbTotal = Double(totalBytes) / 1024.0 / 1024.0
                self.status = String(format: "Downloading... %.1f/%.1f MB", mbReceived, mbTotal)
            } else {
                self.status = "Downloading... \(Int(progress * 100))%"
            }
        }
    }
    
    func complete() {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.isCompleted = true
            self.progress = 1.0
            self.status = "Completed"
        }
    }
    
    func fail(with error: Error) {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.hasError = true
            self.status = "Failed: \(error.localizedDescription)"
        }
    }
    
    deinit {
        download?.progress.removeObserver(self, forKeyPath: "fractionCompleted")
    }
}


// MARK: - Updated BrowserViewModel Extensions
extension BrowserViewModel {
    private var downloadAssociations: [WKDownload: DownloadItem] {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.downloadAssociations) as? [WKDownload: DownloadItem] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.downloadAssociations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
 
    func associateDownload(_ download: WKDownload, with item: DownloadItem) {
        downloadAssociations[download] = item
    }
    
    func getDownloadItem(for download: WKDownload) -> DownloadItem? {
        return downloadAssociations[download]
    }
    
    func updateDownloadStatus(_ download: WKDownload, error: Error?) {
        if let downloadItem = getDownloadItem(for: download) {
            if let error = error {
                downloadItem.fail(with: error)
            } else {
                downloadItem.complete()
            }
        }
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        if let downloadItem = getDownloadItem(for: download) {
            downloadItem.complete()
        }
    }
    
 
}

// MARK: - Associated Object Keys
private struct AssociatedKeys {
    static var downloadAssociations = "downloadAssociations"
}

// Add this import at the top if not already present
