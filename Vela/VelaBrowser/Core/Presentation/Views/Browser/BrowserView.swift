//
//  BrowserView 2.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

struct BrowserView: View {
    @StateObject private var viewModel: BrowserViewModel
    @StateObject private var bookMarkViewModel: BookmarkViewModel
    @StateObject private var previewManager = TabPreviewManager()
    @StateObject private var suggestionViewModel: SuggestionViewModel
    @StateObject private var velaPilotViewModel: VelaPilotViewModel
    @StateObject private var noteBoardVM: NoteBoardViewModel
    @StateObject var manager = DefaultBrowserManager()
    @EnvironmentObject private var quitManager: QuitManager
    init(viewModel: BrowserViewModel, bookMarkViewModel: BookmarkViewModel, suggestionViewModel: SuggestionViewModel, velaPilotViewModel: VelaPilotViewModel, noteBoardVM: NoteBoardViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._bookMarkViewModel = StateObject(wrappedValue: bookMarkViewModel)
        self._suggestionViewModel = StateObject(wrappedValue: suggestionViewModel)
        self._velaPilotViewModel = StateObject(wrappedValue: velaPilotViewModel)
        self._noteBoardVM = StateObject(wrappedValue: noteBoardVM)
    }
    
    var body: some View {
        ZStack{
            VStack(spacing: 0) {
                NavigationSplitView(columnVisibility: $viewModel.columnVisibility) {
                    // Sidebar
                    SidebarView(viewModel: viewModel, previewManager: previewManager, boardVM: viewModel.noteboardVM)
                        .frame(minWidth: 245, maxWidth: 320)
                        .navigationSplitViewColumnWidth(245)
                } detail: {
                    // Main Content
                    VStack(spacing: 0) {
                        if !viewModel.isInBoardMode {
                            // Browser mode - show toolbar and web content
                            BrowserToolbar(
                                viewModel: viewModel,
                                bookmarkViewModel: bookMarkViewModel,
                                suggestionVM: suggestionViewModel
                            )
                            
                            if viewModel.currentTab != nil {
                                if viewModel.currentTab?.webView != nil {
                                    // Active tab with web view
                                    WebViewContainer(
                                        viewModel: viewModel,
                                        noteBoardViewModel: noteBoardVM, suggestionViewModel: suggestionViewModel
                                    )
                                }
                            } else {
                                // No active tab - show start page
                                StartPageView(viewModel: viewModel)
                            }
                        } else {
                            // Board mode - show note board
                            BoardView(boardVM: viewModel.noteboardVM)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .top, content: {
                        if let currentTab = viewModel.currentTab {
                            if currentTab.isLoading && !viewModel.isInBoardMode{
                                
                                VelaProgressIndicator(progress: viewModel.estimatedProgress)
                            }
                        }
                    })
                    // Background overlay for dismissing suggestions
                    .background {
                        if suggestionViewModel.isShowingSuggestions && !suggestionViewModel.suggestions.isEmpty && !viewModel.isInBoardMode {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    suggestionViewModel.isShowingSuggestions = false
                                }
                        }
                    }
                    .overlay(alignment: .top) {
                        if suggestionViewModel.isShowingSuggestions && !suggestionViewModel.suggestions.isEmpty && !viewModel.isInBoardMode {
                            SuggestionsListView(
                                suggestionViewModel: suggestionViewModel,
                                onSuggestionSelected: { selectedURL in
                                    viewModel.addressText = selectedURL
                                    viewModel.navigateToURL()
                                },
                                onEditingChanged: { isEditing in
                                    viewModel.isEditing = isEditing
                                }
                            )
                            .frame(maxWidth: 530)
                            .padding(.top, 4)
                            // .transition(.opacity.combined(with: .move(edge: .top)))
                            .offset(y: 48)
                        }
                    }

                }
            }
            
            .animation(.easeInOut(duration: 0.3), value: viewModel.estimatedProgress)
            .browserKeyboardShortcuts(viewModel: viewModel)
            .focusable()
           
            .overlay(
                TabPreviewOverlay(previewManager: previewManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            .sheet(isPresented: $viewModel.showCommandPalette) {
                VelaPilotView(viewModel: velaPilotViewModel, browserViewModel: viewModel)
                    .onKeyPress(.escape) {
                        viewModel.showCommandPalette = false
                        return .handled
                    }
            }
            .sheet(isPresented: $quitManager.showingQuitDialog) {
                QuitDialog()
            }
            .overlay(alignment: .bottomTrailing) {
                DefaultBrowserPromptView(manager: manager)
                    .padding()
                  
            }
            
           
        }
        
    }
   
}
