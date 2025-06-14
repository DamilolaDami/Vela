import SwiftUI
import WebKit

// MARK: - Custom WKWebView with contextual menu support
class CustomAudioObservingWebView: AudioObservingWebView {
    
    // Property to track the custom action selected from contextual menu
    var contextualMenuAction: ContextualMenuAction?
    weak var browserViewModel: BrowserViewModel?
    
    // Define custom actions
    enum ContextualMenuAction {
        case openInNewTab
        case openInNewWindow
        // Add other actions as needed
    }
    
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        
        var items = menu.items
        
        // Find and modify existing menu items
        for idx in (0..<items.count).reversed() {
            if let id = items[idx].identifier?.rawValue {
                // Check for link-related menu items
                if id == "WKMenuItemIdentifierOpenLinkInNewWindow" {
                    // Create "Open in New Tab" menu item
                    let action = #selector(processMenuItem(_:))
                    let tabMenuItem = NSMenuItem(title: "Open Link in New Tab", action: action, keyEquivalent: "")
                    tabMenuItem.identifier = NSUserInterfaceItemIdentifier("openLinkInNewTab")
                    tabMenuItem.target = self
                    tabMenuItem.representedObject = items[idx]
                    
                    // Insert the new menu item right after the original
                    items.insert(tabMenuItem, at: idx + 1)
                }
                
                // You can also handle images and other elements
                else if id == "WKMenuItemIdentifierOpenImageInNewWindow" {
                    let action = #selector(processMenuItem(_:))
                    let tabMenuItem = NSMenuItem(title: "Open Image in New Tab", action: action, keyEquivalent: "")
                    tabMenuItem.identifier = NSUserInterfaceItemIdentifier("openImageInNewTab")
                    tabMenuItem.target = self
                    tabMenuItem.representedObject = items[idx]
                    items.insert(tabMenuItem, at: idx + 1)
                }
                
                // Handle media (videos)
                else if id == "WKMenuItemIdentifierOpenMediaInNewWindow" {
                    let action = #selector(processMenuItem(_:))
                    let tabMenuItem = NSMenuItem(title: "Open Video in New Tab", action: action, keyEquivalent: "")
                    tabMenuItem.identifier = NSUserInterfaceItemIdentifier("openMediaInNewTab")
                    tabMenuItem.target = self
                    tabMenuItem.representedObject = items[idx]
                    items.insert(tabMenuItem, at: idx + 1)
                }
                
                // Optional: Remove download options if you don't want them
                /*
                else if id == "WKMenuItemIdentifierDownloadLinkedFile" ||
                        id == "WKMenuItemIdentifierDownloadImage" ||
                        id == "WKMenuItemIdentifierDownloadMedia" {
                    items.remove(at: idx)
                }
                */
            }
        }
        
        // Update the menu with our modifications
        menu.items = items
    }
    
    @objc func processMenuItem(_ menuItem: NSMenuItem) {
        // Reset the action
        self.contextualMenuAction = nil
        
        guard let originalMenuItem = menuItem.representedObject as? NSMenuItem else { return }
        
        // Determine which custom action was selected
        if let identifier = menuItem.identifier?.rawValue {
            switch identifier {
            case "openLinkInNewTab", "openImageInNewTab", "openMediaInNewTab":
                self.contextualMenuAction = .openInNewTab
            default:
                break
            }
        }
        
        // Trigger the original menu item's action to get the URL
        if let action = originalMenuItem.action {
            originalMenuItem.target?.perform(action, with: originalMenuItem)
        }
    }
    
    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        super.didCloseMenu(menu, with: event)
        
        // Clear the action after a delay to ensure the navigation delegate has time to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.contextualMenuAction = nil
        }
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    @ObservedObject var tab: Tab
    @Binding var isLoading: Bool
    @Binding var estimatedProgress: Double
    let browserViewModel: BrowserViewModel

  
    func makeNSView(context: Context) -> WKWebView {
        let webView: WKWebView
        if let existingWebView = tab.webView as? CustomAudioObservingWebView {
            webView = existingWebView
            existingWebView.startObservingAudio()
        } else {
            let configuration = WKWebViewConfiguration()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = browserViewModel.isJavaScriptEnabled
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = !browserViewModel.isPopupBlockingEnabled
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
            let audioWebView = CustomAudioObservingWebView(frame: .zero, configuration: configuration)
            audioWebView.autoresizingMask = [.width, .height]
            audioWebView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
            audioWebView.allowsBackForwardNavigationGestures = true
            audioWebView.startObservingAudio()
            
            // IMPORTANT: Set the browserViewModel reference for contextual menu
            audioWebView.browserViewModel = browserViewModel
            
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
