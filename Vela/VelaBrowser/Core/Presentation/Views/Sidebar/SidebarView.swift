import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @ObservedObject var boardVM: NoteBoardViewModel
    @ObservedObject var bookMarkViewModel: BookmarkViewModel
    @ObservedObject var suggestionViewModel: AddressBarViewModel
    
    @State private var hoveredTab: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with space selector
            SidebarHeader(viewModel: viewModel, bookmarkViewModel: bookMarkViewModel)
            
            ScrollView (showsIndicators: false){
                VStack(spacing: 10) {
                    BrowserToolbar(
                        viewModel: viewModel,
                        bookmarkViewModel: bookMarkViewModel,
                        suggestionVM: suggestionViewModel
                    )
                    QuickAccessGrid(viewModel: viewModel)
                    NoteBoardSection(boardVM: boardVM, viewModel: viewModel, onBoardSelected: {
                        viewModel.currentSpace = nil
                    })
                    FolderSection(
                                           viewModel: viewModel,
                                           previewManager: previewManager,
                                           hoveredTab: $hoveredTab
                                       )
                    TabsSection(
                        viewModel: viewModel, previewManager: previewManager,
                        hoveredTab: $hoveredTab
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
    
    private var currentSpaceColor: Color {
        guard let space = viewModel.currentSpace else { return .blue }
        return space.displayColor
    }
}
