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
    var bookmarkViewModel: BookmarkViewModel?
    private var keyEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupAppearance()
       // hideTitleBar()
        if let window = NSApplication.shared.windows.first {
            window.delegate = self // Set delegate for full-screen events
            // Removed styleMask.insert(.fullScreen) to avoid exception
            window.collectionBehavior.insert(.fullScreenPrimary) // Allow full-screen mode
        }
    }
    
    
//    func hideTitleBar() {
//        guard let window = NSApplication.shared.windows.first else { assertionFailure(); return }
//        window.standardWindowButton(.closeButton)?.isHidden = true
//        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
//        window.standardWindowButton(.zoomButton)?.isHidden = true
//    }
    
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
            DispatchQueue.main.async {
                window.contentView?.frame = window.frame
                window.contentView?.needsLayout = true
            }
        }
    }

    @MainActor func windowWillExitFullScreen(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            browserViewModel?.toggleFullScreen(false)
            DispatchQueue.main.async {
                window.contentView?.frame = window.frame
                window.contentView?.needsLayout = true
            }
        }
    }

    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.contentView?.needsLayout = true // Ensure content view updates
        }
    }
    
    // MARK: - Menu Actions
    @MainActor @objc func newTab(_ sender: Any?) {
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
    
    // MARK: - Bookmark Actions
    @MainActor @objc func addBookmark(_ sender: Any?) {
        print("Menu action: Add Bookmark")
        bookmarkViewModel?.showAddBookmarkSheet()
        
        // Alternatively, if you want to add the current page directly:
        // if let currentTab = browserViewModel?.currentTab,
        //    let url = currentTab.url {
        //     let title = currentTab.title ?? url.absoluteString
        //     bookmarkViewModel?.addBookmark(title: title, url: url)
        // }
    }
    
    @MainActor @objc func showAllBookmarks(_ sender: Any?) {
        print("Menu action: Show All Bookmarks")
        // This would typically show a bookmark manager window or sidebar
      //  browserViewModel?.showBookmarksSidebar()
        // Or if you have a dedicated bookmarks window:
        // showBookmarksWindow()
    }
    
    @MainActor @objc func bookmarkAllTabs(_ sender: Any?) {
        print("Menu action: Bookmark All Tabs")
        // Implementation to bookmark all open tabs
      //  browserViewModel?.bookmarkAllTabs()
    }
    
    @MainActor @objc func importBookmarks(_ sender: Any?) {
        print("Menu action: Import Bookmarks")
        showImportBookmarksDialog()
    }
    
    @MainActor @objc func exportBookmarks(_ sender: Any?) {
        print("Menu action: Export Bookmarks")
        showExportBookmarksDialog()
    }
    
    @MainActor @objc func organizeBookmarks(_ sender: Any?) {
        print("Menu action: Organize Bookmarks")
        // Show bookmark organization interface
        bookmarkViewModel?.toggleEditing()
    }
    
    @MainActor @objc func addBookmarkFolder(_ sender: Any?) {
        print("Menu action: Add Bookmark Folder")
        bookmarkViewModel?.showCreateFolderSheet()
    }
    @MainActor @objc func openBookmark(_ sender: Any?){
        guard let bookmarkViewModel = self.bookmarkViewModel else { return }
        browserViewModel?.openBookmarkForSelected(bookmarkViewModel: bookmarkViewModel)
    }
    
    // MARK: - Helper Methods for File Dialogs
    private func showImportBookmarksDialog() {
        let panel = NSOpenPanel()
        panel.title = "Import Bookmarks"
        panel.allowedContentTypes = [.html, .json] // Common bookmark export formats
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.importBookmarksFromFile(url)
            }
        }
    }
    
    private func showExportBookmarksDialog() {
        let panel = NSSavePanel()
        panel.title = "Export Bookmarks"
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = "bookmarks.html"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.exportBookmarksToFile(url)
            }
        }
    }
    
    private func importBookmarksFromFile(_ url: URL) {
        // Implementation for importing bookmarks
        // This would parse the file and add bookmarks to your system
        print("Importing bookmarks from: \(url)")
        // You might want to call bookmarkViewModel methods here
    }
    
    private func exportBookmarksToFile(_ url: URL) {
        // Implementation for exporting bookmarks
        print("Exporting bookmarks to: \(url)")
        // Generate HTML or JSON from your bookmarks and save to file
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
        // Bookmark menu validation
        case #selector(addBookmark(_:)):
            return viewModel.currentTab != nil
        case #selector(showAllBookmarks(_:)):
            return true
        case #selector(bookmarkAllTabs(_:)):
            return !viewModel.tabs.isEmpty
        case #selector(importBookmarks(_:)), #selector(exportBookmarks(_:)):
            return true
        case #selector(organizeBookmarks(_:)), #selector(addBookmarkFolder(_:)):
            return bookmarkViewModel != nil
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
