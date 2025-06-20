//
//  SpaceNavigationView.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//
import SwiftUI

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
                .frame(width: 600, height: 500)
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
     //   NavigationView {
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
           // .navigationTitle("Spaces")
//           // .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigation) {
//                    Button("Done") { dismiss() }
//                }
//            }
//        }
//        .presentationDetents([.medium, .large])
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
                                space.displayColor,
                                space.displayColor.opacity(0.7)
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
                                isSelected ? space.displayColor.opacity(0.4) :
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



// MARK: - Custom Tooltip View
struct CustomTooltip: View {
    let text: String
    let shortcut: String
    
    private var dynamicWidth: CGFloat {
        let baseWidth: CGFloat = 60
        let textWidth = CGFloat(text.count * 7) // Approximate character width
        let shortcutWidth = CGFloat(shortcut.count * 6 + 12) // Plus padding
        return max(baseWidth, textWidth + shortcutWidth + 30) // Plus spacing and padding
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
            
            Text(shortcut)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: dynamicWidth)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Tooltip Modifier
struct TooltipModifier: ViewModifier {
    let text: String
    let shortcut: String
    @State private var showTooltip = false
    @State private var hoverTimer: Timer?
    
    func body(content: Content) -> some View {
        content
            .onHover { isHovering in
                if isHovering {
                    // Delay showing tooltip by 0.5 seconds
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTooltip = true
                        }
                    }
                } else {
                    // Cancel timer and hide tooltip immediately
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showTooltip = false
                    }
                }
            }
            .overlay(
                Group {
                    if showTooltip {
                        CustomTooltip(text: text, shortcut: shortcut)
                            .offset(y: -45) // Position above the element
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            ))
                            .zIndex(1000)
                    }
                },
                alignment: .top
            )
    }
}

// MARK: - View Extension
extension View {
    func tooltip(text: String, shortcut: String) -> some View {
        modifier(TooltipModifier(text: text, shortcut: shortcut))
    }
}

// MARK: - SpaceChip with Tooltip
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
                if viewModel.currentSpace?.id != space.id {
                    viewModel.selectSpace(space)
                 
                }
                viewModel.isShowingSpaceInfoPopover = false
            }
        }) {
            HStack(spacing: 6) {
                space.displayIcon
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? space.displayColor : .primary)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
            }
            .frame(width: 28, height: 28)
            .background(
                isHovered ? RoundedRectangle(cornerRadius: 5)
                    .fill(Color(NSColor.quaternaryLabelColor))
                :  RoundedRectangle(cornerRadius: 5)
                    .fill(Color.clear)
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
        .tooltip(
            text: space.name.isEmpty ? "Space \(index + 1)" : space.name,
            shortcut: "⌃\(index + 1)"
        )
    }
}

// MARK: - Updated OverflowSpaceButton with Tooltip
struct OverflowSpaceButton: View {
    let count: Int
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? Color(NSColor.quaternaryLabelColor) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .tooltip(
            text: "\(count) more spaces",
            shortcut: "⌃⇧S"
        )
    }
}
