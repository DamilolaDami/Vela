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
    @State private var showDownloads = false
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main header content
            VStack(spacing: 12) {
                // Top row - Search
                SearchBarView()
                
                // Bottom row - Action buttons
                ActionButtonsRow(
                    viewModel: viewModel,
                    showDownloads: $showDownloads,
                    showSettings: $showSettings
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Enhanced separator
            SeparatorView()
        }
        .background(.regularMaterial)
    }
}

// MARK: - Search Bar Sub-View
struct SearchBarView: View {
    @State private var searchHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Handle search action
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Search tabs, history...")
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.tertiarySystemFill))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    KeyboardShortcutHint(shortcut: "⌘K")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(searchHovered ? Color.black.opacity(0.03) : Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    searchHovered = hovering
                }
            }
        }
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
    @Binding var showDownloads: Bool
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            // Incognito mode toggle
            IncognitoToggleButton(viewModel: viewModel)
            
            Spacer()
            
            // Downloads button
            DownloadsButton(
                viewModel: viewModel,
                showDownloads: $showDownloads
            )
            
            // Settings button
            SettingsButton(showSettings: $showSettings, viewModel: viewModel)
            
           
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
            badge: viewModel.activeDownloadsCount,
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




