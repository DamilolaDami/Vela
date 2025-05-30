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
}
