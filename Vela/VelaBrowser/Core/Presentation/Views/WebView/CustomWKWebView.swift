import WebKit

class CustomWKWebView: WKWebView {
    
    // Property to track the custom action selected from contextual menu
    var contextualMenuAction: ContextualMenuAction?
    var contextualMenuURL: URL?
    weak var browserViewModel: BrowserViewModel?
    
    // Store the URL from the right-click location
    private var rightClickURL: URL?
    
    // Define custom actions
    enum ContextualMenuAction {
        case openInNewTab
        case openInNewWindow
        // Add other actions as needed
    }
    
    @objc dynamic var isPlayingAudioPrivate: Bool = false

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

    func startObservingAudio() {
        addObserver(self, forKeyPath: "_isPlayingAudio", options: [.new, .initial], context: nil)
    }

    func stopObservingAudio() {
        removeObserver(self, forKeyPath: "_isPlayingAudio")
    }

    deinit {
        stopObservingAudio()
    }
    
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

