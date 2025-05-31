import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @State private var hoveredTab: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with space selector
            SidebarHeader(viewModel: viewModel)
            
            ScrollView {
                VStack(spacing: 24) {
                    QuickAccessGrid(viewModel: viewModel)
                    SpaceInfoSection(viewModel: viewModel)
                    TabsSection(
                        viewModel: viewModel, previewManager: previewManager,
                        hoveredTab: $hoveredTab
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            BottomActions(viewModel: viewModel)
        }
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: currentSpaceColor.opacity(0.4), location: 0.0),
                    Gradient.Stop(color: currentSpaceColor.opacity(0.2), location: 0.3),
                    Gradient.Stop(color: currentSpaceColor.opacity(0.2), location: 0.7),
                    Gradient.Stop(color: currentSpaceColor.opacity(0.1), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            // Colored border instead of gray
            Rectangle()
                .fill(currentSpaceColor.opacity(0.15))
                .frame(width: 1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        )
        .sheet(isPresented: $viewModel.isShowingCreateSpaceSheet) {
            SpaceCreationSheet(viewModel: viewModel)
        }
    }
    
    private var currentSpaceColor: Color {
        guard let space = viewModel.currentSpace else { return .blue }
        return Color.spaceColor(space.color)
    }
}

// MARK: - Space Info Section (moved from SpaceDivider)
struct SpaceInfoSection: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentSpaceColor)
                        .frame(width: 8, height: 8)
                    
                    Text("\(viewModel.currentSpace?.name ?? "Personal Space")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(height: 0.5)
                Spacer()
                
                Text("\(viewModel.tabs.count) tabs")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
            }
            
          
        }
    }
    
    private var currentSpaceColor: Color {
        guard let space = viewModel.currentSpace else { return .blue }
        return Color.spaceColor(space.color)
    }
}

// MARK: - Tabs Section 
struct TabsSection: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @Binding var hoveredTab: UUID?
    
    // Computed properties to separate pinned and regular tabs
    private var pinnedTabs: [Tab] {
        viewModel.tabs.filter { $0.isPinned }
    }
    
    private var regularTabs: [Tab] {
        viewModel.tabs.filter { !$0.isPinned }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // New Tab Button
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
                            isSelected: tab.id == viewModel.currentTab?.id,
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
                    isSelected: tab.id == viewModel.currentTab?.id,
                    isHovered: hoveredTab == tab.id,
                    onSelect: { viewModel.selectTab(tab) },
                    onClose: { viewModel.closeAndDeleteTab(tab) },
                    onHover: { isHovering in
                        hoveredTab = isHovering ? tab.id : nil
                    }
                )
            }
        }
        .id(viewModel.currentSpace?.id)
    }
}
struct NewTabButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                
                Text("New Tab")
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isHovered ?
                        Color(NSColor.controlAccentColor).opacity(0.1) :
                        Color.clear
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

// MARK: - Supporting Extensions
extension BrowserViewModel {
    func openURL(_ urlString: String) {
        // Implementation to open URL in current or new tab
        guard let url = URL(string: urlString) else { return }
        
        if let currentTab = currentTab {
            currentTab.url = url
        } else {
            createNewTab()
            currentTab?.url = url
        }
    }
}

