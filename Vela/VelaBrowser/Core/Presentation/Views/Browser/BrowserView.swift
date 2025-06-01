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
    init(viewModel: BrowserViewModel, bookMarkViewModel: BookmarkViewModel, suggestionViewModel: SuggestionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._bookMarkViewModel = StateObject(wrappedValue: bookMarkViewModel)
        self._suggestionViewModel = StateObject(wrappedValue: suggestionViewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $viewModel.columnVisibility) {
                // Sidebar
                    SidebarView(viewModel: viewModel, previewManager: previewManager)
                        .frame(minWidth: 280, maxWidth: 320)
                        .navigationSplitViewColumnWidth(280)
            } detail: {
                // Main Content
                VStack(spacing: 0) {
                    BrowserToolbar(viewModel: viewModel, bookmarkViewModel: bookMarkViewModel, suggestionVM: suggestionViewModel)
                    if viewModel.currentTab != nil {
                        if (viewModel.currentTab?.webView != nil){
                            WebViewContainer(viewModel: viewModel)
                        }else{
                            Text("no WebView")
                        }
                    } else {
                        StartPageView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
              
                
//                .toolbar(content: {
//                    ToolbarItem(placement: .principal) {
//                        if let currentTab = viewModel.currentTab{
//                            if currentTab.isLoading {
//                                VelaProgressIndicator(progress: viewModel.estimatedProgress)
//                            }
//                        }
//                    }
//                })
                .overlay(alignment: .top) {
                    if suggestionViewModel.isShowingSuggestions && !suggestionViewModel.suggestions.isEmpty {
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
       
    }
   
}
