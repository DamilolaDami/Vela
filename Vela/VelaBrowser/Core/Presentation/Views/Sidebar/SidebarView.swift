import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @ObservedObject var boardVM: NoteBoardViewModel
    @ObservedObject var bookMarkViewModel: BookmarkViewModel
    @ObservedObject var suggestionViewModel: AddressBarViewModel
    
    @State private var hoveredTab: UUID?
    @State private var draggedTab: Tab? = nil
    @State private var isDragging: Bool = false
    
    var body: some View {
        Group {
            VStack(spacing: 0) {
                SidebarHeader(viewModel: viewModel, bookmarkViewModel: bookMarkViewModel)
                
                ScrollView {
                    VStack(spacing: 4) {
                        BrowserToolbar(
                            viewModel: viewModel,
                            bookmarkViewModel: bookMarkViewModel,
                            suggestionVM: suggestionViewModel
                        )
                        QuickAccessGrid(viewModel: viewModel)
//                        NoteBoardSection(
//                            boardVM: boardVM,
//                            viewModel: viewModel,
//                            onBoardModeSelected: {
//                                viewModel.currentSpace = nil
//                            }
//                        )
                        FolderSection(
                            viewModel: viewModel,
                            previewManager: previewManager,
                            hoveredTab: $hoveredTab,
                            draggedTab: $draggedTab,
                            isDragging: $isDragging
                        )
                        TabsSection(
                            viewModel: viewModel,
                            previewManager: previewManager,
                            hoveredTab: $hoveredTab,
                            draggedTab: $draggedTab,
                            isDragging: $isDragging
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                }
                
                BottomActions(viewModel: viewModel)
            }
            
            .sheet(isPresented: $viewModel.isShowingCreateSpaceSheet) {
                SpaceCreationSheet(viewModel: viewModel)
            }
        }
    }
    
    private var currentSpaceColor: Color {
        guard let space = viewModel.currentSpace else { return Color.blue }
        return space.displayColor
    }
}
