import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var hoveredTab: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with space selector
            SidebarHeader(viewModel: viewModel)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Access Grid
                    QuickAccessGrid(viewModel: viewModel)
                    
                    
                    SpaceInfoSection(viewModel: viewModel)
                    
                    // Tabs Section (without space divider)
                    TabsSection(
                        viewModel: viewModel,
                        hoveredTab: $hoveredTab
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            // Bottom Actions
            BottomActions(viewModel: viewModel)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $viewModel.isShowingCreateSpaceSheet, content: {
            SpaceCreationSheet(viewModel: viewModel)
        })
        .overlay(
            // Subtle border
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(width: 0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
        )
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

// MARK: - Tabs Section (simplified without space divider)
struct TabsSection: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Binding var hoveredTab: UUID?
    
    var body: some View {
        VStack(spacing: 8) {
            // New Tab Button
            NewTabButton {
                viewModel.createNewTab()
            }
            
            // Tab List
            ForEach(viewModel.tabs) { tab in
                TabRow(
                    viewModel: viewModel,
                    tab: tab,
                    isSelected: tab.id == viewModel.currentTab?.id,
                    isHovered: hoveredTab == tab.id,
                    onSelect: { viewModel.selectTab(tab) },
                    onClose: { viewModel.closeTab(tab) },
                    onHover: { isHovering in
                      hoveredTab = isHovering ? tab.id : nil
                    }
                )
            }
        }
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

