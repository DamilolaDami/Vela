import SwiftUI
// MARK: - Updated SidebarHeader
//
//  SidebarHeader.swift
//  Vela
//
//   sidebar header  design
//

import SwiftUI

// MARK: - Main SidebarHeader View
struct SidebarHeader: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var bookmarkViewModel: BookmarkViewModel
    @State private var showDownloads = false
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main header content
            VStack(spacing: 12) {
         
                // Bottom row - Action buttons
                ActionButtonsRow(
                    viewModel: viewModel,
                    bookmarkViewModel: bookmarkViewModel,
                    showDownloads: $showDownloads,
                    showSettings: $showSettings
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Enhanced separator
            SeparatorView()
        }
        //.background(.regularMaterial)
    }
}


// MARK: - Keyboard Shortcut Hint Sub-View
struct KeyboardShortcutHint: View {
    let shortcut: String
    
    var body: some View {
        Text(shortcut)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(Color(NSColor.quaternarySystemFill))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.1))
            )
    }
}

// MARK: - Action Buttons Row Sub-View
struct ActionButtonsRow: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var bookmarkViewModel: BookmarkViewModel
    @Binding var showDownloads: Bool
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            
            ActionButton(
                icon: "sidebar.left",
                tooltip: "Close sidebar"            ) {
                viewModel.toggleSidebar()
            }

            Spacer()
            HStack {
                ActionButton(
                    icon: "arrow.left",
                    tooltip: "Go back",
                    isDisabled: !canGoBack
                ) {
                    goBack()
                }
              //  .disabled(!canGoBack)
            }
            ActionButton(
                icon: "arrow.right",
                tooltip: "Go Forward",
                isDisabled: !canGoForward
            ) {
                goForward()
            }
            ActionButton(
                icon: viewModel.isLoading ? "xmark" : "arrow.clockwise",
                tooltip: "Reload this tab"
            ) {
                refresh()
            }
           
        }
           
            
    }
    
    private var canGoBack: Bool {
        viewModel.currentTab?.canGoBack ?? false
    }
   
    
    private var canGoForward: Bool {
        viewModel.currentTab?.canGoForward ?? false
    }
    
    private var isBookmarked: Bool {
        guard let url = viewModel.currentTab?.url else { return false }
        return bookmarkViewModel.bookmarks.contains { bookmark in
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

// MARK: - Incognito Toggle Button Sub-View
struct IncognitoToggleButton: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        ActionButton(
            icon: viewModel.isIncognitoMode ? "eye.slash.fill" : "eye.fill",
            isActive: viewModel.isIncognitoMode,
            activeColor: .orange,
            tooltip: viewModel.isIncognitoMode ? "Exit Incognito" : "Enter Incognito"
        ) {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isIncognitoMode.toggle()
                viewModel.updateIncognitoMode(enabled: viewModel.isIncognitoMode)
            }
        }
    }
}

// MARK: - Downloads Button Sub-View
struct DownloadsButton: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Binding var showDownloads: Bool
    
    var body: some View {
        ActionButton(
            icon: "arrow.down.circle.fill",
            badge: 0,
            tooltip: "Downloads"
        ) {
            showDownloads.toggle()
        }
        .popover(isPresented: $showDownloads, arrowEdge: .bottom) {
            DownloadsView(viewModel: viewModel)
        }
    }
}

// MARK: - Settings Button Sub-View
struct SettingsButton: View {
    @Binding var showSettings: Bool
    var viewModel: BrowserViewModel
    
    var body: some View {
        ActionButton(
            icon: "gearshape.fill",
            tooltip: "Settings"
        ) {
            showSettings.toggle()
        }
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            SettingsView(viewModel: viewModel)
        }
    }
}


// MARK: - Separator Sub-View
struct SeparatorView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color(NSColor.separatorColor).opacity(0.3),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 0.5)
        .padding(.horizontal, 8)
    }
}

// MARK: - Background Gradient Sub-View
struct BackgroundGradientView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(NSColor.controlBackgroundColor),
                Color(NSColor.controlBackgroundColor).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}




