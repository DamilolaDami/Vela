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
    @Published var hasDownloadsAccess: Bool = false // Track access status
    
    private var fileSystemWatcher: DispatchSourceFileSystemObject?
    private var cancellables = Set<AnyCancellable>()
    private var securityScopedDownloadsURL: URL?
    private let downloadsBookmarkKey = "DownloadsDirectoryBookmarkk"
    let downloadsURL: URL
    
    // Configuration for what constitutes "recent"
    private let recentDownloadsDays: TimeInterval = 7 // Last 7 days
    private let maxRecentDownloads: Int = 100 // Maximum number of recent downloads to load
    
    init() {
        // Get the user's Downloads folder
        downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
      
        // Set up security-scoped access first
        setupDownloadsAccess()
    }
    
    deinit {
        cleanup()
        stopWatchingDownloadsFolder()
    }
    
    // MARK: - Security Scoped Access Methods
    
    func setupDownloadsAccess() {
        // Try to restore previously granted access first
        if let restoredURL = restoreDownloadsAccess() {
            self.securityScopedDownloadsURL = restoredURL
            self.hasDownloadsAccess = true
            print("✅ Restored Downloads access from bookmark")
            loadRecentDownloads()
            startWatchingDownloadsFolder()
        } else {
            self.hasDownloadsAccess = false
            requestDownloadsAccess()
            print("⚠️ No Downloads access available")
            // Don't automatically request - let user trigger it when needed
        }
    }
    
    func requestDownloadsAccess() {
        DispatchQueue.main.async { [weak self] in
            let openPanel = NSOpenPanel()
            openPanel.title = "Allow Downloads Access"
            openPanel.message = "To manage downloads, please select your Downloads folder and click 'Open'"
            openPanel.prompt = "Grant Access"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            
            // Pre-select Downloads directory
            openPanel.directoryURL = self?.downloadsURL
            
            if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
                self?.saveDownloadsAccess(url: selectedURL)
                self?.securityScopedDownloadsURL = selectedURL
                self?.hasDownloadsAccess = true
                print("✅ Downloads access granted: \(selectedURL.path)")
                
                // Now load downloads and start watching
                self?.loadRecentDownloads()
                self?.startWatchingDownloadsFolder()
            } else {
                print("❌ User denied Downloads access")
                self?.showDownloadsAccessDeniedAlert()
            }
        }
    }
    
    private func saveDownloadsAccess(url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: downloadsBookmarkKey)
            print("💾 Saved Downloads bookmark")
        } catch {
            print("❌ Failed to save Downloads bookmark: \(error)")
        }
    }
    
    private func restoreDownloadsAccess() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: downloadsBookmarkKey) else {
            return nil
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("⚠️ Downloads bookmark is stale, need to request new access")
                return nil
            }
            
            if url.startAccessingSecurityScopedResource() {
                return url
            } else {
                print("❌ Failed to access security scoped Downloads URL")
                return nil
            }
        } catch {
            print("❌ Failed to restore Downloads bookmark: \(error)")
            return nil
        }
    }
    
    private func showDownloadsAccessDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Downloads Access Required"
        alert.informativeText = "To manage downloads, the app needs access to your Downloads folder. You can grant access later by clicking 'Allow Downloads Access' in the downloads view."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func cleanup() {
        securityScopedDownloadsURL?.stopAccessingSecurityScopedResource()
    }
    
    // MARK: - Enhanced Download Directory Access
    
    private func getAccessibleDownloadsURL() -> URL? {
        return securityScopedDownloadsURL ?? downloadsURL
    }
    
    private func testWriteAccess(to url: URL) -> Bool {
        do {
            let testURL = url.appendingPathExtension("tmp")
            try "".write(to: testURL, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testURL)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Modified File Operations
    
    private func loadRecentDownloads() {
        guard hasDownloadsAccess else {
            print("⚠️ No Downloads access - cannot load downloads")
            return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let accessibleURL = self.getAccessibleDownloadsURL() else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: accessibleURL,
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
                // If we lost access, update the status
                DispatchQueue.main.async {
                    self.hasDownloadsAccess = false
                }
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
        guard hasDownloadsAccess,
              let accessibleURL = getAccessibleDownloadsURL() else {
            print("⚠️ Cannot start watching - no Downloads access")
            return
        }
        
        let fileDescriptor = open(accessibleURL.path, O_EVTONLY)
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
    
    // MARK: - Public Methods (Enhanced with Access Checks)
    
    func addBrowserDownload(_ download: DownloadItem) {
        browserDownloads.append(download)
        
        // Post notification that a download item was added
        DispatchQueue.main.async {
            print("📢 Posting downloadItemAdded notification for: \(download.filename)")
            NotificationCenter.default.post(
                name: .downloadItemAdded,
                object: download
            )
        }
        
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
        guard hasDownloadsAccess else {
            print("⚠️ Cannot delete file - no Downloads access")
            return
        }
        
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
    
    // MARK: - Download Destination for Browser Downloads
    
    func getDownloadDestination(for filename: String) -> URL? {
        guard hasDownloadsAccess,
              let accessibleURL = getAccessibleDownloadsURL() else {
            print("⚠️ No Downloads access for destination")
            return nil
        }
        
        let destinationURL = accessibleURL.appendingPathComponent(filename)
        let uniqueURL = getUniqueFileName(for: destinationURL)
        
        // Test write access
        if testWriteAccess(to: uniqueURL) {
            return uniqueURL
        } else {
            print("❌ Lost write access to Downloads folder")
            hasDownloadsAccess = false
            return nil
        }
    }
    
    private func getUniqueFileName(for url: URL) -> URL {
        var counter = 1
        var uniqueURL = url
        let fileManager = FileManager.default
        
        while fileManager.fileExists(atPath: uniqueURL.path) {
            let filename = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newFilename = "\(filename) (\(counter))"
            uniqueURL = url.deletingLastPathComponent()
                .appendingPathComponent(newFilename)
                .appendingPathExtension(fileExtension)
            counter += 1
        }
        
        return uniqueURL
    }
    
    // MARK: - Configuration Methods
    
    func updateRecentDownloadsTimeframe(days: Int) {
        // Allow users to customize what constitutes "recent"
        // This would require updating the private property and refreshing
    }
}

// MARK: - SystemDownloadItem Model (Unchanged)

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
