import SwiftUI

struct TabsSection: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @Binding var hoveredTab: UUID?
    
    // Track the previous space to determine slide direction
    @State private var previousSpaceIndex: Int = 0
    @State private var slideDirection: SlideDirection = .none
    @State private var isSpaceHeaderHovered: Bool = false
    
    enum SlideDirection {
        case none, left, right
    }
    
    // Computed properties to separate pinned and regular tabs
    private var pinnedTabs: [Tab] {
        viewModel.tabs.filter { $0.isPinned }
    }
    
    private var regularTabs: [Tab] {
        viewModel.tabs.filter { !$0.isPinned }
    }
    
    var body: some View {
        // Wrap the entire content in a container that manages the transition
      //  GeometryReader { geometry in
            ZStack {
                // The main content with proper clipping
                tabsContent
                    .clipped() // This ensures content doesn't overflow during transition
                    //.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .transition(slideTransition)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.currentSpace?.id)
                    .id(viewModel.currentSpace?.id) // Force view recreation for each space
            }
            .clipped() // Additional clipping at container level
      //  }
        .onChange(of: viewModel.currentSpace?.id) { _, newSpaceId in
            updateSlideDirection()
        }
    }
    
    // Extract the main content into a separate computed property
    private var tabsContent: some View {
        VStack(spacing: 8) {
            // Space Header with Edit Button
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Text("\(viewModel.currentSpace?.name ?? "Personal Space")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(Color(NSColor.separatorColor))
                            .frame(height: 0.5)
                    }
                    .frame(minWidth: 20) // Ensure minimum separator width
                    
                    HStack(spacing: 6) {
                        Text("\(viewModel.tabs.count) tabs")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                        
                        // Edit button that appears on hover
                        if isSpaceHeaderHovered {
                            Button(action: {
                                // Handle edit action here
                                // viewModel.editCurrentSpace()
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .fill(Color(NSColor.controlBackgroundColor))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                            .onHover { hovering in
                                // Keep the edit button visible when hovering over it
                                if hovering {
                                    isSpaceHeaderHovered = true
                                }
                            }
                        }
                    }
                    .fixedSize() // Prevent compression of the right side elements
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSpaceHeaderHovered)
                }
                .padding(.vertical, 8)
                .onHover { hovering in
                    isSpaceHeaderHovered = hovering
                }
            }
            
            NewTabButton {
                viewModel.createNewTab()
            }
            
            // Pinned Tabs Section (if any exist)
            if !pinnedTabs.isEmpty {
                VStack(spacing: 4) {
                    // Optional: Pinned tabs header
                    HStack {
                        Text("Pinned")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    
                    // Pinned tabs list
                    ForEach(pinnedTabs) { tab in
                        PinnedTabRow(
                            viewModel: viewModel,
                            tab: tab,
                            isSelected: tab.id == viewModel.currentTab?.id && !viewModel.isInBoardMode,
                            isHovered: hoveredTab == tab.id,
                            onSelect: { viewModel.selectTab(tab) },
                            onHover: { isHovering in
                                hoveredTab = isHovering ? tab.id : nil
                            }
                        )
                    }
                }
                
                // Divider between pinned and regular tabs
                Divider()
                    .padding(.horizontal, 12)
            }
            
            // Regular Tabs Section
            ForEach(regularTabs) { tab in
                TabRow(
                    viewModel: viewModel,
                    previewManager: previewManager,
                    tab: tab,
                    isSelected: tab.id == viewModel.currentTab?.id && !viewModel.isInBoardMode,
                    isHovered: hoveredTab == tab.id,
                    onSelect: { viewModel.selectTab(tab) },
                    onClose: { viewModel.closeAndDeleteTab(tab) },
                    onHover: { isHovering in
                        hoveredTab = isHovering ? tab.id : nil
                    }
                )
            }
            
            Spacer(minLength: 0) // Ensures consistent layout
        }
    }
    
    private var slideTransition: AnyTransition {
        switch slideDirection {
        case .left:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .right:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .none:
            return .opacity
        }
    }
    
    private func updateSlideDirection() {
        // Determine slide direction based on space ordering
        guard let currentSpace = viewModel.currentSpace else {
            slideDirection = .none
            return
        }
        
        let spaces = viewModel.spaces // Non-optional array of spaces
        
        guard let currentIndex = spaces.firstIndex(where: { $0.id == currentSpace.id }) else {
            slideDirection = .none
            return
        }
        
        if currentIndex > previousSpaceIndex {
            slideDirection = .right
        } else if currentIndex < previousSpaceIndex {
            slideDirection = .left
        } else {
            slideDirection = .none
        }
        
        previousSpaceIndex = currentIndex
    }
    
    private var currentSpaceColor: Color {
        guard let space = viewModel.currentSpace else { return .blue }
        return Color.spaceColor(space.color)
    }
}
