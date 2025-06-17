//
//  TabRow.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

// MARK: -  Tab Row

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
    
    var body: some View {
        HStack(spacing: 8) {
            // Favicon or default icon
            TabIcon(tab: tab)
            
            // Title with animation
            VStack(alignment: .leading, spacing: 1) {
                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.3), value: tab.title)
                    .transition(.opacity.combined(with: .slide))
                
                if let url = tab.url {
                    Text(url.host ?? "")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Enhanced Audio indicator and mute/unmute button
            if tab.isPlayingAudio {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        toggleMute()
                    }
                }) {
                    ZStack {
                        // Background circle with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isMuted ?
                                            Color.red.opacity(0.2) :
                                            Color.blue.opacity(0.2),
                                        isMuted ?
                                            Color.red.opacity(0.1) :
                                            Color.blue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 22, height: 22)
                            .scaleEffect(isMuteButtonHovered ? 1.1 : 1.0)
                            .shadow(
                                color: isMuted ?
                                    Color.red.opacity(0.3) :
                                    Color.blue.opacity(0.3),
                                radius: isMuteButtonHovered ? 4 : 2,
                                x: 0,
                                y: 1
                            )
                        
                        // Icon with enhanced styling
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isMuted ? Color.red : Color.blue,
                                        isMuted ? Color.red.opacity(0.8) : Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(isMuteButtonHovered ? 1.05 : 1.0)
                        
                        // Pulse animation for active audio
                        if !isMuted {
                            Circle()
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                .frame(width: 26, height: 26)
                                .scaleEffect(1.0)
                                .opacity(0.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: false),
                                    value: tab.isPlayingAudio
                                )
                                .onAppear {
                                    withAnimation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                    ) {
                                        // This creates the pulse effect
                                    }
                                }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .help(isMuted ? "Unmute tab" : "Mute tab")
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isMuteButtonHovered = hovering
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Close button (shown on hover or selection)
            if isHovered || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(Color(NSColor.separatorColor).opacity(0.3))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
      
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    isSelected ?
                    Color.white :
                    Color(NSColor.controlBackgroundColor).opacity(isHovered ? 1.0 : 0)
                )
                .shadow(
                    color: isSelected ? Color.black.opacity(0.1) : Color.clear,
                    radius: isSelected ? 4 : 0,
                    x: 0,
                    y: isSelected ? 2 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    isSelected ? Color.gray.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 15))
        .contextMenu {
            TabContextMenu(tab: tab, viewModel: viewModel)
        }
        .onTapGesture {
            onSelect()
        }
        // Simplified hover detection using onHover modifier
        .onHover { hovering in
           
            
            if hovering {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onHover(true)
                }
                
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onHover(false)
                }
                
            }
        }
    }
    
    // MARK: - Mute/Unmute Functionality
    private func toggleMute() {
        guard let webView = tab.webView else { return }
        
        let muteJS = """
        (function() {
            let audioElements = document.getElementsByTagName('audio');
            let videoElements = document.getElementsByTagName('video');
            let wasMuted = false;
            
            // Check current mute state from first audio/video element
            if (audioElements.length > 0) {
                wasMuted = audioElements[0].muted;
            } else if (videoElements.length > 0) {
                wasMuted = videoElements[0].muted;
            }
            
            // Toggle mute state for all audio elements
            for (let audio of audioElements) {
                audio.muted = !wasMuted;
            }
            
            // Toggle mute state for all video elements
            for (let video of videoElements) {
                video.muted = !wasMuted;
            }
            
            return !wasMuted; // Return new mute state
        })();
        """
        
        webView.evaluateJavaScript(muteJS) { (result, error) in
            if let error = error {
                print("Mute toggle error: \(error.localizedDescription)")
            } else if let newMuteState = result as? Bool {
                print("Tab \(tab.title) mute state changed to: \(newMuteState)")
                // Optionally update UI or trigger audio check
                isMuted = newMuteState
            }
        }
    }
}

struct TabIcon: View {
    let tab: Tab
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(NSColor.quaternaryLabelColor))
                .frame(width: 20, height: 20)
            
            Group {
                if let faviconData = tab.favicon,
                   let nsImage = NSImage(data: faviconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: Color(NSColor.shadowColor).opacity(0.2), radius: 1, x: 0, y: 0.5)
                        .onChange(of: tab.favicon) { _ in
                            print("Favicon updated for tab: \(tab.title)")
                        }
                } else {
                    // Just show a soft gray circle, no loading indicator
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
        }
    }
}


// MARK: - Tab Context Menu
struct TabContextMenu: View {
    let tab: Tab
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        Group {
            Button("Reload Tab") {
                viewModel.reloadTab(tab)
            }
            
            Button("Duplicate Tab") {
                viewModel.duplicateTab(tab)
            }
            
            Divider()
            
            Button(tab.isPinned ? "Unpin Tab" : "Pin Tab") {
                viewModel.pinTab(tab)
            }
            
            Button("Mute Tab") {
                viewModel.muteTab(tab)
            }
            
            Divider()
            
            Button("Close Tab") {
                viewModel.closeTab(tab)
            }
            
            Button("Close Other Tabs") {
                viewModel.closeOtherTabs(except: tab)
            }
            
            Button("Close Tabs below this tab") {
                viewModel.closeTabsToRight(of: tab)
            }
        }
    }
}
