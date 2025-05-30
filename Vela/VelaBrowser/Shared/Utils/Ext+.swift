//
//  Ext+.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUICore
import CoreData
import AppKit


// MARK: - Color Extensions

extension Color {
    static let tabBackground = Color(NSColor.controlBackgroundColor)
    static let tabSelectedBackground = Color(NSColor.selectedContentBackgroundColor)
    static let tabHoverBackground = Color(NSColor.controlAccentColor).opacity(0.1)
    static let tabBorder = Color(NSColor.separatorColor)
    static let tabSelectedBorder = Color(NSColor.keyboardFocusIndicatorColor)
    static func spaceColor(_ spaceColor: Space.SpaceColor) -> Color {
        switch spaceColor {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .gray: return .gray
        }
    }
}

extension Space.SpaceColor {
    var color: Color {
        Color.spaceColor(self)
    }
}


extension View {
    func progressTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity.combined(with: .move(edge: .top))
        ))
    }
        func withNotificationBanners() -> some View {
            ZStack(alignment: .top) {
                self
                NotificationBannerContainer()
            }
        }
    func browserKeyboardShortcuts(viewModel: BrowserViewModel) -> some View {
            self.modifier(BrowserKeyboardShortcutModifier(viewModel: viewModel))
        }

}


extension NSApplication {
    func setupBrowserKeyboardShortcuts(for viewModel: BrowserViewModel) {
        // This approach gives you more control over key event handling
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode
            let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""
            
            // Handle Control+Tab and Control+Shift+Tab for tab switching
            if modifiers.contains(.control) && keyCode == 48 { // Tab key
                if modifiers.contains(.shift) {
                    viewModel.selectPreviousTab()
                } else {
                    viewModel.selectNextTab()
                }
                return nil // Consume the event
            }
            
            return event // Let other events pass through
        }
    }
}

extension NSMenu {
    static func createBrowserMenu(for viewModel: BrowserViewModel) -> NSMenu {
        let menu = NSMenu(title: "Browser")
        
        // File Menu
        let fileMenu = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileSubmenu = NSMenu(title: "File")
        
        fileSubmenu.addItem(withTitle: "New Tab", action: #selector(BrowserMenuHandler.newTab), keyEquivalent: "t")
        fileSubmenu.addItem(withTitle: "New Tab in Background", action: #selector(BrowserMenuHandler.newTabInBackground), keyEquivalent: "T")
        fileSubmenu.addItem(withTitle: "Close Tab", action: #selector(BrowserMenuHandler.closeTab), keyEquivalent: "w")
        
        fileMenu.submenu = fileSubmenu
        menu.addItem(fileMenu)
        
        return menu
    }
}

@objc class BrowserMenuHandler: NSObject {
    static weak var viewModel: BrowserViewModel?
    
    @MainActor @objc static func newTab() {
        viewModel?.createNewTab()
    }
    
    @MainActor @objc static func newTabInBackground() {
        viewModel?.createNewTab(inBackground: true)
    }
    
    @MainActor @objc static func closeTab() {
        viewModel?.closeCurrentTab()
    }
}


struct BrowserKeyboardShortcutModifier: ViewModifier {
    @StateObject private var keyEventHandler: GlobalKeyEventHandler
    private let viewModel: BrowserViewModel

    init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
        self._keyEventHandler = StateObject(wrappedValue: GlobalKeyEventHandler(viewModel: viewModel))
    }

    func body(content: Content) -> some View {
        content
    }
}
