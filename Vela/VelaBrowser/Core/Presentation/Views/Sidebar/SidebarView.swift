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
        VStack(spacing: 0) {
            SidebarHeader(viewModel: viewModel, bookmarkViewModel: bookMarkViewModel)
            BrowserToolbar(
                viewModel: viewModel,
                bookmarkViewModel: bookMarkViewModel,
                suggestionVM: suggestionViewModel
            )
            //.padding(.bottom)
            .padding(.top, 3)
            .padding(.horizontal, 10)
            QuickAccessGrid(viewModel: viewModel)
                .padding(.bottom)
                .padding(.top, 6)
                .padding(.horizontal, 13)
            List {
                // Quick Access Section
               
                // Note Board Section (commented out)
//                Section {
//                    NoteBoardSection(
//                        boardVM: boardVM,
//                        viewModel: viewModel,
//                        onBoardModeSelected: {
//                            viewModel.currentSpace = nil
//                        }
//                    )
//                    .listRowInsets(EdgeInsets())
//                    .listRowSeparator(.hidden)
//                    .listRowBackground(Color.clear)
//                }
                
                // Folder Section
                Section {
                    FolderSection(
                        viewModel: viewModel,
                        previewManager: previewManager,
                        hoveredTab: $hoveredTab,
                        draggedTab: $draggedTab,
                        isDragging: $isDragging
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                }
                
                // Tabs Section
                Section {
                    TabsSection(
                        viewModel: viewModel,
                        previewManager: previewManager,
                        hoveredTab: $hoveredTab,
                        draggedTab: $draggedTab,
                        isDragging: $isDragging
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .padding(.horizontal, 10)
            .padding(.top, 5)
            
            BottomActions(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingCreateSpaceSheet) {
            SpaceCreationSheet(viewModel: viewModel)
        }
    }
    
    private var currentSpaceColor: Color {
        guard let space = viewModel.currentSpace else { return Color.blue }
        return space.displayColor
    }
}
