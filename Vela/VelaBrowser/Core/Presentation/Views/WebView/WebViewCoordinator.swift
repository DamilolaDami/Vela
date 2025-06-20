@preconcurrency import WebKit
import AppKit
import Foundation
import Combine
import AVFoundation


class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    var parent: WebViewRepresentable?
    var browserViewModel: BrowserViewModel?
    var suggestionViewModel: AddressBarViewModel?
    private let tabId: UUID
    private var webView: WKWebView?
    private var isObserving = false
    private var lastRequestedURL: URL?
    private var pendingNavigation: WKNavigation?
    private var zoomCancellable: AnyCancellable?
    private var lastMagnification: CGFloat = 1.0

// Download tracking
private var downloadAssociations: [WKDownload: DownloadItem] = [:]

init(_ parent: WebViewRepresentable, tab: Tab) {
    self.parent = parent
    self.tabId = tab.id
    super.init()
    setupZoomObserver(tab: tab)
}

// MARK: - Observer Management
func addObservers(to webView: WKWebView) {
    guard !isObserving else { return }
    if let previousWebView = self.webView {
        removeObservers(from: previousWebView)
    }
    
    self.webView = webView
    webView.addObserver(self, forKeyPath: #keyPath(WKWebView.magnification), options: [.new], context: nil)
    webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [.new, .initial], context: nil)
    webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new, .initial], context: nil)
    webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: [.new, .initial], context: nil)
    webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new, .initial], context: nil)
    
    // Apply initial zoom level with error handling
    DispatchQueue.main.async { [weak self] in
        guard let self = self, let parent = self.parent else { return }
        do {
            webView.setMagnification(parent.tab.zoomLevel, centeredAt: .zero)
        } catch {
            parent.tab.handleError(TabError.zoomError(level: parent.tab.zoomLevel, error: error), context: ["webView": webView])
        }
    }
    
    isObserving = true
}

func removeObservers(from webView: WKWebView) {
    guard isObserving, self.webView == webView else { return }
    zoomCancellable?.cancel()
    webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
    webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
    webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
    webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.magnification))
    isObserving = false
    self.webView = nil
}

private func setupZoomObserver(tab: Tab) {
    zoomCancellable = tab.$zoomLevel
        .sink { [weak self] newZoomLevel in
            guard let self = self,
                  let webView = self.webView,
                  tab.id == self.tabId else { return }
            DispatchQueue.main.async {
                do {
                    webView.setMagnification(newZoomLevel, centeredAt: .zero)
                    tab.startZoomIndicator()
                    self.parent?.suggestionViewModel.cancelSuggestions()
                } catch {
                    tab.handleError(TabError.zoomError(level: newZoomLevel, error: error), context: ["webView": webView])
                }
            }
        }
}

// MARK: - URL Loading
func loadURL(_ url: URL, in webView: WKWebView) {
    guard url != lastRequestedURL else { return }
    guard let parent = self.parent, parent.tab.id == self.tabId else { return }
    guard !webView.isLoading else {
        print("⚠️ WebView is already loading; queuing URL: \(url)")
        return
    }
    
    parent.suggestionViewModel.cancelSuggestions()
    lastRequestedURL = url
    let request = URLRequest(url: url)
    pendingNavigation = webView.load(request)
}

// MARK: - KVO
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
            tab.isLoading = webView.isLoading
            parent.isLoading = webView.isLoading
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
                print("🔗 WebView URL changed to: \(newURL.absoluteString)")
                tab.url = newURL
                self.lastRequestedURL = newURL
                tabUpdated = true
            }
            
        case #keyPath(WKWebView.magnification):
            if let newMagnification = change?[.newKey] as? CGFloat,
               newMagnification != self.lastMagnification {
                self.lastMagnification = newMagnification
                tab.setZoomLevelSafely(newMagnification)
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
                tabUpdated = true
            }
        }
        parent.browserViewModel.detectedSechema.scanSchemas(in: webView)
        parent.suggestionViewModel.cancelSuggestions()
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
        parent.suggestionViewModel.cancelSuggestions()
    }
}

func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    guard webView == self.webView,
          let parent = self.parent,
          parent.tab.id == self.tabId else { return }
    
    if pendingNavigation == navigation {
        pendingNavigation = nil
    }
    let newURL = webView.url
    let oldHost = parent.tab.url?.host
    let newHost = newURL?.host
    
    // Inject JavaScript to ensure full-screen API is available with error handling
    let fullscreenJS = """
    (function() {
        function enableFullscreen(element) {
            element.requestFullscreen = element.requestFullscreen ||
                element.webkitRequestFullscreen ||
                element.mozRequestFullScreen ||
                element.msRequestFullscreen ||
                function() { return Promise.reject(new Error('Fullscreen API is not supported')); };
            element.webkitEnterFullscreen = element.webkitEnterFullscreen ||
                function() { if (element.requestFullscreen) { element.requestFullscreen(); } };
        }
        document.querySelectorAll('*').forEach(enableFullscreen);
        enableFullscreen(document.documentElement);
        document.querySelectorAll('video').forEach(enableFullscreen);
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === 1) {
                        enableFullscreen(node);
                        if (node.tagName === 'VIDEO') { enableFullscreen(node); }
                    }
                });
            });
        });
        observer.observe(document, { childList: true, subtree: true });
        window.webkitSupportsFullscreen = true;
        window.webkitEnterFullscreen = function() { document.documentElement.requestFullscreen(); };
    })();
    """
    
    parent.tab.evaluateJavaScriptSafely(fullscreenJS) { [weak self] _, error in
        if let error = error {
            print("⚠️ Fullscreen API injection failed; some features may be unavailable")
            self?.parent?.tab.handleError(TabError.jsEvaluationError(script: "Fullscreen API injection", error: error), context: ["webView": webView])
        }
    }
    
    DispatchQueue.main.async { [weak self] in
        guard let self = self,
              let parent = self.parent,
              parent.tab.id == self.tabId else { return }
        
        parent.tab.isLoading = false
        parent.isLoading = false
        parent.estimatedProgress = 1.0
        parent.suggestionViewModel.cancelSuggestions()
        if oldHost != newHost || parent.tab.favicon == nil {
            if let newURL = newURL{
                parent.tab.loadFaviconWithErrorHandling(for: newURL )
                parent.tab.reloadFavicon()
            }
        }
    }
}

func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
    Task {
        let granted = await requestSystemPermission(for: type)
        DispatchQueue.main.async {
            if granted {
                print("✅ Permission granted for \(type)")
                decisionHandler(.grant)
            } else {
                print("❌ Permission denied for \(type)")
                decisionHandler(.deny)
            }
        }
    }
}

func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    handleNavigationError(navigation: navigation, error: error)
}

func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    handleNavigationError(navigation: navigation, error: error)
}

func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    guard let parent = self.parent, parent.tab.id == self.tabId else { return }
    parent.tab.handleError(TabError.webProcessCrash(tabId: tabId), context: ["webView": webView, "url": webView.url as Any])
}

// MARK: - Download Policy Decision
func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
    let mimeType = navigationResponse.response.mimeType ?? ""
    let isDownload = shouldDownloadFile(mimeType: mimeType, response: navigationResponse.response)
    
    if isDownload {
        decisionHandler(.download)
    } else {
        decisionHandler(.allow)
    }
}

// MARK: - Download Delegate Methods
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
    print("📥 Download deciding destination for: \(suggestedFilename)")
    
    guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
        print("❌ Downloads directory inaccessible")
        completionHandler(nil)
        return
    }
    
    let destinationURL = downloadsURL.appendingPathComponent(suggestedFilename)
    let finalURL = getUniqueFileName(for: destinationURL)
    
    // Test write access
    do {
        let testURL = finalURL.appendingPathExtension("tmp")
        try "".write(to: testURL, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(at: testURL)
        print("📁 Write access confirmed for: \(finalURL.path)")
    } catch {
        print("❌ No write access to: \(finalURL.path), error: \(error)")
        completionHandler(nil)
        return
    }
    
    // Create DownloadItem with the download reference
    DispatchQueue.main.async { [weak self] in
        guard let self = self, let parent = self.parent else {
            completionHandler(nil)
            return
        }
        
        let contentLength = response.expectedContentLength > 0 ? response.expectedContentLength : 0
        let downloadItem = DownloadItem(filename: finalURL.lastPathComponent, url: finalURL, download: download)
        downloadItem.totalBytes = contentLength
        
        print("🔗 Created download item: \(downloadItem.filename) with expected size: \(contentLength) bytes")
        
        self.downloadAssociations[download] = downloadItem
        self.browserViewModel?.addDownload(downloadItem)
        print("📥 Added download to browser: \(downloadItem.filename)")
    }
    
    completionHandler(finalURL)
}

func download(_ download: WKDownload, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
    
    print("📥 Download progress: \(String(format: "%.1f", progress * 100))% (\(totalBytesWritten)/\(totalBytesExpectedToWrite) bytes)")
    
    DispatchQueue.main.async { [weak self] in
        guard let downloadItem = self?.downloadAssociations[download] else {
            print("❌ No download item found for progress update")
            return
        }
        
        downloadItem.updateProgress(progress, bytesReceived: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
    }
}

func download(_ download: WKDownload, didCancel error: Error) {
    print("🚫 Download canceled: \(error.localizedDescription)")
    DispatchQueue.main.async { [weak self] in
        guard let self = self, let downloadItem = self.downloadAssociations[download] else { return }
        downloadItem.fail(with: error)
        self.downloadAssociations.removeValue(forKey: download)
    }
}

func download(_ download: WKDownload, didFinishWith error: Error?) {
    print("📥 Download finished: \(error?.localizedDescription ?? "Success")")
    
    DispatchQueue.main.async { [weak self] in
        guard let self = self, let downloadItem = self.downloadAssociations[download] else {
            print("❌ No download item found for finish callback")
            return
        }
        
        if let error = error {
            print("❌ Download failed: \(downloadItem.filename), error: \(error)")
            downloadItem.fail(with: error)
            self.parent?.tab.handleError(
                TabError.networkError(
                    code: (error as NSError).code,
                    description: error.localizedDescription,
                    url: downloadItem.url
                ),
                context: ["filename": downloadItem.filename]
            )
        } else {
            print("✅ Download completed: \(downloadItem.filename)")
            downloadItem.complete()
        }
        
        self.downloadAssociations.removeValue(forKey: download)
    }
}

func downloadDidFinish(_ download: WKDownload) {
    print("✅ Download completed successfully (alternative callback)")
    
    DispatchQueue.main.async { [weak self] in
        guard let self = self, let downloadItem = self.downloadAssociations[download] else {
            print("❌ No download item found for finish callback")
            return
        }
        
        downloadItem.complete()
        self.downloadAssociations.removeValue(forKey: download)
    }
}

// MARK: - Permission Handling
private func requestSystemPermission(for type: WKMediaCaptureType) async -> Bool {
    switch type {
    case .camera:
        return await requestCameraPermission()
    case .microphone:
        return await requestMicrophonePermission()
    case .cameraAndMicrophone:
        let camera = await requestCameraPermission()
        let microphone = await requestMicrophonePermission()
        return camera && microphone
    @unknown default:
        return false
    }
}

private func requestCameraPermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
        return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
        DispatchQueue.main.async {
            self.showPermissionAlert(for: "Camera")
        }
        return false
    @unknown default:
        return false
    }
}

private func requestMicrophonePermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    switch status {
    case .authorized:
        return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .audio)
    case .denied, .restricted:
        DispatchQueue.main.async {
            self.showPermissionAlert(for: "Microphone")
        }
        return false
    @unknown default:
        return false
    }
}

private func showPermissionAlert(for mediaType: String) {
    #if os(macOS)
    let alert = NSAlert()
    alert.messageText = "\(mediaType) Permission Required"
    alert.informativeText = "Please enable \(mediaType) access in System Preferences > Security & Privacy > Privacy > \(mediaType), then restart the app."
    alert.addButton(withTitle: "Open System Preferences")
    alert.addButton(withTitle: "Cancel")
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_\(mediaType)") {
            NSWorkspace.shared.open(url)
        }
    }
    #elseif os(iOS)
    let alert = UIAlertController(
        title: "\(mediaType) Permission Required",
        message: "Please enable \(mediaType) access in Settings > Privacy > \(mediaType), then return to the app.",
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    parent?.viewController?.present(alert, animated: true)
    #endif
}

// MARK: - Download Detection
private func shouldDownloadFile(mimeType: String, response: URLResponse) -> Bool {
    if let httpResponse = response as? HTTPURLResponse {
        if let contentDisposition = httpResponse.allHeaderFields["Content-Disposition"] as? String {
            let disposition = contentDisposition.lowercased()
            if disposition.contains("attachment") || disposition.contains("filename=") {
                print("📎 Content-Disposition indicates download: \(contentDisposition)")
                return true
            }
        }
    }
    
    let downloadMimeTypes = [
        "image/png", "image/jpeg", "image/jpg", "image/gif", "image/webp",
        "image/svg+xml", "image/bmp", "image/tiff", "image/ico",
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/vnd.ms-powerpoint",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "text/plain", "text/csv",
        "application/zip", "application/x-zip-compressed",
        "application/x-rar-compressed", "application/x-7z-compressed",
        "application/gzip", "application/x-tar",
        "video/mp4", "video/avi", "video/mov", "video/wmv", "video/webm", "video/mkv",
        "audio/mp3", "audio/wav", "audio/aac", "audio/ogg", "audio/flac", "audio/m4a",
        "application/octet-stream",
        "application/x-executable",
        "application/x-msdos-program"
    ]
    
    let normalizedMimeType = mimeType.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    return downloadMimeTypes.contains(normalizedMimeType)
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
        parent.tab.handleError(TabError.navigationFailed(url: webView?.url, error: error), context: [
            "navigation": navigation as Any,
            "errorDomain": nsError.domain,
            "errorCode": nsError.code
        ])
    }
}

// MARK: - WKUIDelegate - New Tab/Window Support
func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    guard let url = navigationAction.request.url,
          let browserViewModel = self.browserViewModel else { return nil }
    
    if let customWebView = webView as? CustomWKWebView,
       let customAction = customWebView.contextualMenuAction {
        DispatchQueue.main.async { [weak self] in
            switch customAction {
            case .openInNewTab:
                self?.browserViewModel?.createNewTab(with: url, inBackground: false, focusAddressBar: false)
            case .openInNewWindow:
                self?.browserViewModel?.createNewWindow(with: url)
            }
        }
        return nil
    }
    
    DispatchQueue.main.async {
        if self.shouldHandleNavigationExternally(navigationAction, windowFeatures: windowFeatures) {
            browserViewModel.createNewWindow(with: url)
        } else {
            let inBackground = navigationAction.modifierFlags.contains(.command)
            browserViewModel.createNewTab(with: url, inBackground: inBackground, focusAddressBar: false)
        }
    }
    
    return nil
}

func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if shouldHandleNavigationExternally(navigationAction) {
        if let url = navigationAction.request.url,
           let browserViewModel = self.browserViewModel {
            DispatchQueue.main.async {
                let inBackground = navigationAction.modifierFlags.contains(.shift)
                browserViewModel.createNewTab(with: url, inBackground: inBackground, focusAddressBar: false)
            }
            decisionHandler(.cancel)
        } else {
            print("⚠️ Failed to open new tab: URL or browserViewModel is nil")
//            parent?.tab.handleError(TabError.invalidNavigationRequest(url: navigationAction.request.url), context: ["navigationAction": navigationAction])
            decisionHandler(.cancel)
        }
    } else {
        decisionHandler(.allow)
    }
}

private func shouldHandleNavigationExternally(_ navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures? = nil) -> Bool {
    if navigationAction.modifierFlags.contains(.command) ||
       navigationAction.modifierFlags.contains([.command, .shift]) ||
       navigationAction.buttonNumber == 2 ||
       navigationAction.targetFrame == nil {
        return true
    }
    if let windowFeatures = windowFeatures {
        return windowFeatures.width != nil || windowFeatures.height != nil
    }
    return false
}

deinit {
    if let webView = self.webView {
        removeObservers(from: webView)
    }
    zoomCancellable?.cancel()
    pendingNavigation = nil
    downloadAssociations.removeAll()
    print("WebViewCoordinator deinit for tab: \(tabId)")
}

}
