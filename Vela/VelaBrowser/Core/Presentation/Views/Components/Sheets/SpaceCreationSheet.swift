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
    
    // Icon picker states
    @State private var selectedIconType: IconType = .emoji
    @State private var selectedIconValue: String = "🌟"
    @State private var showIconPicker = false
    
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
                    selectedIconType: $selectedIconType,
                    selectedIconValue: $selectedIconValue,
                    showIconPicker: $showIconPicker,
                    isAnimating: $isAnimating,
                    createAction: createSpace
                )
                .scaleEffect(scale)
                .opacity(opacity)
            }
        }
        .frame(width: 480, height: 580) // Increased height for icon picker
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
    
    private func createSpace(customHexColor: String?) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let newSpace = Space(
                name: spaceName,
                color: selectedColor,
                customHexColor: customHexColor,
                iconType: selectedIconType,
                iconValue: selectedIconValue
            )
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
    @Binding var selectedIconType: IconType
    @Binding var selectedIconValue: String
    @Binding var showIconPicker: Bool
    @Binding var isAnimating: Bool
    let createAction: (String?) -> Void
    
    @State private var nameFieldFocused = false
    @State private var hoverCreate = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var customColor: Color = .blue
    @State private var customHexColor: String?
    @State private var circlePosition: CGPoint = CGPoint(x: 150, y: 60)
    @State private var isDragging = false
    
    // Canvas dimensions
    private let canvasWidth: CGFloat = 400
    private let canvasHeight: CGFloat = 150
    private let circleRadius: CGFloat = 12
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon and Space name input with horizontal alignment
            VStack(alignment: .leading, spacing: 8) {
                Text("Space Details")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    // Icon picker button
                    Button(action: { showIconPicker.toggle() }) {
                        HStack(spacing: 6) {
                            // Display current icon
                            Group {
                                switch selectedIconType {
                                case .emoji:
                                    Text(selectedIconValue)
                                        .font(.system(size: 20))
                                case .systemImage:
                                    Image(systemName: selectedIconValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)
                                case .custom:
                                    Image(systemName: selectedIconValue.isEmpty ? "folder" : selectedIconValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .frame(width: 24, height: 24)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.separator, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showIconPicker, arrowEdge: .bottom) {
                        IconPickerPopover(
                            selectedIconType: $selectedIconType,
                            selectedIconValue: $selectedIconValue,
                            showIconPicker: $showIconPicker
                        )
                    }
                    
                    // Space name text field
                    TextField("Enter space name...", text: $spaceName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 16, weight: .medium))
                        .focused($isTextFieldFocused)
                        .frame(maxWidth: .infinity)
                }
                
                if !spaceName.isEmpty {
                    HStack {
                        Spacer()
                        Text("\(spaceName.count)/50")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            // Modern Color Selection Interface
            VStack(alignment: .leading, spacing: 16) {
                Text("Color Theme")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                // Large primary color display with draggable picker
                VStack(spacing: 16) {
                    // Fixed size container for the color picker
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.05))
                        .frame(width: canvasWidth, height: canvasHeight)
                        .overlay(
                            // Simplified gradient canvas
                            LinearGradient(
                                stops: [
                                    .init(color: .red, location: 0.0),
                                    .init(color: .yellow, location: 0.17),
                                    .init(color: .green, location: 0.33),
                                    .init(color: .cyan, location: 0.5),
                                    .init(color: .blue, location: 0.67),
                                    .init(color: .purple, location: 0.83),
                                    .init(color: .red, location: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .overlay(
                                // Vertical saturation/brightness overlay
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.3),
                                        .black.opacity(0.4)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )
                        .overlay(
                            // Draggable color circle with improved positioning
                            Circle()
                                .fill(customColor)
                                .frame(width: circleRadius * 2, height: circleRadius * 2)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.black.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.3), radius: isDragging ? 6 : 4, x: 0, y: 2)
                                .scaleEffect(isDragging ? 1.2 : 1.0)
                                .position(circlePosition)
                                .gesture(
                                    DragGesture(coordinateSpace: .local)
                                        .onChanged { value in
                                            isDragging = true
                                            
                                            // Constrain position within canvas bounds
                                            let newX = max(circleRadius, min(value.location.x, canvasWidth - circleRadius))
                                            let newY = max(circleRadius, min(value.location.y, canvasHeight - circleRadius))
                                            
                                            // Update position immediately for smooth dragging
                                            circlePosition = CGPoint(x: newX, y: newY)
                                            
                                            // Sample color at the new position
                                            let normalizedX = (newX - circleRadius) / (canvasWidth - 2 * circleRadius)
                                            let normalizedY = (newY - circleRadius) / (canvasHeight - 2 * circleRadius)
                                            
                                            let sampledColor = sampleColor(x: normalizedX, y: normalizedY)
                                            customColor = sampledColor
                                            
                                            // Update selected color if it matches a predefined color
                                            updateSelectedColorFromCustom(sampledColor)
                                        }
                                        .onEnded { _ in
                                            isDragging = false
                                        }
                                )
                                .animation(.easeOut(duration: isDragging ? 0 : 0.2), value: isDragging)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Horizontal scrolling color palette (predefined colors)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Space.SpaceColor.allCases, id: \.self) { color in
                                ModernColorButton(
                                    color: color,
                                    isSelected: selectedColor == color,
                                    action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            selectedColor = color
                                            customColor = Color.spaceColor(color)
                                            moveCircleToColor(Color.spaceColor(color))
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            
            Spacer()
            
            // Create button with enhanced styling
            Button(action: { createAction(customHexColor) }) {
                HStack(spacing: 8) {
                    if isAnimating {
                        ProgressView()
                            .progressViewStyle(.circular)
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
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [customColor, customColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .scaleEffect(hoverCreate && !spaceName.isEmpty ? 1.02 : 1.0)
                .shadow(
                    color: spaceName.isEmpty ? .clear : customColor.opacity(0.4),
                    radius: hoverCreate ? 12 : 6,
                    x: 0,
                    y: 6
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
        .onAppear {
            // Initialize with the selected color
            customColor = Color.spaceColor(selectedColor)
            moveCircleToColor(customColor)
        }
    }
    
    // MARK: - Helper Functions
    
    private func sampleColor(x: Double, y: Double) -> Color {
        // Clamp values to 0-1 range
        let clampedX = max(0, min(1, x))
        let clampedY = max(0, min(1, y))
        
        // Sample hue from horizontal position
        let hue = clampedX
        
        // Sample saturation and brightness from vertical position
        let saturation = 1.0 - (clampedY * 0.3)
        let brightness = 1.0 - (clampedY * 0.4)
        
        let color = Color(hue: x, saturation: 1.0 - (y * 0.3), brightness: 1.0 - (y * 0.4))
        customHexColor = color.toHexString()
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private func updateSelectedColorFromCustom(_ color: Color) {
        if let matchingColor = Space.SpaceColor.allCases.min(by: { color1, color2 in
            let distance1 = colorDistance(color, Color.spaceColor(color1))
            let distance2 = colorDistance(color, Color.spaceColor(color2))
            return distance1 < distance2
        }) {
            let distance = colorDistance(color, Color.spaceColor(matchingColor))
            if distance < 0.3 && matchingColor != .custom {
                selectedColor = matchingColor
                customHexColor = nil
            } else {
                selectedColor = .custom
                customHexColor = color.toHexString()
            }
        }
    }
    
    private func colorDistance(_ color1: Color, _ color2: Color) -> Double {
        let c1 = NSColor(color1).usingColorSpace(.sRGB) ?? NSColor.red
        let c2 = NSColor(color2).usingColorSpace(.sRGB) ?? NSColor.blue
        
        let rDiff = c1.redComponent - c2.redComponent
        let gDiff = c1.greenComponent - c2.greenComponent
        let bDiff = c1.blueComponent - c2.blueComponent
        
        return sqrt(Double(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff))
    }
    
    private func moveCircleToColor(_ targetColor: Color) {
        let nsColor = NSColor(targetColor).usingColorSpace(.sRGB) ?? NSColor(targetColor)
        
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        guard h.isFinite && s.isFinite && b.isFinite && a.isFinite else {
            return
        }
        
        let x = circleRadius + h * (canvasWidth - 2 * circleRadius)
        let brightnessNormalized = (1.0 - b) / 0.4
        let saturationNormalized = (1.0 - s) / 0.3
        let y = circleRadius + max(brightnessNormalized, saturationNormalized) * (canvasHeight - 2 * circleRadius)
        customHexColor = targetColor.toHexString()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            circlePosition = CGPoint(
                x: max(circleRadius, min(x, canvasWidth - circleRadius)),
                y: max(circleRadius, min(y, canvasHeight - circleRadius))
            )
        }
    }
}

// MARK: - Modern Color Button
struct ModernColorButton: View {
    let color: Space.SpaceColor
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.spaceColor(color))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(isSelected ? 1.0 : 0.3), lineWidth: isSelected ? 3 : 1)
                )
                .overlay(
                    // Selection indicator
                    Circle()
                        .stroke(Color.spaceColor(color).opacity(0.3), lineWidth: 2)
                        .scaleEffect(1.4)
                        .opacity(isSelected ? 1 : 0)
                )
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .shadow(
                    color: Color.spaceColor(color).opacity(0.3),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .padding(10)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Color Extension for Comparison
extension Color {
    func isApproximatelyEqual(to other: Color, tolerance: Double = 0.1) -> Bool {
        let thisComponents = self.cgColor?.components ?? [0, 0, 0, 1]
        let otherComponents = other.cgColor?.components ?? [0, 0, 0, 1]
        
        guard thisComponents.count >= 3 && otherComponents.count >= 3 else { return false }
        
        let rDiff = abs(thisComponents[0] - otherComponents[0])
        let gDiff = abs(thisComponents[1] - otherComponents[1])
        let bDiff = abs(thisComponents[2] - otherComponents[2])
        
        return rDiff < tolerance && gDiff < tolerance && bDiff < tolerance
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
