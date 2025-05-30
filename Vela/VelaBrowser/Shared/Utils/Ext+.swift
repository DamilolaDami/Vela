//
//  Ext+.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUICore
import CoreData


// MARK: - Color Extensions

extension Color {
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
