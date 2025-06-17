//
//  SettingsView.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovered in
                    // Add subtle hover effect
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
                .opacity(0.3)
            
            // Settings Content
            ScrollView {
                LazyVStack(spacing: 1) {
                    // Quick Actions Section
                        HStack(spacing: 8) {
                            MiniActionButton(
                                icon: "viewfinder",
                                spaceColor: viewModel.spaceColor
                            ) {
                              //  viewModel.captureSelectedArea()
                            }
                            Spacer()
                            
                            MiniActionButton(
                                icon: "camera",
                                spaceColor: viewModel.spaceColor
                            ) {
                             //   viewModel.captureFullPage()
                            }
                            Spacer()
                            
                            MiniActionButton(
                                icon: "doc.text",
                                spaceColor: viewModel.spaceColor
                            ) {
                              //  viewModel.toggleReaderMode()
                            }
                            Spacer()
                            
                            MiniActionButton(
                                icon: "arrow.clockwise",
                                spaceColor: viewModel.spaceColor
                            ) {
                              //  viewModel.hardRefresh()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    
                    
                    SiteHeaderOption(siteName: viewModel.currentTab?.url?.urlBase ?? "Unknown Site")
                    
                    // Privacy & Security Section
                    SettingsSection(title: "Privacy & Security") {
                        SettingsRow(
                            icon: "shield.fill",
                            title: "Block Ads and Trackers",
                            subtitle: "Enhanced privacy protection",
                            spaceColor: viewModel.spaceColor,
                            isOn: $viewModel.isAdBlockingEnabled
                        ) { newValue in
                            viewModel.updateAdBlocking(enabled: newValue)
                        }
                        
                        SettingsRow(
                            icon: "eye.slash.fill",
                            title: "Incognito Mode",
                            subtitle: "Browse without saving history",
                            spaceColor: viewModel.spaceColor,
                            isOn: $viewModel.isIncognitoMode
                        ) { newValue in
                            viewModel.updateIncognitoMode(enabled: newValue)
                        }
                        
                        SettingsRow(
                            icon: "rectangle.on.rectangle.slash",
                            title: "Block Pop-ups",
                            subtitle: "Prevent unwanted pop-ups",
                            spaceColor: viewModel.spaceColor,
                            isOn: $viewModel.isPopupBlockingEnabled
                        ) { newValue in
                            viewModel.updatePopupBlocking(enabled: newValue)
                        }
                    }
                    
                    // Developer Section
                    SettingsSection(title: "Developer") {
                        SettingsRow(
                            icon: "curlybraces",
                            title: "JavaScript",
                            subtitle: "Enable dynamic content",
                            spaceColor: viewModel.spaceColor,
                            isOn: $viewModel.isJavaScriptEnabled
                        ) { newValue in
                            viewModel.updateJavaScript(enabled: newValue)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 320, height: 415)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
        )
    }
}

struct SiteHeaderOption: View {
    var siteName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SITE SETTINGS")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(siteName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
    }
}
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.3)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 4)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let spaceColor: Color?
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(spaceColor ?? .blue)
                .frame(width: 20, height: 20)
                .background((spaceColor ?? .blue).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: spaceColor ?? .blue ))
                .scaleEffect(0.8)
                .onChange(of: isOn) { _, newValue in
                    onChange(newValue)
                }
             
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.black.opacity(0.03) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
    }
}

struct MiniActionButton: View {
    let icon: String
    let spaceColor: Color?
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isPressed ? Color.black.opacity(0.15) :
                            isHovered ? Color.black.opacity(0.08) :
                            Color.black.opacity(0.05)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

