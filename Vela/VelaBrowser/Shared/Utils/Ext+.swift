//
//  Ext+.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUICore
import CoreData
import AppKit
import WebKit


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
        case .custom: return .blue // Fallback, should use Space.displayColor instead
        }
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    func toHexString() -> String {
        let nsColor = NSColor(self)
        guard let components = nsColor.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    func toSpaceColor() -> Space.SpaceColor {
        let nsColor = NSColor(self)
        guard let components = nsColor.cgColor.components, components.count >= 3 else {
            return .gray
        }
        
        let r = components[0], g = components[1], b = components[2]
        
        // Check if it matches any predefined colors (with some tolerance)
        let predefinedColors: [(Space.SpaceColor, Color)] = [
            (.blue, .blue), (.purple, .purple), (.pink, .pink), (.red, .red),
            (.orange, .orange), (.yellow, .yellow), (.green, .green), (.gray, .gray)
        ]
        
        for (spaceColor, color) in predefinedColors {
            if self.isApproximatelyEqual(to: color, tolerance: 0.2) {
                return spaceColor
            }
        }
        
        return .custom // It's a custom color
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
            ZStack(alignment: .topTrailing) {
                self
                NotificationBannerContainer()
            }
        }
    func browserKeyboardShortcuts(viewModel: BrowserViewModel) -> some View {
            self.modifier(BrowserKeyboardShortcutModifier(viewModel: viewModel))
        }
        func glassBackground(
            material: NSVisualEffectView.Material = .contentBackground,
            blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
        ) -> some View {
            self.modifier(
                GlassBackground(
                    material: material,
                    blendingMode: blendingMode
                )
                
            )
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

extension Tab {
    /// Captures a fresh snapshot of the tab's web view
    func captureSnapshot(completion: @escaping (NSImage?) -> Void) {
        guard let webView = self.webView else {
            completion(nil)
            return
        }
        
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: 0, y: 0, width: webView.bounds.width, height: webView.bounds.height)
        
        webView.takeSnapshot(with: config) { image, error in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    /// Whether this tab can show a preview (has a loaded web view)
    var canShowPreview: Bool {
        return webView != nil && !isLoading && url != nil
    }
}

extension TabPreview {
    struct Preferences {
        static let previewDelay: TimeInterval = 0.8
        static let previewWidth: CGFloat = 344
        static let previewHeight: CGFloat = 240
        static let thumbnailWidth: CGFloat = 320
        static let thumbnailHeight: CGFloat = 180
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 12
        static let shadowOffset: CGSize = CGSize(width: 0, height: 4)
    }
}




public extension URLValidator {
    
    /// Predefined configurations for common use cases
    enum Preset {
        /// Strict validation for production environments
        public static var strict: Configuration {
            return Configuration(
                allowedSchemes: ["https"],
                allowLocalhost: false,
                allowIPAddresses: false,
                requireTLD: true,
                performDNSValidation: true
            )
        }
        
        /// Relaxed validation for development
        public static var development: Configuration {
            return Configuration(
                allowedSchemes: ["http", "https"],
                allowLocalhost: true,
                allowIPAddresses: true,
                requireTLD: false,
                performDNSValidation: false
            )
        }
        
        /// Web browser compatible validation
        public static var browser: Configuration {
            return Configuration(
                allowedSchemes: ["http", "https"],
                allowLocalhost: true,
                allowIPAddresses: true,
                requireTLD: true,
                performDNSValidation: false
            )
        }
        
        /// API endpoint validation
        public static var api: Configuration {
            return Configuration(
                allowedSchemes: ["https"],
                allowLocalhost: false,
                allowIPAddresses: true,
                requireTLD: true,
                performDNSValidation: true,
                networkTimeout: 3.0
            )
        }
    }
    
    /// Validate using a preset configuration
    /// - Parameters:
    ///   - urlString: URL string to validate
    ///   - preset: Predefined configuration preset
    /// - Returns: Validation result
    func validate(_ urlString: String, using preset: Configuration) -> ValidationResult {
        return validate(urlString, configuration: preset)
    }
}

// MARK: - String Extension

public extension String {
    
    /// Validate this string as a URL
    /// - Parameter validator: URLValidator instance (default: shared)
    /// - Returns: ValidationResult
    func validateAsURL(using validator: URLValidator = .shared) -> URLValidator.ValidationResult {
        return validator.validate(self)
    }
    
    /// Check if this string is a valid URL
    /// - Parameter validator: URLValidator instance (default: shared)
    /// - Returns: Boolean indicating validity
    var isValidURL: Bool {
        return URLValidator.shared.isValid(self)
    }
    
    /// Sanitize this string as a URL
    /// - Parameter validator: URLValidator instance (default: shared)
    /// - Returns: Sanitized URL string or nil
    func sanitizedAsURL(using validator: URLValidator = .shared) -> String? {
        return validator.sanitize(self)
    }
}


extension URL {
    var urlBase: String? {
        // Return the host component, which gives us the base domain (e.g., "github.com")
        return host
    }
}


extension Notification.Name {
    static let downloadStarted = Notification.Name("downloadStarted")
    static let downloadItemAdded = Notification.Name("downloadItemAdded")
}
