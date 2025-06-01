//
//  CustomWKWebView.swift
//  Vela
//
//  Created by damilola on 6/1/25.
//

import WebKit


class CustomWKWebView: WKWebView {
    
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

