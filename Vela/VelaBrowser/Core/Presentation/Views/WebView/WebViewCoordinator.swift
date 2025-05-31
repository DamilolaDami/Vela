// MARK: - Fixed WebViewCoordinator with proper download support
import WebKit
import AppKit
import Foundation

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    var parent: WebViewRepresentable?
    var browserViewModel: BrowserViewModel?
    private let tabId: UUID
    private var webView: WKWebView?
    private var isObserving = false
    private var lastRequestedURL: URL?
    private var pendingNavigation: WKNavigation?
    
    // Download tracking
    private var downloadAssociations: [WKDownload: DownloadItem] = [:]

    init(_ parent: WebViewRepresentable, tab: Tab) {
        self.parent = parent
        self.tabId = tab.id
        super.init()
    }
    
    // MARK: - Observer Management (unchanged)
    func addObservers(to webView: WKWebView) {
        guard !isObserving else { return }
        
        if let previousWebView = self.webView, previousWebView != webView {
            removeObservers(from: previousWebView)
        }
        
        self.webView = webView
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [.new, .initial], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new, .initial], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: [.new, .initial], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new, .initial], context: nil)
        
        isObserving = true
    }
    
    func removeObservers(from webView: WKWebView) {
        guard isObserving, self.webView == webView else { return }
        
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        
        isObserving = false
        self.webView = nil
    }
    
    // MARK: - URL Loading (unchanged)
    func loadURL(_ url: URL, in webView: WKWebView) {
        guard url != lastRequestedURL else { return }
        
        if let pending = pendingNavigation {
            if webView.url != url {
                lastRequestedURL = url
                let request = URLRequest(url: url)
                pendingNavigation = webView.load(request)
            }
        } else {
            lastRequestedURL = url
            let request = URLRequest(url: url)
            pendingNavigation = webView.load(request)
        }
    }

    // MARK: - KVO (unchanged)
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView,
              webView == self.webView,
              let parent = self.parent,
              parent.tab.id == self.tabId else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let parent = self.parent,
                  parent.tab.id == self.tabId else { return }

            let tab = parent.tab
            var tabUpdated = false
            
            switch keyPath {
            case #keyPath(WKWebView.isLoading):
                let loading = webView.isLoading
                tab.isLoading = loading
                parent.isLoading = loading
                tabUpdated = true
            case #keyPath(WKWebView.estimatedProgress):
                parent.estimatedProgress = webView.estimatedProgress
            case #keyPath(WKWebView.title):
                if let newTitle = webView.title, !newTitle.isEmpty, tab.title != newTitle {
                    tab.title = newTitle
                    tabUpdated = true
                } else if webView.title?.isEmpty == true || webView.title == nil {
                    tab.title = "Untitled"
                    tabUpdated = true
                }
            case #keyPath(WKWebView.url):
                if let newURL = webView.url, tab.url != newURL {
                    tab.url = newURL
                    self.lastRequestedURL = newURL
                    tabUpdated = true
                }
            default:
                break
            }
            if let audioWebView = webView as? AudioObservingWebView {
                let isAudioPlaying = audioWebView.isPlayingAudioPrivate
                if tab.isPlayingAudio != isAudioPlaying {
                    tab.isPlayingAudio = isAudioPlaying
                    print("🎧 Audio state updated via _isPlayingAudio: \(isAudioPlaying)")
                }
            }

            if tabUpdated {
                self.browserViewModel?.updateTab(tab)
            }
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard webView == self.webView,
              let parent = self.parent,
              parent.tab.id == self.tabId else { return }
        
        pendingNavigation = navigation
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let parent = self.parent,
                  parent.tab.id == self.tabId else { return }
            
            parent.tab.isLoading = true
            parent.isLoading = true
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView == self.webView,
              let parent = self.parent,
              parent.tab.id == self.tabId else { return }
        
        if pendingNavigation == navigation {
            pendingNavigation = nil
        }
        
        // Inject JavaScript to ensure full-screen API is available
        let fullscreenScript = """
        (function() {
            var element = document.documentElement;
            if (element.requestFullscreen) {
                element.requestFullscreen = element.requestFullscreen ||
                    element.webkitRequestFullscreen ||
                    element.mozRequestFullScreen ||
                    element.msRequestFullscreen ||
                    function() { return Promise.reject(new Error('Fullscreen API is not supported')); };
            }
        })();
        """
        webView.evaluateJavaScript(fullscreenScript) { _, error in
            if let error = error {
                print("Error injecting fullscreen script: \(error)")
            } else {
                print("Fullscreen script injected successfully")
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let parent = self.parent,
                  parent.tab.id == self.tabId else { return }
            
            parent.tab.isLoading = false
            parent.isLoading = false
            parent.estimatedProgress = 1.0
            parent.tab.reloadFavicon()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(navigation: navigation, error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(navigation: navigation, error: error)
    }
    
    // MARK: - FIXED Download Policy Decision
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("🔍 Navigation response for: \(navigationResponse.response.url?.absoluteString ?? "unknown")")
        print("🔍 MIME type: \(navigationResponse.response.mimeType ?? "unknown")")
        
        let mimeType = navigationResponse.response.mimeType ?? ""
        let isDownload = shouldDownloadFile(mimeType: mimeType, response: navigationResponse.response)
        
        print("🔍 Should download: \(isDownload)")
        
        if isDownload {
            print("📥 Triggering download for: \(navigationResponse.response.url?.absoluteString ?? "unknown")")
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }
    
    // MARK: - FIXED Download Delegate Methods
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        print("📥 Navigation response became download")
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        print("📥 Navigation action became download")
        download.delegate = self
    }
    
    // MARK: - WKDownloadDelegate Implementation
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        print("📥 Download destination requested for: \(suggestedFilename)")
        
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            print("❌ Could not access Downloads folder")
            completionHandler(nil)
            return
        }
        
        let destinationURL = downloadsURL.appendingPathComponent(suggestedFilename)
        let finalURL = getUniqueFileName(for: destinationURL)
        
        print("📁 Download destination: \(finalURL.path)")
        
        // Create download item
        DispatchQueue.main.async { [weak self] in
            let downloadItem = DownloadItem(filename: finalURL.lastPathComponent, url: finalURL, download: download)
            self?.browserViewModel?.addDownload(downloadItem)
            self?.downloadAssociations[download] = downloadItem
        }
        
        completionHandler(finalURL)
    }
    
    func download(_ download: WKDownload, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("📥 Download authentication challenge")
        completionHandler(.performDefaultHandling, nil)
    }
    
    func download(_ download: WKDownload, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        
        print("📥 Download progress: \(Int(progress * 100))% (\(totalBytesWritten)/\(totalBytesExpectedToWrite) bytes)")
        
        DispatchQueue.main.async { [weak self] in
            if let downloadItem = self?.downloadAssociations[download] {
                downloadItem.updateProgress(progress, bytesReceived: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
            }
        }
    }
    
    func download(_ download: WKDownload, didFinishWith error: Error?) {
        print("📥 Download finished with error: \(error?.localizedDescription ?? "none")")
        
        DispatchQueue.main.async { [weak self] in
            if let downloadItem = self?.downloadAssociations[download] {
                if let error = error {
                    downloadItem.fail(with: error)
                } else {
                    downloadItem.complete()
                }
                // Clean up association
                self?.downloadAssociations.removeValue(forKey: download)
            }
        }
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        print("✅ Download completed successfully")
        
        DispatchQueue.main.async { [weak self] in
            if let downloadItem = self?.downloadAssociations[download] {
                downloadItem.complete()
                // Clean up association
                self?.downloadAssociations.removeValue(forKey: download)
            }
        }
    }
    
    // MARK: - IMPROVED Download Detection
    private func shouldDownloadFile(mimeType: String, response: URLResponse) -> Bool {
        // Check Content-Disposition header first (most reliable)
        if let httpResponse = response as? HTTPURLResponse {
            if let contentDisposition = httpResponse.allHeaderFields["Content-Disposition"] as? String {
                let disposition = contentDisposition.lowercased()
                if disposition.contains("attachment") || disposition.contains("filename=") {
                    print("📎 Content-Disposition indicates download: \(contentDisposition)")
                    return true
                }
            }
        }
        
        // Common download MIME types
        let downloadMimeTypes = [
            // Images
            "image/png", "image/jpeg", "image/jpg", "image/gif", "image/webp",
            "image/svg+xml", "image/bmp", "image/tiff", "image/ico",
            // Documents
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-powerpoint",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "text/plain", "text/csv",
            // Archives
            "application/zip", "application/x-zip-compressed",
            "application/x-rar-compressed", "application/x-7z-compressed",
            "application/gzip", "application/x-tar",
            // Media
            "video/mp4", "video/avi", "video/mov", "video/wmv", "video/webm", "video/mkv",
            "audio/mp3", "audio/wav", "audio/aac", "audio/ogg", "audio/flac", "audio/m4a",
            // Other
            "application/octet-stream",
            "application/x-executable",
            "application/x-msdos-program"
        ]
        
        let normalizedMimeType = mimeType.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldDownload = downloadMimeTypes.contains(normalizedMimeType)
        
        print("🔍 MIME type '\(normalizedMimeType)': \(shouldDownload ? "DOWNLOAD" : "DISPLAY")")
        
        return shouldDownload
    }
    
    // MARK: - Helper Methods
    private func getUniqueFileName(for url: URL) -> URL {
        var finalURL = url
        var counter = 1
        
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newName = "\(nameWithoutExtension) (\(counter))"
            
            if fileExtension.isEmpty {
                finalURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            } else {
                finalURL = url.deletingLastPathComponent().appendingPathComponent("\(newName).\(fileExtension)")
            }
            
            counter += 1
        }
        
        return finalURL
    }
    
    private func handleNavigationError(navigation: WKNavigation?, error: Error) {
        guard let parent = self.parent,
              parent.tab.id == self.tabId else { return }
        
        if pendingNavigation == navigation {
            pendingNavigation = nil
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let parent = self.parent,
                  parent.tab.id == self.tabId else { return }
            
            parent.tab.isLoading = false
            parent.isLoading = false
            parent.estimatedProgress = 0
        }
        
        let nsError = error as NSError
        if nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled {
            print("Navigation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - WKUIDelegate - New Tab Support
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url,
              let browserViewModel = self.browserViewModel else { return nil }
        
        DispatchQueue.main.async {
            let inBackground = navigationAction.modifierFlags.contains(.command)
            browserViewModel.createNewTab(with: url, inBackground: inBackground)
        }
        
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if shouldOpenInNewTab(navigationAction: navigationAction) {
            decisionHandler(.cancel)
            
            if let url = navigationAction.request.url,
               let browserViewModel = self.browserViewModel {
                DispatchQueue.main.async {
                    let inBackground = navigationAction.modifierFlags.contains(.shift)
                    browserViewModel.createNewTab(with: url, inBackground: inBackground)
                }
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    private func shouldOpenInNewTab(navigationAction: WKNavigationAction) -> Bool {
        if navigationAction.modifierFlags.contains(.command) {
            return true
        }
        
        if navigationAction.modifierFlags.contains([.command, .shift]) {
            return true
        }
        
        if navigationAction.buttonNumber == 2 {
            return true
        }
        
        if navigationAction.targetFrame == nil {
            return true
        }
        
        return false
    }

    deinit {
        if let webView = self.webView {
            removeObservers(from: webView)
        }
        pendingNavigation = nil
        downloadAssociations.removeAll()
        print("WebViewCoordinator deinit for tab: \(tabId)")
    }
}



// MARK: - FIXED BrowserViewModel Extension
extension BrowserViewModel {
    func addDownload(_ downloadItem: DownloadItem) {
        downloads.append(downloadItem)
        print("📥 Added download: \(downloadItem.filename)")
    }
    
    var activeDownloadsCount: Int {
        return downloads.filter { $0.isDownloading }.count
    }
    
    func removeDownload(_ download: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            // Cancel download if still in progress
            if download.isDownloading {
                download.download?.cancel { _ in }
            }
            downloads.remove(at: index)
        }
    }
    
    func clearAllDownloads() {
        // Cancel any active downloads
        for download in downloads where download.isDownloading {
            download.download?.cancel { _ in }
        }
        downloads.removeAll()
    }
    
    func showDownloadInFinder(_ download: DownloadItem) {
        NSWorkspace.shared.selectFile(download.url.path, inFileViewerRootedAtPath: "")
    }
}
