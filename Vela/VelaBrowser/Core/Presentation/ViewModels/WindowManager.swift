//
//  WindowManager.swift
//  Vela
//
//  Created by damilola on 6/1/25.
//

import SwiftUI
import WebKit

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published private var windowData: [WindowData] = []
    
    private init() {}
    
    func addWindow(_ window: NSWindow, with coordinator: WebViewCoordinator) {
        // Create a strong reference to the delegate
        let delegate = WindowDelegate(window: window, coordinator: coordinator, manager: self)
        
        let data = WindowData(
            window: window,
            coordinator: coordinator,
            delegate: delegate
        )
        
        windowData.append(data)
        
        // Set the delegate AFTER storing it
        window.delegate = delegate
        
        print("🪟 Added window. Total count: \(windowData.count)")
    }
    
    func removeWindow(_ window: NSWindow) {
        if let index = windowData.firstIndex(where: { $0.window === window }) {
            let data = windowData[index]
            
            print("🪟 Removing window. Current count: \(windowData.count)")
            
            // Clean up coordinator and web view
            cleanupWindow(data)
            
            // Remove from array
            windowData.remove(at: index)
            
            print("🪟 Window removed. New count: \(windowData.count)")
        }
    }
    
    private func cleanupWindow(_ data: WindowData) {
        // Clear the window delegate first to prevent further callbacks
        data.window.delegate = nil
        
        // Clean up the web view if it exists
        if let webView = data.window.contentView as? WKWebView {
            // Stop loading
            webView.stopLoading()
            
            // Remove observers
            data.coordinator.removeObservers(from: webView)
            
            // Clear delegates
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            
//            // If it's an AudioObservingWebView, stop audio observation
//            if let audioWebView = webView as? AudioObservingWebView {
//                audioWebView.stopObservingAudio()
//            }
        }
        
        // Clear coordinator references
        data.coordinator.browserViewModel = nil
    }
    
    var windowCount: Int {
        return windowData.count
    }
    
    // Clean up method for app termination
    func cleanupAllWindows() {
        for data in windowData {
            cleanupWindow(data)
        }
        windowData.removeAll()
    }
}

// MARK: - Window Data Structure
struct WindowData {
    let window: NSWindow
    let coordinator: WebViewCoordinator
    let delegate: WindowDelegate // Strong reference to keep delegate alive
}

// MARK: - Updated Window Delegate
class WindowDelegate: NSObject, NSWindowDelegate {
    weak var window: NSWindow?
    weak var coordinator: WebViewCoordinator?
    weak var manager: WindowManager?
    
    init(window: NSWindow, coordinator: WebViewCoordinator, manager: WindowManager) {
        self.window = window
        self.coordinator = coordinator
        self.manager = manager
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = window else { return }
        
        print("🪟 Window will close notification received")
        
        // Remove from manager
        manager?.removeWindow(window)
        
        // Clear references
        self.window = nil
        self.coordinator = nil
        self.manager = nil
    }
    
    deinit {
        print("🪟 WindowDelegate deallocated")
    }
}
