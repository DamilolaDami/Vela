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
    
    var body: some View {
        HStack(spacing: 12) {
            // Favicon - simple and clean
            Group {
                if tab.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .frame(width: 16, height: 16)
                } else if let faviconData = tab.favicon,
                          let nsImage = NSImage(data: faviconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                }
            }
            
            // Tab title and URL - Arc's minimal approach
            VStack(alignment: .leading, spacing: 1) {
                Text(tab.title.isEmpty ? "Untitled" : tab.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if let url = tab.url {
                    Text(cleanURL(from: url))
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            // Close button - only show on hover or selection
            if isHovered {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(isSelected ? Color.white : Color.clear)
        )
        .overlay(
            // Arc's signature left border for selected tab
            Rectangle()
                .fill(viewModel.currentSpace?.color.color ?? .blue)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0),
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            TabContextMenu(tab: tab, onClose: onClose)
        }
    }
    
    private func cleanURL(from url: URL) -> String {
        if let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return url.absoluteString
    }
}

// MARK: - TabContextMenu

struct TabContextMenu: View {
    let tab: Tab
    let onClose: () -> Void
    
    var body: some View {
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
