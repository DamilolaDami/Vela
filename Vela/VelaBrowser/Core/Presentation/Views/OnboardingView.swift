//
//  OnboardingView.swift
//  Vela
//
//  Created by damilola on 6/1/25.
//

import SwiftUI

// MARK: - Main OnboardingView
struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var showCreateSpace = false
    @State private var animateContent = false
    @Environment(\.dismiss) private var dismiss
    
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "safari.fill",
            title: "Meet Vela",
            subtitle: "The browser designed for power users",
            description: "Vela reimagines web browsing with powerful organization tools, intelligent commands, and a clean interface designed for macOS. Let's get you set up in just a few steps.",
            buttonText: "Get Started",
            contentType: .introduction
        ),
        OnboardingStep(
            icon: "safari.fill",
            title: "Unlock the\nfull potential",
            subtitle: "Granting these permissions ensures all features work seamlessly from the get-go.",
            description: "Vela reimagines web browsing with powerful organization tools, intelligent commands, and a clean interface designed for macOS.",
            buttonText: "Continue",
            contentType: .permissions
        ),
        OnboardingStep(
            icon: "rectangle.3.group.fill",
            title: "Organize with\nTabs & Spaces",
            subtitle: "Keep your workflow organized and never lose track",
            description: "Group related tabs into Spaces, switch between projects instantly, and maintain perfect organization across all your browsing contexts.",
            buttonText: "Continue",
            contentType: .feature
        ),
        OnboardingStep(
            icon: "command.circle.fill",
            title: "Global Command\nPalette",
            subtitle: "Navigate at the speed of thought",
            description: "Access any tab, bookmark, or action with intelligent search. Context-aware suggestions adapt to your workflow and boost productivity.",
            buttonText: "Continue",
            contentType: .feature
        ),
        OnboardingStep(
            icon: "plus.circle.fill",
            title: "Create Your\nFirst Space",
            subtitle: "Optional: Set up your workspace",
            description: "Spaces help you separate work, personal browsing, and projects. You can always create one later.",
            buttonText: "Create Space",
            isOptional: true,
            contentType: .createSpace
        ),
        OnboardingStep(
            icon: "checkmark.circle.fill",
            title: "You're All Set!",
            subtitle: "Start browsing with Vela",
            description: "Vela is ready to transform your browsing experience. Press ⌘K anytime to open the command palette.",
            buttonText: "Start Browsing",
            contentType: .completion
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView(animateContent: animateContent, geometry: geometry)
                
                VStack(spacing: 0) {
                    // Main content area
                    HStack(spacing: 40) {
                        OnboardingTitleView(
                            step: steps[currentStep],
                            animateContent: animateContent
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 50)
                        
                        OnboardingContentCardView(
                            step: steps[currentStep],
                            animateContent: animateContent
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 50)
                    }
                    .frame(maxHeight: .infinity)
                    
                    OnboardingBottomBarView(
                        currentStep: currentStep,
                        totalSteps: steps.count,
                        step: steps[currentStep],
                        animateContent: animateContent,
                        onNext: {
                            if currentStep < steps.count - 1 {
                                nextStep()
                            } else {
                                dismiss()
                            }
                        },
                        onSkip: { nextStep() }
                    )
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            animateContent = true
        }
        .onChange(of: currentStep) { _ in
            animateContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateContent = true
            }
        }
    }
    
    private func nextStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep += 1
        }
    }
}

// MARK: - Background View
struct OnboardingBackgroundView: View {
    let animateContent: Bool
    let geometry: GeometryProxy
    
    private var primaryAccentColor: Color {
        Color(red: 0.4, green: 0.2, blue: 0.8)
    }
    
    var body: some View {
        ZStack {
            // Base background
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95),
                    Color(NSColor.controlBackgroundColor).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Overall subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    primaryAccentColor.opacity(0.02),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            // Animated orbs
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                primaryAccentColor.opacity(0.03),
                                primaryAccentColor.opacity(0.01),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: geometry.size.width * (index == 0 ? 0.2 : index == 1 ? 0.8 : 0.5),
                        y: geometry.size.height * (index == 0 ? 0.3 : index == 1 ? 0.7 : 0.1)
                    )
                    .scaleEffect(animateContent ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 4.0 + Double(index))
                        .repeatForever(autoreverses: true),
                        value: animateContent
                    )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Title View
struct OnboardingTitleView: View {
    let step: OnboardingStep
    let animateContent: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 24) {
                // Permission tag for permissions step
                if step.contentType == .permissions {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Permissions Required")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 16) {
                    Text(step.title)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.primary,
                                    Color.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .scaleEffect(animateContent ? 1.0 : 0.95)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateContent)
                    
                    Text(step.subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(animateContent ? 1.0 : 0.7)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Content Card View
struct OnboardingContentCardView: View {
    let step: OnboardingStep
    let animateContent: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Group {
                switch step.contentType {
                case .introduction:
                    IntroductionContentView(step: step)
                case .permissions:
                    PermissionsContentView()
                case .createSpace:
                    CreateSpaceContentView()
                case .feature, .completion:
                    FeatureContentView(step: step)
                }
            }
            .frame(maxHeight: 450)
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.black.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.clear,
                                        Color.secondary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            )
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeInOut(duration: 0.6).delay(0.3), value: animateContent)
            
            Spacer()
        }
    }
}

// MARK: - Bottom Bar View
struct OnboardingBottomBarView: View {
    let currentStep: Int
    let totalSteps: Int
    let step: OnboardingStep
    let animateContent: Bool
    let onNext: () -> Void
    let onSkip: () -> Void
    
    private var primaryAccentColor: Color {
        Color(red: 0.4, green: 0.2, blue: 0.8)
    }
    
    private var secondaryAccentColor: Color {
        Color(red: 0.6, green: 0.3, blue: 0.9)
    }
    
    var body: some View {
        HStack {
            OnboardingProgressView(
                currentStep: currentStep,
                totalSteps: totalSteps,
                primaryAccentColor: primaryAccentColor,
                secondaryAccentColor: secondaryAccentColor
            )
            
            Spacer()
            
            OnboardingActionButtonsView(
                step: step,
                animateContent: animateContent,
                primaryAccentColor: primaryAccentColor,
                secondaryAccentColor: secondaryAccentColor,
                onNext: onNext,
                onSkip: onSkip
            )
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.7))
                    .blur(radius: 20)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.secondary.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
                    .offset(y: -28)
            }
        )
    }
}

// MARK: - Progress View
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let primaryAccentColor: Color
    let secondaryAccentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(primaryAccentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(primaryAccentColor.opacity(0.1))
                )
            
            GeometryReader { progressGeometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [primaryAccentColor, secondaryAccentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: progressGeometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps),
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.5), value: currentStep)
                }
            }
            .frame(width: 120, height: 4)
        }
    }
}

// MARK: - Action Buttons View
struct OnboardingActionButtonsView: View {
    let step: OnboardingStep
    let animateContent: Bool
    let primaryAccentColor: Color
    let secondaryAccentColor: Color
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if step.isOptional {
                Button("Skip for now") {
                    onSkip()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .overlay(
                            Capsule()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: onNext) {
                HStack(spacing: 10) {
                    Text(step.buttonText)
                        .font(.system(size: 15, weight: .semibold))
                    
                    if step.buttonText != "Start Browsing" {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [primaryAccentColor, secondaryAccentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [primaryAccentColor.opacity(0.3), secondaryAccentColor.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(
                    color: primaryAccentColor.opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .scaleEffect(animateContent ? 1.0 : 0.95)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateContent)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
struct OnboardingStep {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let buttonText: String
    let isOptional: Bool
    let contentType: ContentType
    
    enum ContentType {
        case introduction
        case permissions
        case feature
        case createSpace
        case completion
    }
    
    init(icon: String, title: String, subtitle: String, description: String, buttonText: String, isOptional: Bool = false, contentType: ContentType) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.buttonText = buttonText
        self.isOptional = isOptional
        self.contentType = contentType
    }
}

// MARK: - Enhanced Content Views

struct IntroductionContentView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 32) {
            // Welcome illustration with enhanced styling
            ZStack {
                // Animated background circles
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.15),
                                Color.purple.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 100
                        )
                    )
                    .frame(width: 140, height: 140)
                
                // Main Vela logo/icon
                Image(systemName: step.icon)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.purple,
                                Color.blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            // Welcome message
            VStack(spacing: 16) {
                Text("Welcome to the future of browsing")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .lineSpacing(3)
            }
        }
    }
}

struct PermissionsContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Calendar and Contacts
            PermissionRow(
                icon: "calendar",
                title: "Calendar and Contacts",
                description: "Allows you to check upcoming meetings and join calls.",
                isGranted: true
            )
            
            // Files and Folders
            PermissionRow(
                icon: "folder.fill",
                title: "Files and Folders",
                description: "Allows you to find documents and see recently opened files.",
                isGranted: true
            )
            
            // Accessibility
            PermissionRow(
                icon: "accessibility",
                title: "Accessibility",
                description: "Allows you to resize windows, expand snippets, and more.",
                isGranted: false
            )
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(NSColor.controlBackgroundColor).opacity(0.8),
                                Color(NSColor.controlBackgroundColor).opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Enhanced status
            if isGranted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Text("Granted")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.1))
                )
            } else {
                Button("Grant Access") {
                    // Handle permission request
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct CreateSpaceContentView: View {
    @State private var spaceName = ""
    @State private var selectedColor = Color.purple
    
    private let colors: [Color] = [
        .purple, .blue, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Enhanced form with better styling
            VStack(alignment: .leading, spacing:20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Space Name")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("Work, Personal, Research...", text: $spaceName)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.textBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Theme")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [color, color.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColor == color ? Color.primary : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                    .shadow(
                                        color: selectedColor == color ? color.opacity(0.4) : Color.clear,
                                        radius: 6,
                                        x: 0,
                                        y: 3
                                    )
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

struct FeatureContentView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 32) {
            // Enhanced icon with animated background
            ZStack {
                // Animated background circles
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.12),
                                Color.purple.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                // Main icon
                Image(systemName: step.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.purple,
                                Color.purple.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Enhanced description
            Text(step.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .lineSpacing(3)
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.light)
        .frame(width: 1200, height: 700)
}
