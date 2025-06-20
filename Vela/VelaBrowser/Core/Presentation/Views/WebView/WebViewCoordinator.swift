// MARK: - Fixed WebViewCoordinator with proper download support and error handling
@preconcurrency import WebKit
import AppKit
import Foundation
import Combine
import AVFAudio

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
        
        if let previousWebView = self.webView, previousWebView != webView {
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
        
        parent.suggestionViewModel.cancelSuggestions()
        if let pending = pendingNavigation, webView.url != url {
            lastRequestedURL = url
            let request = URLRequest(url: url)
            pendingNavigation = webView.load(request)
        } else {
            lastRequestedURL = url
            let request = URLRequest(url: url)
            pendingNavigation = webView.load(request)
        }
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
                    // Schedule favicon loading with error handling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        tab.loadFaviconWithErrorHandling(for: newURL)
                    }
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
                parent.tab.reloadFavicon()
            }
        }
    }
    
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        if type == .microphone {
            decisionHandler(.prompt)
        } else {
            decisionHandler(.deny)
            parent?.tab.handleError(TabError.securityError(url: webView.url, description: "Denied media capture for type \(type.rawValue)"), context: ["origin": origin.host, "type": type.rawValue])
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
        print("📥 Download destination requested for: \(suggestedFilename)")
        
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            let error = TabError.networkError(code: -1, description: "Could not access Downloads folder", url: nil)
            parent?.tab.handleError(error, context: ["suggestedFilename": suggestedFilename])
            completionHandler(nil)
            return
        }
        
        let destinationURL = downloadsURL.appendingPathComponent(suggestedFilename)
        let finalURL = getUniqueFileName(for: destinationURL)
        
        print("📁 Download destination: \(finalURL.path)")
        
        // Create download item
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let parent = self.parent else { return }
            let downloadItem = DownloadItem(filename: finalURL.lastPathComponent, url: finalURL, download: download)
           // self.browserViewModel?.addDownload(downloadItem)
            self.downloadAssociations[download] = downloadItem
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
            guard let downloadItem = self?.downloadAssociations[download] else { return }
            downloadItem.updateProgress(progress, bytesReceived: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
        }
    }
    
    func download(_ download: WKDownload, didFinishWith error: Error?) {
        print("📥 Download finished with error: \(error?.localizedDescription ?? "none")")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let downloadItem = self.downloadAssociations[download] else { return }
            if let error = error {
                downloadItem.fail(with: error)
                self.parent?.tab.handleError(TabError.networkError(code: (error as NSError).code, description: error.localizedDescription, url: downloadItem.url), context: ["filename": downloadItem.filename])
            } else {
                downloadItem.complete()
            }
            self.downloadAssociations.removeValue(forKey: download)
        }
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        print("✅ Download completed successfully")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let downloadItem = self.downloadAssociations[download] else { return }
            downloadItem.complete()
            self.downloadAssociations.removeValue(forKey: download)
        }
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

    // MARK: - WKUIDelegate - New Tab Support
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let customWebView = webView as? CustomWKWebView,
           let customAction = customWebView.contextualMenuAction {
            
            guard let url = navigationAction.request.url else { return nil }
            
            DispatchQueue.main.async { [weak self] in
                switch customAction {
                case .openInNewTab:
                    self?.browserViewModel?.createNewTab(with: url, inBackground: false, focusAddressBar: false)
                case .openInNewWindow:
                    self?.browserViewModel?.createNewTab(with: url, inBackground: false, focusAddressBar: false)
                 //   self?.browserViewModel?.createNewWindow(with: url)
                }
            }
            
            return nil
        }
        
        guard let url = navigationAction.request.url,
              let browserViewModel = self.browserViewModel else { return nil }
        
        let shouldOpenInNewWindow = windowFeatures.width != nil ||
                                   windowFeatures.height != nil ||
                                   navigationAction.modifierFlags.contains([.command, .option])
        
        DispatchQueue.main.async {
            if shouldOpenInNewWindow {
              //  browserViewModel.createNewWindow(with: url)
            } else {
                let inBackground = navigationAction.modifierFlags.contains(.command)
                browserViewModel.createNewTab(with: url, inBackground: inBackground, focusAddressBar: false)
            }
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
                    browserViewModel.createNewTab(with: url, inBackground: inBackground, focusAddressBar: false)
                }
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    private func shouldOpenInNewTab(navigationAction: WKNavigationAction) -> Bool {
        if navigationAction.modifierFlags.contains(.command) ||
           navigationAction.modifierFlags.contains([.command, .shift]) ||
           navigationAction.buttonNumber == 2 ||
           navigationAction.targetFrame == nil {
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
