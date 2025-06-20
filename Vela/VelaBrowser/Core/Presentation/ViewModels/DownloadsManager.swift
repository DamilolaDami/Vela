//
//  DownloadsManager.swift
//  Vela
//
//  Created by damilola on 6/20/25.
//


import Foundation
import Combine
import AppKit

class DownloadsManager: ObservableObject {
    @Published var allDownloads: [SystemDownloadItem] = []
    @Published var browserDownloads: [DownloadItem] = [] // Your existing browser downloads
    
    private var fileSystemWatcher: DispatchSourceFileSystemObject?
    private var cancellables = Set<AnyCancellable>()
    let downloadsURL: URL
    
    // Configuration for what constitutes "recent"
    private let recentDownloadsDays: TimeInterval = 7 // Last 7 days
    private let maxRecentDownloads: Int = 100 // Maximum number of recent downloads to load
    
    init() {
        // Get the user's Downloads folder
        downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
        
        loadRecentDownloads()
        startWatchingDownloadsFolder()
    }
    
    deinit {
        stopWatchingDownloadsFolder()
    }
    
    private func loadRecentDownloads() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: self.downloadsURL,
                    includingPropertiesForKeys: [
                        .contentModificationDateKey,
                        .creationDateKey,
                        .fileSizeKey,
                        .isDirectoryKey,
                        .contentTypeKey
                    ],
                    options: [.skipsHiddenFiles]
                )
                
                let cutoffDate = Date().addingTimeInterval(-self.recentDownloadsDays * 24 * 60 * 60)
                
                let recentDownloads = fileURLs.compactMap { url -> SystemDownloadItem? in
                    return self.createSystemDownloadItem(from: url, cutoffDate: cutoffDate)
                }
                .sorted { $0.dateCreated > $1.dateCreated } // Sort by creation date (most recent first)
                .prefix(self.maxRecentDownloads) // Limit the number of items
                .map { $0 }
                
                DispatchQueue.main.async {
                    self.allDownloads = Array(recentDownloads)
                    print("📁 Loaded \(recentDownloads.count) recent downloads from the last \(Int(self.recentDownloadsDays)) days")
                }
                
            } catch {
                print("❌ Error loading downloads folder: \(error)")
            }
        }
    }
    
    private func createSystemDownloadItem(from url: URL, cutoffDate: Date) -> SystemDownloadItem? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .contentModificationDateKey,
                .creationDateKey,
                .fileSizeKey,
                .isDirectoryKey,
                .contentTypeKey
            ])
            
            // Skip directories
            if resourceValues.isDirectory == true {
                return nil
            }
            
            let dateCreated = resourceValues.creationDate ?? Date()
            let dateModified = resourceValues.contentModificationDate ?? dateCreated
            
            // Only include files created after the cutoff date
            guard dateCreated >= cutoffDate else {
                return nil
            }
            
            let fileSize = resourceValues.fileSize ?? 0
            let contentType = resourceValues.contentType?.identifier
            
            return SystemDownloadItem(
                url: url,
                filename: url.lastPathComponent,
                fileSize: Int64(fileSize),
                dateModified: dateModified,
                dateCreated: dateCreated,
                contentType: contentType
            )
            
        } catch {
            print("❌ Error getting file attributes for \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func startWatchingDownloadsFolder() {
        let fileDescriptor = open(downloadsURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("❌ Failed to open Downloads folder for monitoring")
            return
        }
        
        fileSystemWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .delete, .rename],
            queue: DispatchQueue.global(qos: .background)
        )
        
        fileSystemWatcher?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }
        
        fileSystemWatcher?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileSystemWatcher?.resume()
        print("👀 Started watching Downloads folder")
    }
    
    private func stopWatchingDownloadsFolder() {
        fileSystemWatcher?.cancel()
        fileSystemWatcher = nil
    }
    
    private func handleFileSystemEvent() {
        // Debounce rapid file system events
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshDownloads()
        }
    }
    
    private func refreshDownloads() {
        loadRecentDownloads()
    }
    
    // MARK: - Public Methods
    
    func addBrowserDownload(_ download: DownloadItem) {
        browserDownloads.append(download)
        
        // When browser download completes, refresh the system downloads
        // to pick up the newly downloaded file
        download.$isCompleted
            .sink { [weak self] isCompleted in
                if isCompleted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.refreshDownloads()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func removeBrowserDownload(_ download: DownloadItem) {
        browserDownloads.removeAll { $0.id == download.id }
    }
    
    func clearAllBrowserDownloads() {
        for download in browserDownloads where download.isDownloading {
            download.download?.cancel { _ in }
        }
        browserDownloads.removeAll()
    }
    
    func deleteFileFromSystem(_ item: SystemDownloadItem) {
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            // Remove from our list
            allDownloads.removeAll { $0.id == item.id }
            print("🗑️ Moved \(item.filename) to trash")
        } catch {
            print("❌ Failed to delete \(item.filename): \(error)")
        }
    }
    
    func showInFinder(_ item: SystemDownloadItem) {
        NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
    }
    
    func openFile(_ item: SystemDownloadItem) {
        NSWorkspace.shared.open(item.url)
    }
    
    // MARK: - Configuration Methods
    
    func updateRecentDownloadsTimeframe(days: Int) {
        // Allow users to customize what constitutes "recent"
        // This would require updating the private property and refreshing
    }
}

// MARK: - SystemDownloadItem Model

class SystemDownloadItem: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let filename: String
    let fileSize: Int64
    let dateModified: Date
    let dateCreated: Date
    let contentType: String?
    
    init(url: URL, filename: String, fileSize: Int64, dateModified: Date, dateCreated: Date, contentType: String?) {
        self.url = url
        self.filename = filename
        self.fileSize = fileSize
        self.dateModified = dateModified
        self.dateCreated = dateCreated
        self.contentType = contentType
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var isRecentlyDownloaded: Bool {
        // Consider files downloaded in the last 24 hours as "recent"
        return dateCreated.timeIntervalSinceNow > -86400
    }
    
    var fileExtension: String {
        return (filename as NSString).pathExtension.lowercased()
    }
    
    var daysSinceDownload: Int {
        return Calendar.current.dateComponents([.day], from: dateCreated, to: Date()).day ?? 0
    }
}
