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
        //setupGlobalKeyboardShortcuts()
        setupAppearance()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    
    private func setupAppearance() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    // MARK: - Menu Actions
    @MainActor @objc func newTab(_ sender: Any?) {
        print("Menu action: New Tab")
        browserViewModel?.createNewTab(shouldReloadTabs: true)
    }
    
    @MainActor @objc func newTabInBackground(_ sender: Any?) {
        print("Menu action: New Tab in Background")
        browserViewModel?.createNewTab(inBackground: true)
    }
    
    @MainActor @objc func closeTab(_ sender: Any?) {
        print("Menu action: Close Tab")
        browserViewModel?.closeCurrentTab()
    }
    
    @MainActor @objc func duplicateTab(_ sender: Any?) {
        print("Menu action: Duplicate Tab")
        browserViewModel?.duplicateCurrentTab()
    }
    
    @MainActor @objc func goBack(_ sender: Any?) {
        print("Menu action: Go Back")
        browserViewModel?.goBack()
    }
    
    @MainActor @objc func goForward(_ sender: Any?) {
        print("Menu action: Go Forward")
        browserViewModel?.goForward()
    }
    
    @MainActor @objc func reload(_ sender: Any?) {
        print("Menu action: Reload")
        browserViewModel?.reload()
    }
    
    @MainActor @objc func focusAddressBar(_ sender: Any?) {
        print("Menu action: Focus Address Bar")
        browserViewModel?.focusAddressBar()
    }
    
    @MainActor @objc func toggleSidebar(_ sender: Any?) {
        print("Menu action: Toggle Sidebar")
        browserViewModel?.toggleSidebar()
    }
    
    @MainActor func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let viewModel = browserViewModel else {
            print("validateMenuItem: browserViewModel is nil")
            return false
        }
        
        // Validate menu items
        switch menuItem.action {
        case #selector(newTab(_:)), #selector(newTabInBackground(_:)):
            return true
        case #selector(closeTab(_:)):
            return viewModel.currentTab != nil
        case #selector(duplicateTab(_:)):
            return viewModel.currentTab != nil
        case #selector(goBack(_:)):
            return viewModel.currentTab?.webView?.canGoBack ?? false
        case #selector(goForward(_:)):
            return viewModel.currentTab?.webView?.canGoForward ?? false
        case #selector(reload(_:)):
            return viewModel.currentTab != nil
        case #selector(focusAddressBar(_:)):
            return true
        case #selector(toggleSidebar(_:)):
            return true
        default:
            return true
        }
    }
}
