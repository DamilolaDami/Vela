import WebKit

class CustomWKWebView: WKWebView {
    
    // Property to track the custom action selected from contextual menu
    var contextualMenuAction: ContextualMenuAction?
    var contextualMenuURL: URL?
    weak var browserViewModel: BrowserViewModel?
    weak var downloadsManager: DownloadsManager?
    private var downloadHandler: DownloadScriptMessageHandler?
    
    // Store the URL from the right-click location
    private var rightClickURL: URL?
    
    // Track observer state to prevent double removal
    private var isObservingAudio = false
    
    // Track if download detection is set up
    private var isDownloadDetectionSetup = false
    
    // Define custom actions
    enum ContextualMenuAction {
        case openInNewTab
        case openInNewWindow
        // Add other actions as needed
    }
    
    @objc dynamic var isPlayingAudioPrivate: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Don't setup download detection here - do it after navigation starts
    }
    
    // Override navigation delegate methods to ensure script is injected at the right time
    override func load(_ request: URLRequest) -> WKNavigation? {
        setupDownloadDetectionIfNeeded()
        return super.load(request)
    }
    
    override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        setupDownloadDetectionIfNeeded()
        return super.loadHTMLString(string, baseURL: baseURL)
    }
    
    private func setupDownloadDetectionIfNeeded() {
        guard !isDownloadDetectionSetup else { return }
        setupDownloadDetection()
        isDownloadDetectionSetup = true
    }

    override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)

        if key == "_isPlayingAudio" {
            if let value = try? self.value(forKey: "_isPlayingAudio") as? Bool {
                isPlayingAudioPrivate = value
            }
        }
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "_isPlayingAudio" {
            if let value = (change?[.newKey] as? NSNumber)?.boolValue {
                isPlayingAudioPrivate = value
            }
        } else {
            // Always call super for unhandled keys
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func setupDownloadDetection() {
        print("🔧 Setting up download detection...")
        
        // Remove existing handler first
        configuration.userContentController.removeScriptMessageHandler(forName: "downloadHandler")
        
        // Create new handler
        downloadHandler = DownloadScriptMessageHandler(webView: self)
        
        // Add the handler BEFORE adding the script
        configuration.userContentController.add(downloadHandler!, name: "downloadHandler")
        
        // Inject JavaScript to detect download button clicks with better position detection
        let downloadDetectionScript = """
           (function() {
               console.log('🚀 Download detection script loaded');
               
               // Function to find download links/buttons
               function isDownloadElement(element) {
                   if (!element) return false;
                   
                   // Check for download attribute
                   if (element.hasAttribute && element.hasAttribute('download')) {
                       console.log('📥 Found download attribute on element:', element);
                       return true;
                   }
                   
                   // Check for common download patterns in href
                   const href = element.href || '';
                   const downloadExtensions = ['.pdf', '.doc', '.docx', '.zip', '.exe', '.dmg', '.pkg', '.xlsx', '.pptx', '.mp4', '.mp3', '.jpg', '.png'];
                   if (downloadExtensions.some(ext => href.toLowerCase().includes(ext))) {
                       console.log('📁 Found download extension in href:', href);
                       return true;
                   }
                   
                   // Check for download-related text content
                   const text = (element.textContent || element.innerText || '').toLowerCase();
                   const downloadKeywords = ['download', 'get', 'save', 'export', 'install'];
                   if (downloadKeywords.some(keyword => text.includes(keyword))) {
                       console.log('💾 Found download keyword in text:', text);
                       return true;
                   }
                   
                   // Check for common download class names
                   const className = element.className || '';
                   if (className.toLowerCase().includes('download')) {
                       console.log('🏷️ Found download class name:', className);
                       return true;
                   }
                   
                   return false;
               }
               
               // Enhanced function to get precise element position
               function getElementViewportPosition(element) {
                   const rect = element.getBoundingClientRect();
                   
                   // Get the center point of the element
                   const centerX = rect.left + rect.width / 2;
                   const centerY = rect.top + rect.height / 2;
                   
                   // Position relative to the viewport (what user sees) - this is what we want
                   const viewportPosition = {
                       x: centerX,
                       y: centerY
                   };
                   
                   // Also get document position for debugging
                   const documentPosition = {
                       x: centerX + window.scrollX,
                       y: centerY + window.scrollY
                   };
                   
                   // Get viewport dimensions and scroll info for validation
                   const viewportInfo = {
                       width: window.innerWidth,
                       height: window.innerHeight,
                       scrollX: window.scrollX,
                       scrollY: window.scrollY,
                       devicePixelRatio: window.devicePixelRatio || 1,
                       documentWidth: document.documentElement.scrollWidth,
                       documentHeight: document.documentElement.scrollHeight
                   };
                   
                   console.log('📏 Element rect:', {
                       left: rect.left,
                       top: rect.top,
                       right: rect.right,
                       bottom: rect.bottom,
                       width: rect.width,
                       height: rect.height
                   });
                   console.log('📍 Viewport position (center):', viewportPosition);
                   console.log('📜 Document position (center):', documentPosition);
                   console.log('🖥️ Viewport info:', viewportInfo);
                   
                   // Validate position is within viewport
                   const isVisible = rect.top < window.innerHeight && 
                                   rect.bottom > 0 && 
                                   rect.left < window.innerWidth && 
                                   rect.right > 0;
                   
                   console.log('👁️ Element is visible in viewport:', isVisible);
                   
                   return {
                       viewport: viewportPosition,
                       document: documentPosition,
                       rect: {
                           left: rect.left,
                           top: rect.top,
                           right: rect.right,
                           bottom: rect.bottom,
                           width: rect.width,
                           height: rect.height
                       },
                       viewportInfo: viewportInfo,
                       isVisible: isVisible
                   };
               }
               
               // Test message handler availability
               if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.downloadHandler) {
                   console.log('✅ Download handler is available');
                   
                   // Send test message
                   window.webkit.messageHandlers.downloadHandler.postMessage({
                       type: 'test',
                       message: 'Download detection script loaded successfully'
                   });
               } else {
                   console.error('❌ Download handler is NOT available');
               }
               
               // Add click listeners to potential download elements
               document.addEventListener('click', function(event) {
                   console.log('🖱️ Click detected on:', event.target);
                   
                   const element = event.target.closest('a, button, [role="button"], input[type="submit"], [onclick]');
                   
                   if (element) {
                       console.log('🎯 Found clickable element:', element);
                       
                       if (isDownloadElement(element)) {
                           console.log('📥 Download element clicked!');
                           
                           // Small delay to ensure element is in final position after any click effects
                           setTimeout(() => {
                               const positionData = getElementViewportPosition(element);
                               
                               console.log('📍 Sending download click message with position data');
                               
                               // Send comprehensive position data to native code
                               try {
                                   window.webkit.messageHandlers.downloadHandler.postMessage({
                                       type: 'downloadClick',
                                       position: positionData,
                                       element: {
                                           tagName: element.tagName,
                                           href: element.href || '',
                                           text: element.textContent?.trim() || '',
                                           id: element.id || '',
                                           className: element.className || '',
                                           hasDownloadAttr: element.hasAttribute('download')
                                       },
                                       timestamp: Date.now()
                                   });
                                   console.log('✅ Message sent successfully');
                               } catch (error) {
                                   console.error('❌ Failed to send message:', error);
                               }
                           }, 50); // 50ms delay to account for any UI changes
                           
                       } else {
                           console.log('ℹ️ Not a download element');
                       }
                   }
               }, true); // Use capture phase to ensure we get the event
               
               console.log('👂 Click listener added to document');
           })();
           """
        
        let script = WKUserScript(
            source: downloadDetectionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        configuration.userContentController.addUserScript(script)
        print("✅ Download detection script added")
    }

    func startObservingAudio() {
        guard !isObservingAudio else { return }
        
        do {
            addObserver(self, forKeyPath: "_isPlayingAudio", options: [.new, .initial], context: nil)
            isObservingAudio = true
            print("✅ Started observing _isPlayingAudio")
        } catch {
            print("❌ Failed to add observer for _isPlayingAudio: \(error)")
        }
    }

    func stopObservingAudio() {
        guard isObservingAudio else { return }
        
        do {
            removeObserver(self, forKeyPath: "_isPlayingAudio")
            isObservingAudio = false
            print("✅ Stopped observing _isPlayingAudio")
        } catch {
            print("❌ Failed to remove observer for _isPlayingAudio: \(error)")
        }
    }

    deinit {
        stopObservingAudio()
        if downloadHandler != nil {
            configuration.userContentController.removeScriptMessageHandler(forName: "downloadHandler")
        }
    }
    
    // Rest of your existing methods...
    @objc func processMenuItem(_ menuItem: NSMenuItem) {
        print("🎯 Processing menu item: \(menuItem.identifier?.rawValue ?? "nil")")

        // Reset the action to avoid stale state
        self.contextualMenuAction = nil
        self.contextualMenuURL = nil
        
        // Check the menu item's identifier directly
        let identifier = menuItem.identifier?.rawValue
        switch identifier {
        case "openLinkInNewTab", "openImageInNewTab", "openMediaInNewTab":
            print("📑 Setting contextualMenuAction to openInNewTab")
            self.contextualMenuAction = .openInNewTab
        case "openLinkInNewWindow", "openImageInNewWindow", "openMediaInNewWindow":
            print("🪟 Setting contextualMenuAction to openInNewWindow")
            self.contextualMenuAction = .openInNewWindow
        default:
            print("🔍 Unknown menu item identifier: \(identifier ?? "nil")")
            return
        }
        
        // Use the stored URL from the right-click location
        if let url = self.rightClickURL {
            print("🔗 Found URL from right-click: \(url)")
            self.contextualMenuURL = url
            
            // Notify your browser view model to handle the new tab/window
            if let action = self.contextualMenuAction {
                handleContextualMenuAction(action, url: url)
            }
        } else {
            print("❌ No URL found from right-click location")
        }
    }
    
    private func handleContextualMenuAction(_ action: ContextualMenuAction, url: URL) {
        // Call your browser view model to handle the action
        switch action {
        case .openInNewTab:
            browserViewModel?.createNewTab(with: url ,inBackground: false, shouldReloadTabs: false, focusAddressBar: false)
        case .openInNewWindow:
            print("🔄 Opening URL in new window: \(url)")
            browserViewModel?.createNewWindow(with: url)
        }
        
        // Clear the stored action and URL
        self.contextualMenuAction = nil
        self.contextualMenuURL = nil
    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        
        // Perform JavaScript evaluation to get the URL at the click location
        let locationInView = convert(event.locationInWindow, from: nil)
        
        // Store this for later use in processMenuItem
        evaluateJavaScript("""
            (function() {
                var element = document.elementFromPoint(\(locationInView.x), \(locationInView.y));
                if (element) {
                    // Check if it's a link or has a parent link
                    var link = element.closest('a[href]');
                    if (link) {
                        return link.href;
                    }
                    // Check if it's an image with a src
                    if (element.tagName === 'IMG' && element.src) {
                        return element.src;
                    }
                    // Check if it's a video with a src
                    if (element.tagName === 'VIDEO' && element.src) {
                        return element.src;
                    }
                }
                return null;
            })();
        """) { [weak self] result, error in
            if let urlString = result as? String, let url = URL(string: urlString) {
                print("🎯 JavaScript found URL: \(url)")
                DispatchQueue.main.async {
                    self?.rightClickURL = url
                }
            } else if let error = error {
                print("❌ JavaScript error: \(error)")
            } else {
                print("🔍 No URL found at click location")
            }
        }
        
        print("🔍 Menu items: \(menu.items.map { $0.identifier?.rawValue ?? "nil" })")
        
        var items = menu.items
        
        // Add custom menu items
        for idx in (0..<items.count).reversed() {
            if let id = items[idx].identifier?.rawValue {
                if id == "WKMenuItemIdentifierOpenLinkInNewWindow" {
                    // Add "Open Link in New Tab"
                    let tabMenuItem = NSMenuItem(title: "Open Link in New Tab", action: #selector(processMenuItem(_:)), keyEquivalent: "")
                    tabMenuItem.identifier = NSUserInterfaceItemIdentifier("openLinkInNewTab")
                    tabMenuItem.target = self
                    items.insert(tabMenuItem, at: idx + 1)
                    
                    // Modify the original "Open Link in New Window" to use our custom action
                    items[idx].action = #selector(processMenuItem(_:))
                    items[idx].target = self
                    items[idx].identifier = NSUserInterfaceItemIdentifier("openLinkInNewWindow")
                    
                } else if id == "WKMenuItemIdentifierOpenImageInNewWindow" {
                    // Add "Open Image in New Tab"
                    let tabMenuItem = NSMenuItem(title: "Open Image in New Tab", action: #selector(processMenuItem(_:)), keyEquivalent: "")
                    tabMenuItem.identifier = NSUserInterfaceItemIdentifier("openImageInNewTab")
                    tabMenuItem.target = self
                    items.insert(tabMenuItem, at: idx + 1)
                    
                    // Modify the original "Open Image in New Window"
                    items[idx].action = #selector(processMenuItem(_:))
                    items[idx].target = self
                    items[idx].identifier = NSUserInterfaceItemIdentifier("openImageInNewWindow")
                    
                } else if id == "WKMenuItemIdentifierOpenMediaInNewWindow" {
                    // Add "Open Video in New Tab"
                    let tabMenuItem = NSMenuItem(title: "Open Video in New Tab", action: #selector(processMenuItem(_:)), keyEquivalent: "")
                    tabMenuItem.identifier = NSUserInterfaceItemIdentifier("openMediaInNewTab")
                    tabMenuItem.target = self
                    items.insert(tabMenuItem, at: idx + 1)
                    
                    // Modify the original "Open Video in New Window"
                    items[idx].action = #selector(processMenuItem(_:))
                    items[idx].target = self
                    items[idx].identifier = NSUserInterfaceItemIdentifier("openMediaInNewWindow")
                }
            }
        }
        
        menu.items = items
    }

    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        super.didCloseMenu(menu, with: event)
        print("🔍 Menu closed")
        
        // Clear stored data after menu closes if no action was taken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.contextualMenuAction == nil {
                self?.contextualMenuURL = nil
                self?.rightClickURL = nil
            }
        }
    }
}
