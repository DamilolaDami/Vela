//
//  BrowserView 2.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI


struct BrowserView: View {
    @StateObject private var viewModel: BrowserViewModel
    @StateObject private var previewManager = TabPreviewManager()
    init(viewModel: BrowserViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
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
                    // Toolbar
                    BrowserToolbar(viewModel: viewModel)
                    
                    // Web Content
                    if viewModel.currentTab != nil {
                        WebViewContainer(viewModel: viewModel)
                    } else {
                        StartPageView(viewModel: viewModel)
                    }
                }
                .toolbar(removing: .sidebarToggle)
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
