//
//  SpaceCreationSheet.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//


import SwiftUI

struct SpaceCreationSheet: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var spaceName = ""
    @State private var selectedColor: Space.SpaceColor = .blue
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Ultra-modern gradient background with animated particles
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Custom header with glassmorphism effect
                ModernHeader(dismiss: dismiss)
                
                // Main content with floating card design
                FloatingContentCard(
                    spaceName: $spaceName,
                    selectedColor: $selectedColor,
                    isAnimating: $isAnimating,
                    createAction: createSpace
                )
                .scaleEffect(scale)
                .opacity(opacity)
            }
        }
        .frame(width: 480, height: 520)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private func createSpace() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let newSpace = Space(name: spaceName, color: selectedColor)
            viewModel.createSpace(newSpace)
            
            withAnimation(.easeInOut(duration: 0.2)) {
                scale = 0.9
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
            }
        }
    }
}

// MARK: - Modern Header Component
struct ModernHeader: View {
    let dismiss: DismissAction
    @State private var hoverClose = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Space")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Design your perfect workspace")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(hoverClose ? .primary : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(hoverClose ? .gray : .clear)
                    )
                    .scaleEffect(hoverClose ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoverClose = hovering
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
}

// MARK: - Floating Content Card
struct FloatingContentCard: View {
    @Binding var spaceName: String
    @Binding var selectedColor: Space.SpaceColor
    @Binding var isAnimating: Bool
    let createAction: () -> Void
    
    @State private var nameFieldFocused = false
    @State private var hoverCreate = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Space name input with modern styling
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Space Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !spaceName.isEmpty {
                        Text("\(spaceName.count)/50")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                TextField("Enter space name...", text: $spaceName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary.opacity(isTextFieldFocused ? 0.8 : 0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isTextFieldFocused ? .blue.opacity(0.6) : .clear,
                                        lineWidth: 2
                                    )
                            )
                    )
                    .scaleEffect(isTextFieldFocused ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
            }
            
            // Color selection with animated preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Color Theme")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(Space.SpaceColor.allCases, id: \.self) { color in
                        ColorSelectionButton(
                            color: color,
                            isSelected: selectedColor == color,
                            action: { selectedColor = color }
                        )
                    }
                }
            }
            
            Spacer()
            
            // Create button with premium styling
            Button(action: createAction) {
                HStack(spacing: 8) {
                    if isAnimating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isAnimating ? "Creating..." : "Create Space")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                           
                            LinearGradient(
                                colors: [Color.spaceColor(selectedColor), Color.spaceColor(selectedColor).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .scaleEffect(hoverCreate && !spaceName.isEmpty ? 1.02 : 1.0)
                .shadow(
                    color: spaceName.isEmpty ? .clear : Color.spaceColor(selectedColor).opacity(0.3),
                    radius: hoverCreate ? 8 : 4,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(.plain)
            .disabled(spaceName.isEmpty || isAnimating)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoverCreate = hovering
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
    }
}

// MARK: - Color Selection Button
struct ColorSelectionButton: View {
    let color: Space.SpaceColor
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.spaceColor(color))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: Color.spaceColor(color).opacity(0.3),
                        radius: isSelected ? 6 : 2,
                        x: 0,
                        y: 2
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                }
            }
            .scaleEffect(isSelected ? 1.2 : (isHovering ? 1.1 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .blue.opacity(0.1),
                        .purple.opacity(0.08),
                        .pink.opacity(0.06)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
            )
            .overlay(
                // Floating particles effect
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(0.03))
                        .frame(width: CGFloat.random(in: 20...60))
                        .position(
                            x: CGFloat.random(in: 0...480),
                            y: CGFloat.random(in: 0...320)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...7))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.5),
                            value: animateGradient
                        )
                }
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
    }
}
