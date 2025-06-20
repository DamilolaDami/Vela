//
//  BrowserView.swift
//  Vela
//
//  Created by Damilola on 5/30/25.
//

import SwiftUI

struct BrowserView: View {
    @StateObject private var viewModel: BrowserViewModel
    @StateObject private var bookMarkViewModel: BookmarkViewModel
    @StateObject private var previewManager = TabPreviewManager()
    @StateObject private var suggestionViewModel: AddressBarViewModel
    @StateObject private var velaPilotViewModel: VelaPilotViewModel
    @StateObject private var noteBoardVM: NoteBoardViewModel
    @State var shchemaDetector: SchemaDetectionService
    @StateObject var manager = DefaultBrowserManager()
    @EnvironmentObject private var quitManager: QuitManager
    
    init(viewModel: BrowserViewModel, bookMarkViewModel: BookmarkViewModel, suggestionViewModel: AddressBarViewModel, velaPilotViewModel: VelaPilotViewModel, noteBoardVM: NoteBoardViewModel, shchemaDetector: SchemaDetectionService) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._bookMarkViewModel = StateObject(wrappedValue: bookMarkViewModel)
        self._suggestionViewModel = StateObject(wrappedValue: suggestionViewModel)
        self._velaPilotViewModel = StateObject(wrappedValue: velaPilotViewModel)
        self._noteBoardVM = StateObject(wrappedValue: noteBoardVM)
        self._shchemaDetector = State(wrappedValue: shchemaDetector)
    }
    
    var body: some View {
        ConfigurableSplitView(
            columnVisibility: $viewModel.columnVisibility,
            sidebarWidth: 245,
            minSidebarWidth: 245,
            maxSidebarWidth: 245
        ) {
            // Sidebar
            SidebarView(viewModel: viewModel, previewManager: previewManager, boardVM: viewModel.noteboardVM, bookMarkViewModel: bookMarkViewModel, suggestionViewModel: suggestionViewModel)
        } detail: {
            VStack(spacing: 0) {
                if !viewModel.isInBoardMode {
                    // Browser mode - show toolbar and web content
                    if let currentTab = viewModel.currentTab {
                       if currentTab.webView != nil {
                            // Active tab with web view
                            WebViewContainer(
                                viewModel: viewModel,
                                noteBoardViewModel: noteBoardVM, suggestionViewModel: suggestionViewModel
                            )
                        } else {
                           
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
            .allowsHitTesting(!viewModel.addressBarVM.isShowingEnterAddressPopup)
            .overlay(alignment: .top, content: {
                if let currentTab = viewModel.currentTab, !currentTab.hasLoadFailed {
                    if currentTab.isLoading, !viewModel.isInBoardMode {
                        VelaProgressIndicator(progress: viewModel.estimatedProgress)
                    }
                }
            })
            .toolbar(removing: .title)
            .toolbarBackground(.hidden, for: .windowToolbar)
            .frame(maxHeight: .infinity)
            .ignoresSafeArea()
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            .padding(5)
        }
//        .overlay(alignment: .bottomTrailing, content: {
//            SchemeInfoPopup(detector: shchemaDetector, color: viewModel.currentSpace?.displayColor ?? .blue)
//                .padding(7)
//                .frame(maxWidth: 300)
//        })
        .animation(.easeInOut(duration: 0.3), value: viewModel.estimatedProgress)
        .browserKeyboardShortcuts(viewModel: viewModel)
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
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: (viewModel.currentSpace?.displayColor ?? .blue).opacity(0.45), location: 0.0),
                    Gradient.Stop(color: (viewModel.currentSpace?.displayColor ?? .blue).opacity(0.35), location: 0.1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottomTrailing) {
            DefaultBrowserPromptView(manager: manager)
                .padding()
        }
        .overlay(alignment: .topLeading) {
            if suggestionViewModel.isShowingEnterAddressPopup {
                AddressEntryPopup(
                    isPresented: $suggestionViewModel.isShowingEnterAddressPopup,
                    addressText: $viewModel.addressText,
                    onURLSubmit: { urlString in
                        Task(priority: .high) {
                            viewModel.navigateToURL(urlString)
                        }
                    },
                    suggestionVM: suggestionViewModel
                )
                .padding()
                .padding(.top, 40)
            }
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    suggestionViewModel.isShowingSuggestions = false
                    viewModel.addressBarVM.isShowingEnterAddressPopup = false
                }
        )
    }
    
    private var canGoBack: Bool {
        viewModel.currentTab?.canGoBack ?? false
    }
    
    private var canGoForward: Bool {
        viewModel.currentTab?.canGoForward ?? false
    }
    
    private var isBookmarked: Bool {
        guard let url = viewModel.currentTab?.url else { return false }
        return bookMarkViewModel.bookmarks.contains { bookmark in
            bookmark.url?.absoluteString == url.absoluteString
        }
    }
    
    private var hasURL: Bool {
        viewModel.currentTab?.url != nil
    }
    
    // MARK: - Actions
    
    func goBack() {
        print("Attempting to go back. Can go back: \(viewModel.currentTab?.webView?.canGoBack ?? false)")
        viewModel.currentTab?.webView?.goBack()
    }
    
    func goForward() {
        print("Attempting to go forward. Can go forward: \(viewModel.currentTab?.webView?.canGoForward ?? false)")
        viewModel.currentTab?.webView?.goForward()
    }
    
    private func refresh() {
        if viewModel.isLoading {
            viewModel.stopLoading()
        } else {
            viewModel.reload()
        }
    }
}
