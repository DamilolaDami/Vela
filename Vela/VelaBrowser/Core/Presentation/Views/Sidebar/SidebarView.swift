import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @ObservedObject var boardVM: NoteBoardViewModel
    @State private var hoveredTab: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with space selector
            SidebarHeader(viewModel: viewModel)
            
            ScrollView {
                VStack(spacing: 24) {
                    QuickAccessGrid(viewModel: viewModel)
                    NoteBoardSection(boardVM: boardVM, viewModel: viewModel, onBoardSelected: {
                        viewModel.currentSpace = nil
                    })
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
