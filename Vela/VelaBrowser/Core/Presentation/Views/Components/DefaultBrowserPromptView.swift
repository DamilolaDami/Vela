//
//  DefaultBrowserPromptView.swift
//  Vela
//
//  Created by damilola on 6/17/25.
//

import SwiftUI

// MARK: - Main Container View
struct DefaultBrowserPromptView: View {
    @ObservedObject var manager: DefaultBrowserManager
    @State private var isDismissed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if manager.showPrompt && !isDismissed {
            PromptCard(
                onDismiss: { dismissPrompt() },
                onSetDefault: { handleSetDefault() },
                colorScheme: colorScheme
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .bottom))
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isDismissed)
        }
    }
    
    private func dismissPrompt() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isDismissed = true
            manager.showPrompt = false
        }
    }
    
    private func handleSetDefault() {
        manager.setAsDefault()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            manager.checkIfDefault()
        }
        dismissPrompt()
    }
}

// MARK: - Prompt Card Container
struct PromptCard: View {
    let onDismiss: () -> Void
    let onSetDefault: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            PromptHeader(onDismiss: onDismiss, colorScheme: colorScheme)
            PromptContent(
                onSetDefault: onSetDefault,
                onDismiss: onDismiss,
                colorScheme: colorScheme
            )
        }
        .frame(width: 280)
        .background(
            CardBackground(colorScheme: colorScheme)
        )
    }
}

// MARK: - Header with Close Button
struct PromptHeader: View {
    let onDismiss: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Spacer()
            CloseButton(action: onDismiss, colorScheme: colorScheme)
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
    }
}

// MARK: - Close Button Component
struct CloseButton: View {
    let action: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Content Area
struct PromptContent: View {
    let onSetDefault: () -> Void
    let onDismiss: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            AppIconView()
            PromptText(colorScheme: colorScheme)
            ActionButtons(
                onSetDefault: onSetDefault,
                onDismiss: onDismiss,
                colorScheme: colorScheme
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - App Icon with Gradient
struct AppIconView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
            
            Image(systemName: "globe")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Text Content
struct PromptText: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Make Vela your default browser")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)
            
            Text("Open links from other apps directly in Vela for a seamless browsing experience")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .lineSpacing(2)
        }
    }
}

// MARK: - Action Buttons Container
struct ActionButtons: View {
    let onSetDefault: () -> Void
    let onDismiss: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            PrimaryButton(action: onSetDefault)
            SecondaryButton(action: onDismiss, colorScheme: colorScheme)
        }
    }
}

// MARK: - Primary Action Button
struct PrimaryButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("Set as Default Browser")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: Color.blue.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Action Button
struct SecondaryButton: View {
    let action: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: action) {
            Text("Maybe Later")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? .white.opacity(0.06) : .black.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.08),
                                    lineWidth: 0.5
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card Background Style
struct CardBackground: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color.black : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.black.opacity(0.06),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.4)
                    : Color.black.opacity(0.12),
                radius: 20,
                x: 0,
                y: 8
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.2)
                    : Color.black.opacity(0.04),
                radius: 1,
                x: 0,
                y: 1
            )
    }
}

