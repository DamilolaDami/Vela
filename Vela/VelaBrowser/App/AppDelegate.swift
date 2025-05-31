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
        setupAppearance()
        if let window = NSApplication.shared.windows.first {
                    window.delegate = self // Set delegate for full-screen events
                    // Removed styleMask.insert(.fullScreen) to avoid exception
                    window.collectionBehavior.insert(.fullScreenPrimary) // Allow full-screen mode
                }
        }
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    
    private func setupAppearance() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    @MainActor func windowWillEnterFullScreen(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                browserViewModel?.toggleFullScreen(true)
                print("Window will enter full-screen mode, frame: \(window.frame)")
                DispatchQueue.main.async {
                    window.contentView?.frame = window.frame // Force content view to match
                    window.contentView?.needsLayout = true // Trigger layout update
                }
            }
        }

    @MainActor func windowWillExitFullScreen(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                browserViewModel?.toggleFullScreen(false)
                print("Window will exit full-screen mode, frame: \(window.frame)")
                DispatchQueue.main.async {
                    window.contentView?.frame = window.frame
                    window.contentView?.needsLayout = true
                }
            }
        }

        func windowDidResize(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                print("Window resized to: \(window.frame)")
                window.contentView?.needsLayout = true // Ensure content view updates
            }
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


extension VelaAppDelegate: NSWindowDelegate {
    func windowDidEnterFullScreen(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.contentView?.frame = window.frame
        }
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.contentView?.frame = window.frame
        }
    }
}
