//
//  TabRow.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

// MARK: - Enhanced Tab Row
struct TabRow: View {
    @ObservedObject var viewModel: BrowserViewModel
    let tab: Tab
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Favicon or default icon
            TabIcon(tab: tab)
            
            // Title
            VStack(alignment: .leading, spacing: 1) {
                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                
                if let url = tab.url {
                    Text(url.host ?? "")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Close button (shown on hover or selection)
            if isHovered || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(Color(NSColor.separatorColor).opacity(0.3))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected ?
                    Color.white :
                    Color(NSColor.controlBackgroundColor).opacity(isHovered ? 1.0 : 0)
                )
                .shadow(
                    color: isSelected ? Color.black.opacity(0.1) : Color.clear,
                    radius: isSelected ? 4 : 0,
                    x: 0,
                    y: isSelected ? 2 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.gray.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
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

struct TabIcon: View {
    let tab: Tab
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(NSColor.quaternaryLabelColor))
                .frame(width: 20, height: 20)
            
            // Use favicon if available, otherwise show default icon
            Group {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let faviconData = tab.favicon,
                          let nsImage = NSImage(data: faviconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: Color(NSColor.shadowColor).opacity(0.2), radius: 1, x: 0, y: 0.5)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: 16, height: 16)
                }
            }
        }
    }
}



// MARK: - Tab Context Menu
struct TabContextMenu: View {
    let tab: Tab
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        Group {
            Button("Reload Tab") {
                viewModel.reloadTab(tab)
            }
            
            Button("Duplicate Tab") {
                viewModel.duplicateTab(tab)
            }
            
            Divider()
            
            Button("Pin Tab") {
                viewModel.pinTab(tab)
            }
            
            Button("Mute Tab") {
                viewModel.muteTab(tab)
            }
            
            Divider()
            
            Button("Close Tab") {
                viewModel.closeTab(tab)
            }
            
            Button("Close Other Tabs") {
                viewModel.closeOtherTabs(except: tab)
            }
            
            Button("Close Tabs to the Right") {
                viewModel.closeTabsToRight(of: tab)
            }
        }
    }
}
