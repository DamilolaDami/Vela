//
//  TabRow.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI


struct TabRow: View {
    @ObservedObject var viewModel: BrowserViewModel
    let tab: Tab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered = false
    @State private var showCloseButton = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Favicon or loading indicator
            Group {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else if let faviconData = tab.favicon,
                          let nsImage = NSImage(data: faviconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                }
            }
            
            // Tab content
            VStack(alignment: .leading, spacing: 2) {
                // Title
                Text(tab.title.isEmpty ? "Untitled" : tab.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // URL
                if let url = tab.url {
                    Text(url.host ?? url.absoluteString)
                        .font(.system(size: 11))
                        .foregroundColor(.teal)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            // Close button
            if showCloseButton || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(.quaternary)
                                .opacity(isHovered ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
                .opacity(showCloseButton ? 1 : 0.7)
                .animation(.easeInOut(duration: 0.2), value: showCloseButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(tabBackgroundColor)
                .opacity(backgroundOpacity)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectionBorderColor, lineWidth: 1)
                .opacity(isSelected ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                showCloseButton = hovering
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .contextMenu {
            TabContextMenu(tab: tab, onClose: onClose)
        }
    }
    
    private var tabBackgroundColor: Color {
        if isSelected {
            return .primary
        } else if isHovered {
            return .secondary
        } else {
            return .clear
        }
    }
    
    private var backgroundOpacity: Double {
        if isSelected {
            return 0.1
        } else if isHovered {
            return 0.05
        } else {
            return 0
        }
    }
    
    private var selectionBorderColor: Color {
        viewModel.currentSpace?.color.color ?? .blue
    }
}

// MARK: - TabContextMenu.swift
import SwiftUI

struct TabContextMenu: View {
    let tab: Tab
    let onClose: () -> Void
    
    var body: some View {
        Group {
            Button("Reload") {
                // TODO: Reload tab
            }
            
            Button("Duplicate") {
                // TODO: Duplicate tab
            }
            
            Divider()
            
            Button("Move to New Space") {
                // TODO: Move to new space
            }
            
            Button("Pin Tab") {
                // TODO: Pin tab
            }
            
            Divider()
            
            Button("Close Tab", action: onClose)
            
            Button("Close Other Tabs") {
                // TODO: Close other tabs
            }
        }
    }
}
