//
//  AppDelegate.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import AppKit
import SwiftUI

class VelaAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var browserViewModel: BrowserViewModel?
    private var keyEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupGlobalKeyboardShortcuts()
        setupAppearance()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupGlobalKeyboardShortcuts() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let viewModel = self?.browserViewModel else { return event }
            
            // Check if the menu system handles the event first
            if NSApp.mainMenu?.performKeyEquivalent(with: event) == true {
                print("Menu handled event: \(event.charactersIgnoringModifiers ?? "unknown")")
                
                // Force a view refresh after menu actions
                DispatchQueue.main.async {
                    viewModel.objectWillChange.send()
                }
                
                return nil // Event was handled by the menu, consume it
            }
            
            // Check for custom keyboard shortcuts
            if let shortcut = KeyboardShortcut.from(event: event) {
                print("Handling shortcut: \(shortcut)")
                
                // Handle on main queue and force view refresh
                DispatchQueue.main.async {
                    viewModel.handleKeyboardShortcut(shortcut)
                    
                    // Additional refresh after a short delay to ensure UI updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        viewModel.objectWillChange.send()
                    }
                }
                
                return nil // Event was handled by custom shortcut, consume it
            }
            
            print("No shortcut matched for event: \(event.charactersIgnoringModifiers ?? "unknown")")
            return event // Pass the event along if not handled
        }
    }
    
    private func setupAppearance() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    // MARK: - Menu Actions with Enhanced View Refresh
    @MainActor @objc func newTab(_ sender: Any?) {
        print("Menu action: New Tab")
        browserViewModel?.createNewTab(shouldReloadTabs: true)
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func newTabInBackground(_ sender: Any?) {
        print("Menu action: New Tab in Background")
        browserViewModel?.createNewTab(inBackground: true)
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func closeTab(_ sender: Any?) {
        print("Menu action: Close Tab")
        browserViewModel?.closeCurrentTab()
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func duplicateTab(_ sender: Any?) {
        print("Menu action: Duplicate Tab")
        browserViewModel?.duplicateCurrentTab()
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func goBack(_ sender: Any?) {
        print("Menu action: Go Back")
        browserViewModel?.goBack()
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func goForward(_ sender: Any?) {
        print("Menu action: Go Forward")
        browserViewModel?.goForward()
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func reload(_ sender: Any?) {
        print("Menu action: Reload")
        browserViewModel?.reload()
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func focusAddressBar(_ sender: Any?) {
        print("Menu action: Focus Address Bar")
        browserViewModel?.focusAddressBar()
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor @objc func toggleSidebar(_ sender: Any?) {
        print("Menu action: Toggle Sidebar")
        browserViewModel?.toggleSidebar()
        
        // Force view refresh
        DispatchQueue.main.async {
            self.browserViewModel?.objectWillChange.send()
        }
    }
    
    @MainActor func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let viewModel = browserViewModel else {
            print("validateMenuItem: browserViewModel is nil")
            return false
        }
        
        // Validate menu items and force refresh if state has changed
        let isValid: Bool
        
        switch menuItem.action {
        case #selector(newTab(_:)), #selector(newTabInBackground(_:)):
            isValid = true
        case #selector(closeTab(_:)):
            isValid = viewModel.currentTab != nil
        case #selector(duplicateTab(_:)):
            isValid = viewModel.currentTab != nil
        case #selector(goBack(_:)):
            isValid = viewModel.currentTab?.webView?.canGoBack ?? false
        case #selector(goForward(_:)):
            isValid = viewModel.currentTab?.webView?.canGoForward ?? false
        case #selector(reload(_:)):
            isValid = viewModel.currentTab != nil
        case #selector(focusAddressBar(_:)):
            isValid = true
        case #selector(toggleSidebar(_:)):
            isValid = true
        default:
            isValid = true
        }
        
        // Update menu item state if needed
        if menuItem.isEnabled != isValid {
            DispatchQueue.main.async {
                viewModel.objectWillChange.send()
            }
        }
        
        return isValid
    }
}
