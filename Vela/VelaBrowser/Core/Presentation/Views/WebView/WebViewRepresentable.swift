import SwiftUI
import WebKit



struct WebViewRepresentable: NSViewRepresentable {
    @ObservedObject var tab: Tab
    @Binding var isLoading: Bool
    @Binding var estimatedProgress: Double
    let browserViewModel: BrowserViewModel
    let suggestionViewModel: AddressBarViewModel
    let noteViewModel: NoteBoardViewModel
 

  
    func makeNSView(context: Context) -> WKWebView {
        let webView: WKWebView
        if let existingWebView = tab.webView as? CustomWKWebView {
            webView = existingWebView
            existingWebView.browserViewModel = browserViewModel
        } else {
            let configuration = WKWebViewConfiguration()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            configuration.preferences.isFraudulentWebsiteWarningEnabled = false
            configuration.allowsAirPlayForMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = []
            configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
            
            
            // FIXED: Proper data store configuration
            if browserViewModel.isIncognitoMode {
                configuration.websiteDataStore = .nonPersistent()
            } else {
                // Use the default persistent data store
                configuration.websiteDataStore = .default()
                
            }
            
            // Rest of your configuration...
            if browserViewModel.isAdBlockingEnabled, let ruleList = browserViewModel.adBlockRuleList {
                configuration.userContentController.add(ruleList)
            }
            
            // Your existing scripts...
            let enhancedFullscreenScript = """
            (function() {
                function enableFullscreen(element) {
                    element.requestFullscreen = element.requestFullscreen ||
                        element.webkitRequestFullscreen ||
                        element.mozRequestFullScreen ||
                        element.msRequestFullscreen ||
                        function() { return Promise.reject(new Error('Fullscreen API is not supported')); };
                    element.webkitEnterFullscreen = element.webkitEnterFullscreen ||
                        function() { if (element.requestFullscreen) element.requestFullscreen(); };
                }
                document.querySelectorAll('*').forEach(enableFullscreen);
                document.querySelectorAll('video').forEach(enableFullscreen);
                const observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        mutation.addedNodes.forEach(function(node) {
                            if (node.nodeType === 1) {
                                enableFullscreen(node);
                                if (node.tagName === 'VIDEO') enableFullscreen(node);
                            }
                        });
                    });
                });
                observer.observe(document, { childList: true, subtree: true });
                window.webkitSupportsFullscreen = true;
                window.webkitEnterFullscreen = function() {
                    document.documentElement.requestFullscreen();
                };
            })();
            """
            let userScript = WKUserScript(source: enhancedFullscreenScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            configuration.userContentController.addUserScript(userScript)

            let youtubeFixScript = """
            (function() {
                Object.defineProperty(HTMLVideoElement.prototype, 'webkitSupportsFullscreen', {
                    get: function() { return true; },
                    configurable: true
                });
                Object.defineProperty(HTMLVideoElement.prototype, 'webkitEnterFullscreen', {
                    value: function() { this.requestFullscreen(); },
                    configurable: true
                });
            })();
            """
            configuration.userContentController.addUserScript(WKUserScript(source: youtubeFixScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))

            if #available(macOS 11.3, *) {
                configuration.upgradeKnownHostsToHTTPS = false
            }
         

            // UPDATED: Use CustomAudioObservingWebView instead of AudioObservingWebView
            let audioWebView = CustomWKWebView(frame: .zero, configuration: configuration)
            
            audioWebView.autoresizingMask = [.width, .height]
            audioWebView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
          //  audioWebView.allowsBackForwardNavigationGestures = true
         //   audioWebView.startObservingAudio()
            
            // IMPORTANT: Set the browserViewModel reference for contextual menu
            audioWebView.browserViewModel = browserViewModel
         //   audioWebView.noteboardViewModel = noteViewModel
            tab.setWebView(audioWebView)
            webView = audioWebView
        }

        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        #if DEBUG
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        context.coordinator.addObservers(to: webView)
        print("WebView frame on creation: \(webView.frame)")
        return webView
    }
   
    func updateNSView(_ nsView: WKWebView, context: Context) {
            context.coordinator.parent = self
            context.coordinator.addObservers(to: nsView)
            
            if let url = tab.url {
                let shouldLoad = nsView.url != url ||
                                (nsView.url == nil && !nsView.isLoading) ||
                                nsView.url?.absoluteString != url.absoluteString
                
                if shouldLoad {
                    context.coordinator.loadURL(url, in: nsView)
                }
            }
            
            DispatchQueue.main.async {
                self.isLoading = nsView.isLoading
                self.estimatedProgress = nsView.estimatedProgress
                // Only update frame during full-screen transitions
                if self.browserViewModel.isFullScreen != (nsView.window?.styleMask.contains(.fullScreen) ?? false) {
                    if let window = nsView.window {
                        nsView.frame = window.contentView?.bounds ?? nsView.frame
                     
                    }
                } else {
                  
                }
            }
        }
    func makeCoordinator() -> WebViewCoordinator {
        let coordinator = WebViewCoordinator(self, tab: tab)
        coordinator.browserViewModel = browserViewModel
        return coordinator
    }
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: WebViewCoordinator) {
        coordinator.removeObservers(from: nsView)
        nsView.stopLoading()
    }
    
}

extension BrowserViewModel {
    
    // Method to clear all website data (for privacy/reset)
    func initiateDownload(from url: URL) {
        print("downloading file: \(currentTab?.webView)")
        guard let webView = currentTab?.webView else { return }
        
        
        let request = URLRequest(url: url)
        webView.load(request) // This should trigger the download policy decision
    }
    
    // New method to handle adding items to noteboard
    func addToNoteboard(title: String, url: String, selectedText: String) {
        print("Adding to Noteboard:")
        print("  Title: \(title)")
        print("  URL: \(url)")
        print("  Selected Text: \(selectedText)")
        let noteBoardNote = NoteBoardNote(id: UUID(),
                                          content: selectedText,
                                          createdAt: Date(),
                                          updatedAt: Date(),
                                          sourceUrl: url,
                                          tabTitle: title,
                                          tags: [],
                                          pinned: false,
                                          archived: false)
        self.noteboardVM.createNote(noteBoardNote)
    }
    
    func clearAllWebsiteData() async {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        await dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast)
        print("✅ All website data cleared")
    }
    
    // Method to clear specific website data
    func clearDataForWebsite(_ domain: String) async {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        let records = await dataStore.dataRecords(ofTypes: dataTypes)
        let recordsToDelete = records.filter { $0.displayName.contains(domain) }
        
        await dataStore.removeData(ofTypes: dataTypes, for: recordsToDelete)
        print("✅ Data cleared for domain: \(domain)")
    }
    
    // Method to check data storage status
    func checkWebsiteDataStatus() async {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        let records = await dataStore.dataRecords(ofTypes: dataTypes)
        print("📊 Stored data for \(records.count) websites:")
        for record in records {
            print("  - \(record.displayName): \(record.dataTypes)")
        }
    }
    
    // Method to ensure persistent storage is enabled
    func ensurePersistentStorage() {
        // This ensures the default data store is properly initialized
        let dataStore = WKWebsiteDataStore.default()
        print("📦 Using persistent data store: \(dataStore.isPersistent)")
    }
}
