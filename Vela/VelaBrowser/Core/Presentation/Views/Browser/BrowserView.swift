//
//  BrowserView 2.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI


struct BrowserView: View {
    @StateObject private var viewModel: BrowserViewModel
    
    init(viewModel: BrowserViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator at the top - always visible when loading
            
            
            HSplitView {
                // Sidebar
                if !viewModel.sidebarCollapsed {
                    SidebarView(viewModel: viewModel)
                        .frame(minWidth: 280, maxWidth: 320)
                }
                
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
            }
           
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: viewModel.toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
            
            // Alternative: Circular progress in toolbar
            ToolbarItem(placement: .status) {
                if viewModel.estimatedProgress > 0 && viewModel.estimatedProgress < 1 {
                    VelaProgressIndicator(progress: viewModel.estimatedProgress)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.estimatedProgress)
        .browserKeyboardShortcuts(viewModel: viewModel)
        .focusable()
    }
}
