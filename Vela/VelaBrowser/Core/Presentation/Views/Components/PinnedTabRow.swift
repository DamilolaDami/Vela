//
//  PinnedTabRow.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI

struct PinnedTabRow: View {
    @ObservedObject var viewModel: BrowserViewModel
    let tab: Tab
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Favicon or default icon
            TabIcon(tab: tab)
            
            // Title (more compact for pinned tabs)
            Text(tab.title)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
            
            Spacer()
            
            // Pin indicator
            Image(systemName: "pin.fill")
                .font(.system(size: 8))
                .foregroundColor(.orange)
                .opacity(isHovered || isSelected ? 1.0 : 0.6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6) // Slightly more compact than regular tabs
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isSelected ?
                    Color.orange.opacity(0.1) : // Different highlight for pinned tabs
                    Color(NSColor.controlBackgroundColor).opacity(isHovered ? 1.0 : 0)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.orange.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Capsule())
        .contextMenu {
            TabContextMenu(tab: tab, viewModel: viewModel)
        }
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                onHover(hovering)
            }
        }
    }
}
