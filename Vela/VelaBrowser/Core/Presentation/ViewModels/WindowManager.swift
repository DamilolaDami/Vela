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
    
    @Published private var windowData: [(window: NSWindow, coordinator: WebViewCoordinator)] = []
    
    private init() {}
    
    func addWindow(_ window: NSWindow, with coordinator: WebViewCoordinator) {
        windowData.append((window: window, coordinator: coordinator))
        
        // Set up window delegate to clean up when closed
        window.delegate = WindowDelegate(window: window, coordinator: coordinator, manager: self)
    }
    
    func removeWindow(_ window: NSWindow) {
        if let index = windowData.firstIndex(where: { $0.window === window }) {
            let coordinator = windowData[index].coordinator
            
            // Clean up coordinator
            if let webView = window.contentView as? WKWebView {
                coordinator.removeObservers(from: webView)
            }
            
            windowData.remove(at: index)
        }
    }
    
    var windowCount: Int {
        return windowData.count
    }
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
        if let window = window {
            manager?.removeWindow(window)
        }
    }
}
