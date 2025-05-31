//
//  BottomActions.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

// MARK: - Bottom Actions
struct BottomActions: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var showNewMenu = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)

            HStack(spacing: 16) {
                ActionButton(icon: "gear", tooltip: "Settings", action: {
                    // Settings action
                })

                ActionButton(icon: "plus", tooltip: "New Tab or Space",  action: {
                    showNewMenu = true
                })
                .popover(isPresented: $showNewMenu, arrowEdge: .top) {
                    NewItemMenu(viewModel: viewModel, showMenu: $showNewMenu)
                }

                // Enhanced Space Navigation
                SpaceNavigationView(viewModel: viewModel)
               
                Spacer()

                ActionButton(icon: "sidebar.right", tooltip: "Toggle Sidebar", action: {
                    withAnimation {
                        viewModel.columnVisibility = .detailOnly
                    }
                })
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Space Navigation View
struct SpaceNavigationView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var showAllSpaces = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Show up to 3 spaces inline, then overflow indicator
            ForEach(Array(viewModel.spaces.prefix(3).enumerated()), id: \.element.id) { index, space in
                SpaceChip(
                    viewModel: viewModel,
                    space: space,
                    index: index
                )
            }
            
            // Overflow indicator if more than 3 spaces
            if viewModel.spaces.count > 3 {
                OverflowSpaceButton(
                    count: viewModel.spaces.count - 3,
                    action: { showAllSpaces = true }
                )
            }
        }
        .sheet(isPresented: $showAllSpaces) {
            SpaceGridView(viewModel: viewModel)
        }
    }
}

// MARK: - Space Chip (Redesigned from SpaceDot)
struct SpaceChip: View {
    @ObservedObject var viewModel: BrowserViewModel
    let space: Space
    let index: Int
    @State private var isHovered = false
    @State private var isPressed = false

    var isSelected: Bool {
        viewModel.currentSpace?.id == space.id
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.selectSpace(space)
                viewModel.isShowingSpaceInfoPopover = false
            }
        }) {
            HStack(spacing: 6) {
                // Color indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.spaceColor(space.color))
                    .frame(width: 4, height: 16)
                
                // Space name or index
                if isSelected || isHovered {
                    Text(space.name.isEmpty ? "Space \(index + 1)" : space.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                }
            }
            .padding(.horizontal, isSelected || isHovered ? 10 : 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        Color.spaceColor(space.color).opacity(0.15) :
                        (isHovered ? Color.primary.opacity(0.06) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.spaceColor(space.color).opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .pressEvents(
            onPress: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
            },
            onRelease: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        )
        .contextMenu {
            SpaceContextMenu(viewModel: viewModel, space: space)
        }
    }
}

// MARK: - Overflow Space Button
struct OverflowSpaceButton: View {
    let count: Int
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("+\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(isHovered ? 0.06 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Space Grid View (for overflow)
struct SpaceGridView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.dismiss) private var dismiss
    
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(viewModel.spaces.enumerated()), id: \.element.id) { index, space in
                        SpaceCard(
                            viewModel: viewModel,
                            space: space,
                            index: index,
                            onSelect: { dismiss() }
                        )
                    }
                    
                    // Add new space card
                    AddSpaceCard(viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("Spaces")
           // .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Space Card
struct SpaceCard: View {
    @ObservedObject var viewModel: BrowserViewModel
    let space: Space
    let index: Int
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var isSelected: Bool {
        viewModel.currentSpace?.id == space.id
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.selectSpace(space)
                onSelect()
            }
        }) {
            VStack(spacing: 12) {
                // Space visual representation
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.spaceColor(space.color),
                                Color.spaceColor(space.color).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 60)
                    .overlay(
                        VStack(spacing: 4) {
                            Text("\(space.tabs.count)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("tabs")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
                
                VStack(spacing: 4) {
                    Text(space.name.isEmpty ? "Space \(index + 1)" : space.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(space.tabs.count) tab\(space.tabs.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.spaceColor(space.color).opacity(0.4) :
                                (isHovered ? Color.primary.opacity(0.1) : Color.primary.opacity(0.05)),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            SpaceContextMenu(viewModel: viewModel, space: space)
        }
    }
}

// MARK: - Add Space Card
struct AddSpaceCard: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            viewModel.isShowingCreateSpaceSheet = true
        }) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary.opacity(0.6))
                    )
                
                VStack(spacing: 4) {
                    Text("New Space")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Create workspace")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            
//                            .stroke(
//                                Color.primary.opacity(isHovered ? 0.15 : 0.08),
//                                lineWidth: 1,
//                                lineCap: .round,
//                                dash: [5, 3]
//                            )
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Space Context Menu
struct SpaceContextMenu: View {
    @ObservedObject var viewModel: BrowserViewModel
    let space: Space
    
    var body: some View {
        Group {
            Button("Rename Space") {
                // Handle rename
            }
            
            Button("Duplicate Space") {
                // Handle duplicate
            }
            
            Divider()
            
            Button("Close All Tabs") {
                // Handle close all tabs
            }
            
            //if viewModel.spaces.count > 1 {
                Button("Delete Space", role: .destructive) {
                    viewModel.deleteSpace(space)
                }
          //  }
        }
    }
}

// MARK: - Extensions
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}

// MARK: - Existing Components (unchanged)
struct NewItemMenu: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuButton(
                icon: "plus.rectangle",
                title: "New tab...",
                action: {
                    viewModel.createNewTab()
                    showMenu = false
                }
            )
            
            Divider()
                .padding(.horizontal, 8)
            
            MenuButton(
                icon: "square.stack.3d.up",
                title: "New space...",
                action: {
                    viewModel.isShowingCreateSpaceSheet = true
                    showMenu = false
                }
            )
        }
        .padding(.vertical, 8)
        .frame(width: 160)
        .background(.regularMaterial)
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

