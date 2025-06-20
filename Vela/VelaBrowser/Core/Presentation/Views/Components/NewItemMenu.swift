//
//  NewItemMenu.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//
import SwiftUI

struct NewItemMenu: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Binding var showMenu: Bool
    
    var body: some View {
        let currentSpace = viewModel.currentSpace
        VStack(alignment: .leading, spacing: 0) {
            // Primary Actions Section
            MenuSection {
                MenuButton(
                                    icon: "plus.rectangle.on.rectangle",
                                    title: "New Tab",
                                    subtitle: "Create a new tab",
                                    shortcut: "⌘T",
                                    spaceColor: currentSpace?.displayColor ?? .blue,
                                    action: {
                                        viewModel.startCreatingNewTab()
                                        showMenu = false
                                    }
                                )
                                
                                MenuButton(
                                    icon: "square.stack.3d.up.fill",
                                    title: "New Space",
                                    subtitle: "Create a new workspace",
                                    shortcut: "⌘⇧N",
                                    spaceColor: currentSpace?.displayColor ?? .blue,
                                    action: {
                                        viewModel.isShowingCreateSpaceSheet = true
                                        showMenu = false
                                    }
                                )
                            }
                            
                            MenuDivider()
                            
                            // Organization Section
                            MenuSection {
                                MenuButton(
                                    icon: "folder.badge.plus",
                                    title: "New Folder",
                                    subtitle: "Organize your tabs",
                                    isDisabled: false,
                                    spaceColor: currentSpace?.displayColor ?? .blue,
                                    action: {
                                        viewModel.createFolder(name: "Untitled Folder")
                                        showMenu = false
                                    }
                                )
                            }
                            
                            MenuDivider()
                            
                            // Advanced Actions Section
            MenuSection {
                MenuButton(
                    icon: "rectangle.grid.2x2",
                    title: "New Board",
                    subtitle: "Collaborative workspace",
                    shortcut: "⌃⌥B",
                    spaceColor: currentSpace?.displayColor ?? .blue,
                    action: {
                        // Handle board creation
                        showMenu = false
                    }
                )
                
                
                MenuButton(
                    icon: "rectangle.split.2x1",
                    title: "New Split",
                    subtitle: "Split view mode",
                    shortcut: "⌃⌥=",
                    spaceColor: currentSpace?.displayColor ?? .blue,
                    action: {
                        // Handle split creation
                        showMenu = false
                    }
                )
            }
            
        }
        .padding(.vertical, 8)
        .frame(width: 230)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator.opacity(0.5), lineWidth: 0.5)
        )
    }
}

struct MenuSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            content
        }
        .padding(.horizontal, 6)
    }
}

struct MenuDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let shortcut: String?
    let isDisabled: Bool
    let spaceColor: Color?
    let action: () -> Void
    
    @State private var isHovered = false
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        shortcut: String? = nil,
        isDisabled: Bool = false,
        spaceColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.shortcut = shortcut
        self.isDisabled = isDisabled
        self.spaceColor = spaceColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(iconForegroundColor)
                        .frame(width: 32, height: 32)
               
                
                // Content
                VStack(alignment: .leading, spacing: 1) {
                    HStack{
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
//                    if let subtitle = subtitle {
//                        Text(subtitle)
//                            .font(.system(size: 11))
//                            .foregroundColor(subtitleColor)
//                    }
                }
                
                Spacer()
                
                // Shortcut
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(shortcutColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(shortcutBackgroundColor)
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundHoverColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Computed Colors

    
    private var iconForegroundColor: Color {
        if isDisabled {
            return Color.primary.opacity(0.3)
        }
        return isHovered ? Color.white : Color.primary.opacity(0.8)
    }
    
    private var textColor: Color {
        isDisabled ? Color.primary.opacity(0.4) : isHovered ? Color.white : Color.primary
    }
    
    private var subtitleColor: Color {
        isDisabled ? Color.secondary.opacity(0.4) : isHovered ? Color.white : Color.secondary
    }
    
    private var shortcutColor: Color {
        isDisabled ? Color.secondary.opacity(0.4) : Color.secondary
    }
    
    private var shortcutBackgroundColor: Color {
        isDisabled ? Color.primary.opacity(0.03) : Color.primary.opacity(0.05)
    }
    
    private var backgroundHoverColor: Color {
        if isDisabled {
            return Color.clear
        }
        return isHovered ? (spaceColor ?? .blue).opacity(0.4) : Color.clear
    }
}

