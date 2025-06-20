import Foundation
import AppKit
import SwiftUI

class Space: Identifiable, Equatable {
    let id: UUID
    var name: String
    var color: SpaceColor
    var customHexColor: String?
    var tabs: [Tab] = []
    let createdAt: Date
    var position: Int?
    var isDefault: Bool = false
    
    // Icon properties
    var iconType: IconType = .emoji
    var iconValue: String = "🌟" // Default emoji
    
    init(
        id: UUID = UUID(),
        name: String,
        color: SpaceColor,
        customHexColor: String? = nil,
        tabs: [Tab] = [],
        createdAt: Date = Date(),
        position: Int? = nil,
        isDefault: Bool = false,
        iconType: IconType = .emoji,
        iconValue: String = "🌟"
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.customHexColor = customHexColor
        self.tabs = tabs
        self.createdAt = createdAt
        self.position = position
        self.isDefault = isDefault
        self.iconType = iconType
        self.iconValue = iconValue
    }
    
    enum SpaceColor: String, CaseIterable {
        case blue, purple, pink, red, orange, yellow, green, gray, custom
    }
    
 
    static func == (lhs: Space, rhs: Space) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.color == rhs.color &&
               lhs.customHexColor == rhs.customHexColor &&
               lhs.tabs == rhs.tabs &&
               lhs.createdAt == rhs.createdAt &&
               lhs.position == rhs.position &&
               lhs.isDefault == rhs.isDefault &&
               lhs.iconType == rhs.iconType &&
               lhs.iconValue == rhs.iconValue
    }
    
    // Updated helper to get the actual display color
    var displayColor: Color {
        if color == .custom, let hexColor = customHexColor, let nsColor = NSColor(hex: hexColor) {
            return Color(nsColor)
        }
        return Color.spaceColor(color)
    }
    
    // Helper to get the display icon view
    @ViewBuilder
    var displayIcon: some View {
        switch iconType {
        case .emoji:
            Text(iconValue)
                .font(.system(size: 11))
                .frame(width: 13, height: 13)
                .fixedSize()
        case .systemImage:
            Image(systemName: iconValue)
                .font(.system(size: 12, weight: .medium))
        case .custom:
            // For custom icons, you might want to load from a file path
            // For now, fallback to system image
            Image(systemName: iconValue.isEmpty ? "folder" : iconValue)
                .font(.system(size: 12, weight: .medium))
        }
    }
    
    // Helper to convert SpaceColor to Color (for predefined colors)
    static func spaceColor(_ color: SpaceColor) -> Color {
        switch color {
        case .blue: return Color.blue
        case .purple: return Color.purple
        case .pink: return Color.pink
        case .red: return Color.red
        case .orange: return Color.orange
        case .yellow: return Color.yellow
        case .green: return Color.green
        case .gray: return Color.gray
        case .custom: return Color.blue
        }
    }
    
    // Method to set a custom color
    func setCustomColor(_ color: Color) {
        self.color = .custom
        self.customHexColor = color.toHexString()
    }
    
    // Method to set a predefined color
    func setPredefinedColor(_ color: SpaceColor) {
        guard color != .custom else { return }
        self.color = color
        self.customHexColor = nil
    }
    
    // Method to set icon
    func setIcon(type: IconType, value: String) {
        self.iconType = type
        self.iconValue = value
    }
}

// Extend Space for hex color storage
extension Space {
    var hexColor: String {
        let nsColor = NSColor(Space.spaceColor(color)) // Convert SpaceColor to Color, then to NSColor
        return nsColor.toHexString() ?? "#000000"
    }
    
    func updateColor(from hex: String) {
        if let color = NSColor(hex: hex) {
            let swiftUIColor = Color(color)
            self.color = swiftUIColor.toSpaceColor()
        }
    }
}

extension NSColor {
    func toHexString() -> String? {
        guard let components = cgColor.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}


enum IconType: String, CaseIterable, Codable {
    case emoji = "emoji"
    case systemImage = "system"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .emoji: return "Emoji"
        case .systemImage: return "System"
        case .custom: return "Custom"
        }
    }
}
