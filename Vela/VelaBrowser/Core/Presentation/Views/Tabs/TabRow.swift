import SwiftUI

// MARK: - Tab Row
struct TabRow: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    let tab: Tab
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onHover: (Bool) -> Void
    @State var isMuted: Bool = false
    @State private var isMuteButtonHovered: Bool = false
    @Environment(\.colorScheme) var scheme
    
    // Pre-computed colors for better performance
    private var titleColor: Color {
        isSelected ? .black : .secondary
    }
    
    private var titleFont: Font {
        .system(size: 13, weight: isSelected ? .medium : .regular)
    }
    
    private var backgroundFill: some ShapeStyle {
        isSelected ?
            AnyShapeStyle(Color.white) :
            AnyShapeStyle(Color(NSColor.quaternaryLabelColor).opacity(isHovered ? 1.0 : 0))
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Favicon with optimized caching
            TabIcon(tab: tab)
                .id(tab.id) // Use tab.id instead of favicon hashValue for stability
            
            // Optimized title section
            titleSection
            
            Spacer(minLength: 8)
            
            // Audio controls - only render when needed
            if tab.isPlayingAudio {
                audioControlButton
            }
            
            // Close button - conditional rendering
            if isHovered || isSelected {
                closeButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tabBackground)
        .contentShape(RoundedRectangle(cornerRadius: 15))
        .contextMenu { TabContextMenu(tab: tab, viewModel: viewModel) }
        .onTapGesture(perform: onSelect)
        .onHover(perform: handleHover)
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var titleSection: some View {
        Text(tab.title)
            .font(titleFont)
            .foregroundColor(titleColor)
            .lineLimit(1)
            .truncationMode(.tail)
    }
    
    @ViewBuilder
    private var audioControlButton: some View {
        Button(action: toggleMute) {
            ZStack {
                // Simplified background
                Circle()
                    .fill(isMuted ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                    .frame(width: 20, height: 20)
                    .scaleEffect(isMuteButtonHovered ? 1.1 : 1.0)
                
                // Icon
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(isMuted ? .red : .blue)
                    .scaleEffect(isMuteButtonHovered ? 1.05 : 1.0)
                
                // Pulse effect - only when not muted
                if !isMuted {
                    pulseEffect
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .help(isMuted ? "Unmute tab" : "Mute tab")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isMuteButtonHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMuted)
        .animation(.easeInOut(duration: 0.15), value: isMuteButtonHovered)
    }
    
    @ViewBuilder
    private var pulseEffect: some View {
        Circle()
            .stroke(Color.blue.opacity(0.4), lineWidth: 1)
            .frame(width: 20, height: 20)
            .opacity(0)
            .scaleEffect(1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    // Pulse animation will be handled by the animation system
                }
            }
    }
    
    @ViewBuilder
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(
                            isSelected ?
                                Color(NSColor.controlBackgroundColor).opacity(0.5) :
                                Color(NSColor.tertiaryLabelColor).opacity(0.3)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.scale.combined(with: .opacity))
    }
    
    @ViewBuilder
    private var tabBackground: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(backgroundFill)
            .shadow(
                color: isSelected ? Color.black.opacity(0.1) : Color.clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ? Color.gray.opacity(0.2) : Color.clear,
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Helper Methods
    private func handleHover(_ hovering: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            onHover(hovering)
        }
    }
    
    // MARK: - Mute/Unmute Functionality (Optimized)
    private func toggleMute() {
        guard let webView = tab.webView else { return }
        
        // Optimized JavaScript - reduced string interpolation
        let muteJS = """
        (function() {
            const media = [...document.querySelectorAll('audio, video')];
            if (media.length === 0) return false;
            
            const wasMuted = media[0].muted;
            const newState = !wasMuted;
            
            media.forEach(el => el.muted = newState);
            return newState;
        })();
        """
        
        webView.evaluateJavaScript(muteJS) { result, error in
            if let error = error {
                print("Mute toggle error: \(error.localizedDescription)")
            } else if let newMuteState = result as? Bool {
                DispatchQueue.main.async {
                    isMuted = newMuteState
                }
            }
        }
    }
}

// MARK: - Optimized Tab Icon
struct TabIcon: View {
    let tab: Tab
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(NSColor.quaternaryLabelColor))
                .frame(width: 20, height: 20)
            
            iconContent
        }
    }
    
    @ViewBuilder
    private var iconContent: some View {
        if let faviconData = tab.favicon,
           let nsImage = NSImage(data: faviconData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: Color.black.opacity(0.1), radius: 0.5, x: 0, y: 0.5)
        } else {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 16, height: 16)
        }
    }
}

// MARK: - Optimized Tab Context Menu
struct TabContextMenu: View {
    let tab: Tab
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        Group {
            basicActions
            Divider()
            tabActions
            Divider()
            folderActions
            Divider()
            closeActions
        }
    }
    
    @ViewBuilder
    private var basicActions: some View {
        Button("Reload Tab") { viewModel.reloadTab(tab) }
        Button("Duplicate Tab") { viewModel.duplicateTab(tab) }
    }
    
    @ViewBuilder
    private var tabActions: some View {
        Button(tab.isPinned ? "Unpin Tab" : "Pin Tab") { viewModel.pinTab(tab) }
        Button("Mute Tab") { viewModel.muteTab(tab) }
    }
    
    @ViewBuilder
    private var folderActions: some View {
        Menu("Move to Folder") {
            ForEach(sortedFolders, id: \.id) { folder in
                Button(folder.name) {
                    viewModel.addTab(tab, to: folder)
                }
            }
            
            Divider()
            
            Button("New Folder") {
                createNewFolder()
            }
        }
    }
    
    @ViewBuilder
    private var closeActions: some View {
        Button("Close Tab") { closeCurrentTab() }
        Button("Close Other Tabs") { viewModel.closeOtherTabs(except: tab) }
        Button("Close Tabs Below This Tab") { viewModel.closeTabsToRight(of: tab) }
    }
    
    // MARK: - Helper computed properties and methods
    private var sortedFolders: [Folder] {
        viewModel.folders.sorted { $0.position < $1.position }
    }
    
    private func createNewFolder() {
        guard let spaceId = viewModel.currentSpace?.id else { return }
        let newFolder = Folder(name: "New Folder", spaceId: spaceId, position: viewModel.folders.count)
        viewModel.createFolder(name: newFolder.name)
        viewModel.addTab(tab, to: newFolder)
    }
    
    private func closeCurrentTab() {
        if let folderId = tab.folderId,
           let folder = viewModel.folders.first(where: { $0.id == folderId }) {
            viewModel.removeTab(tab, from: folder)
            NotificationService.shared.show(type: .success, title: "Tab removed from folder")
        } else {
            viewModel.closeTab(tab)
        }
    }
}
