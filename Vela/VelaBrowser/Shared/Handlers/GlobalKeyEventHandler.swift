//
//  GlobalKeyEventHandler.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI
import AppKit

class GlobalKeyEventHandler: ObservableObject {
    private var eventMonitor: Any?
    private weak var viewModel: BrowserViewModel?

    init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
        setupEventMonitor()
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let viewModel = self?.viewModel else { return event }
            
            // Let the menu system handle the event first
            if NSApp.mainMenu?.performKeyEquivalent(with: event) == true {
                return nil // Menu handled the event, consume it
            }
            
            // Handle custom shortcuts
            if let shortcut = KeyboardShortcut.from(event: event) {
                DispatchQueue.main.async {
                    viewModel.handleKeyboardShortcut(shortcut)
                }
                return nil // Consume the event
            }
            
            return event // Let unhandled events pass through
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
