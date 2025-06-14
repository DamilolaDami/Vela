import SwiftUI

struct OnboardingView: View {
    var viewModel: OnboardingViewModel
    var broswerViewModel: BrowserViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showSplash = true
    @State private var splashAnimationPhase: SplashPhase = .initial
    @State private var showEmptyTitleAlert = false // New state for alert
    
    enum SplashPhase {
        case initial
        case textAppeared
        case logoAnimating
        case completed
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        GeometryReader { geometry in
            ZStack {
                // Unified background using MeshGradient
                UnifiedMeshBackground(
                    showSplash: showSplash,
                    splashPhase: splashAnimationPhase,
                    animateContent: viewModel.animateContent,
                    geometry: geometry,
                    colorScheme: colorScheme
                )
                
                // Splash screen content (without icon)
                if showSplash {
                    OnboardingSplashContent(
                        splashPhase: splashAnimationPhase,
                        geometry: geometry,
                        onAnimationComplete: {
                            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                                showSplash = false
                            }
                            // Extended delay before starting main onboarding animations
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                viewModel.startOnboarding()
                            }
                        }
                    )
                } else {
                    // Main onboarding content (without icon in title)
                    VStack(spacing: 0) {
                        HStack(spacing: 40) {
                            OnboardingTitleView(
                                step: viewModel.currentOnboardingStep,
                                animateContent: viewModel.animateContent
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 50)
                            
                            OnboardingContentCardView(
                                step: viewModel.currentOnboardingStep,
                                animateContent: viewModel.animateContent,
                                colorScheme: colorScheme,
                                spaceName: $viewModel.spaceName,
                                selectedColor: $viewModel.selectedColor
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 50)
                        }
                        .frame(maxHeight: .infinity)
                        
                        OnboardingBottomBarView(
                            viewModel: viewModel,
                            currentStep: viewModel.currentStep,
                            totalSteps: viewModel.totalSteps,
                            step: viewModel.currentOnboardingStep,
                            animateContent: viewModel.animateContent,
                            onNext: {
                                if viewModel.currentStep < viewModel.totalSteps - 1 {
                                    let currentStep: OnboardingStep = viewModel.steps[viewModel.currentStep]
                                    if currentStep.contentType == .createSpace {
                                        // Validate space name
                                        if viewModel.spaceName.trimmingCharacters(in: .whitespaces).isEmpty {
                                            showEmptyTitleAlert = true
                                        } else {
                                            let space = Space(name: viewModel.spaceName, color: viewModel.selectedColor)
                                            broswerViewModel.createSpace(space)
                                            viewModel.nextStep()
                                        }
                                    } else {
                                        viewModel.nextStep()
                                    }
                                } else {
                                    viewModel.completeOnboarding()
                                }
                            },
                            onSkip: { viewModel.skipStep() }
                        )
                    }
                }
                
                // Unified icon that animates from splash to onboarding position
                UnifiedAppIcon(
                    showSplash: showSplash,
                    splashPhase: splashAnimationPhase,
                    animateContent: viewModel.animateContent,
                    currentStep: viewModel.currentOnboardingStep,
                    geometry: geometry
                )
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .onAppear {
            startSplashSequence()
        }
        .alert("Space Name Required", isPresented: $showEmptyTitleAlert) {
            Button("OK") { }
        } message: {
            Text("Please enter a name for your space before continuing.")
        }
    }
    
    private func startSplashSequence() {
        // Phase 1: Show text after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 1.2)) {
                splashAnimationPhase = .textAppeared
            }
        }
        
        // Phase 2: Start logo animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                splashAnimationPhase = .logoAnimating
            }
        }
        
        // Phase 3: Complete splash and show main onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
            splashAnimationPhase = .completed
        }
    }
}

// MARK: - Unified MeshGradient Background
struct UnifiedMeshBackground: View {
    let showSplash: Bool
    let splashPhase: OnboardingView.SplashPhase
    let animateContent: Bool
    let geometry: GeometryProxy
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Unified mesh gradient background
            if #available(macOS 15.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: meshColors
                )
                .ignoresSafeArea()
                .scaleEffect(meshScale)
                .opacity(meshOpacity)
                .animation(.easeInOut(duration: 1.2), value: splashPhase)
                .animation(.easeInOut(duration: 3.0), value: animateContent)
            } else {
                // Fallback gradient for earlier versions
                LinearGradient(
                    colors: [
                        primaryAccentColor.opacity(0.2),
                        primaryAccentColor.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Animated particles that work for both states
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                primaryAccentColor.opacity(particleOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particleRadius
                        )
                    )
                    .frame(width: particleSize, height: particleSize)
                    .offset(
                        x: geometry.size.width * particleXOffset(for: index),
                        y: geometry.size.height * particleYOffset(for: index)
                    )
                    .scaleEffect(particleScale)
                    .opacity(particleAnimatedOpacity)
                    .animation(
                        .easeInOut(duration: particleDuration(for: index))
                        .repeatForever(autoreverses: true),
                        value: showSplash
                    )
                    .animation(
                        .easeInOut(duration: particleDuration(for: index))
                        .repeatForever(autoreverses: true),
                        value: animateContent
                    )
            }
        }
    }
    
    private var primaryAccentColor: Color {
        colorScheme == .dark ? Color(red: 0.5, green: 0.3, blue: 0.9) : Color(red: 0.4, green: 0.2, blue: 0.8)
    }
    
    private var meshColors: [Color] {
        if showSplash {
            return [
                colorScheme == .dark ? Color(red: 0.1, green: 0.05, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 1.0),
                colorScheme == .dark ? Color(red: 0.2, green: 0.1, blue: 0.4) : Color(red: 0.9, green: 0.9, blue: 1.0),
                colorScheme == .dark ? Color(red: 0.15, green: 0.1, blue: 0.3) : Color(red: 0.85, green: 0.9, blue: 1.0),
                
                colorScheme == .dark ? Color(red: 0.3, green: 0.15, blue: 0.5) : Color(red: 0.8, green: 0.85, blue: 0.95),
                colorScheme == .dark ? Color(red: 0.5, green: 0.3, blue: 0.9) : Color(red: 0.7, green: 0.8, blue: 0.95),
                colorScheme == .dark ? Color(red: 0.4, green: 0.2, blue: 0.7) : Color(red: 0.75, green: 0.85, blue: 1.0),
                
                colorScheme == .dark ? Color(red: 0.2, green: 0.1, blue: 0.3) : Color(red: 0.9, green: 0.9, blue: 0.95),
                colorScheme == .dark ? Color(red: 0.35, green: 0.2, blue: 0.6) : Color(red: 0.8, green: 0.85, blue: 0.95),
                colorScheme == .dark ? Color(red: 0.25, green: 0.15, blue: 0.4) : Color(red: 0.85, green: 0.9, blue: 1.0)
            ]
        } else {
            return [
                primaryAccentColor.opacity(0.15),
                primaryAccentColor.opacity(0.12),
                primaryAccentColor.opacity(0.08),
                primaryAccentColor.opacity(0.1),
                primaryAccentColor.opacity(0.05),
                primaryAccentColor.opacity(0.12),
                primaryAccentColor.opacity(0.08),
                primaryAccentColor.opacity(0.1),
                primaryAccentColor.opacity(0.06)
            ]
        }
    }
    
    private var meshScale: CGFloat {
        if showSplash {
            return splashPhase == .completed ? 1.1 : 1.0
        } else {
            return animateContent ? 1.05 : 1.0
        }
    }
    
    private var meshOpacity: Double {
        if showSplash {
            return splashPhase == .completed ? 0.3 : 1.0
        } else {
            return 0.8
        }
    }
    
    private var particleCount: Int {
        showSplash ? 8 : 5
    }
    
    private var particleSize: CGFloat {
        showSplash ? 200 : 150
    }
    
    private var particleRadius: CGFloat {
        showSplash ? 100 : 80
    }
    
    private var particleOpacity: Double {
        showSplash ? 0.1 : 0.05
    }
    
    private var particleScale: CGFloat {
        if showSplash {
            return splashPhase == .textAppeared ? 1.2 : 0.8
        } else {
            return animateContent ? 1.3 : 0.7
        }
    }
    
    private var particleAnimatedOpacity: Double {
        if showSplash {
            return splashPhase == .textAppeared ? 0.6 : 0.3
        } else {
            return animateContent ? 0.6 : 0.3
        }
    }
    
    private func particleXOffset(for index: Int) -> Double {
        if showSplash {
            return Double(index % 4) * 0.33 - 0.5
        } else {
            return index % 2 == 0 ? 0.15 : 0.85
        }
    }
    
    private func particleYOffset(for index: Int) -> Double {
        if showSplash {
            return Double(index / 4) * 0.5 - 0.25
        } else {
            return index < 3 ? 0.2 : 0.8
        }
    }
    
    private func particleDuration(for index: Int) -> Double {
        if showSplash {
            return 2.5 + Double(index) * 0.3
        } else {
            return 3.0 + Double(index) * 0.5
        }
    }
}

// MARK: - Unified App Icon
struct UnifiedAppIcon: View {
    let showSplash: Bool
    let splashPhase: OnboardingView.SplashPhase
    let animateContent: Bool
    let currentStep: OnboardingStep
    let geometry: GeometryProxy
    
    // Enhanced animation progress with easing
    @State private var animationProgress: CGFloat = 0.0
    @State private var curveIntensity: CGFloat = 1.0
    
    var body: some View {
        Image("1024-mac")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: iconShadowRadius,
                x: shadowOffsetX,
                y: iconShadowY
            )
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .offset(x: curvedOffsetX, y: curvedOffsetY)
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: rotationAxisX, y: rotationAxisY, z: 0)
            )
            .animation(.interactiveSpring(
                response: 1.2,
                dampingFraction: 0.65,
                blendDuration: 0.3
            ), value: splashPhase)
            .animation(.interactiveSpring(
                response: 0.8,
                dampingFraction: 0.75,
                blendDuration: 0.2
            ).delay(0.15), value: animateContent)
            .zIndex(1000)
            .onChange(of: splashPhase) { _, newPhase in
                handleSplashPhaseChange(newPhase)
            }
            .onChange(of: showSplash) { _, newValue in
                if !newValue {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        animationProgress = 1.0
                    }
                }
            }
    }
    
    // MARK: - Enhanced Curved Path Calculation
    private var curvedOffsetX: CGFloat {
        if showSplash {
            switch splashPhase {
            case .initial, .textAppeared:
                return 0
            case .logoAnimating, .completed:
                return calculateEnhancedCurvedX(progress: easedProgress)
            }
        } else {
            return currentStep.contentType == .introduction ? finalOffsetX : 0
        }
    }
    
    private var curvedOffsetY: CGFloat {
        if showSplash {
            switch splashPhase {
            case .initial, .textAppeared:
                return 0
            case .logoAnimating, .completed:
                return calculateEnhancedCurvedY(progress: easedProgress)
            }
        } else {
            return currentStep.contentType == .introduction ? finalOffsetY : 0
        }
    }
    
    // Enhanced cubic Bézier curve for more natural movement
    private func calculateEnhancedCurvedX(progress: CGFloat) -> CGFloat {
        let startX: CGFloat = 0
        let endX = finalOffsetX
        
        // Control points for more natural curve
        let controlPoint1X = endX * 0.2
        let controlPoint2X = endX * 0.8
        
        return cubicBezier(
            t: progress,
            p0: startX,
            p1: controlPoint1X,
            p2: controlPoint2X,
            p3: endX
        )
    }
    
    private func calculateEnhancedCurvedY(progress: CGFloat) -> CGFloat {
        let startY: CGFloat = 0
        let endY = finalOffsetY
        
        // Enhanced curve with slight upward arc for natural feel
        let controlPoint1Y = endY * -0.3 * curveIntensity
        let controlPoint2Y = endY * 0.6
        
        return cubicBezier(
            t: progress,
            p0: startY,
            p1: controlPoint1Y,
            p2: controlPoint2Y,
            p3: endY
        )
    }
    
    // Cubic Bézier curve calculation
    private func cubicBezier(t: CGFloat, p0: CGFloat, p1: CGFloat, p2: CGFloat, p3: CGFloat) -> CGFloat {
        let oneMinusT = 1 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT
        let tSquared = t * t
        let tCubed = tSquared * t
        
        return oneMinusTCubed * p0 +
               3 * oneMinusTSquared * t * p1 +
               3 * oneMinusT * tSquared * p2 +
               tCubed * p3
    }
    
    // Eased progress for smoother animation
    private var easedProgress: CGFloat {
        // Custom easing function for natural movement
        let t = animationProgress
        return t < 0.5 ?
            4 * t * t * t :
            1 - pow(-2 * t + 2, 3) / 2
    }
    
    private var finalOffsetX: CGFloat {
        -geometry.size.width * 0.413
    }
    
    private var finalOffsetY: CGFloat {
        -geometry.size.height * 0.13
    }
    
    // MARK: - Enhanced Animation Properties
    private var iconSize: CGFloat {
        if showSplash {
            switch splashPhase {
            case .initial: return 120
            case .textAppeared: return 120
            case .logoAnimating, .completed: return 64
            }
        } else {
            return currentStep.contentType == .introduction ? 64 : 0
        }
    }
    
    private var iconCornerRadius: CGFloat {
        let baseRadius: CGFloat
        if showSplash {
            switch splashPhase {
            case .initial: baseRadius = 30
            case .textAppeared: baseRadius = 30
            case .logoAnimating, .completed: baseRadius = 16
            }
        } else {
            baseRadius = 16
        }
        
        // Dynamic corner radius based on animation progress
        let radiusModifier = sin(animationProgress * .pi * 0.5) * 2
        return max(baseRadius - radiusModifier, 8)
    }
    
    private var iconScale: CGFloat {
        if showSplash {
            switch splashPhase {
            case .initial: return 0.8
            case .textAppeared: return 1.0
            case .logoAnimating:
                // Dynamic scaling during curve animation
                let scaleBoost = sin(animationProgress * .pi) * 0.1
                return 1.1 + scaleBoost
            case .completed: return 1.0
            }
        } else {
            return animateContent ? 1.0 : 0.8
        }
    }
    
    private var iconShadowRadius: CGFloat {
        let baseRadius: CGFloat
        if showSplash {
            switch splashPhase {
            case .initial: baseRadius = 20
            case .textAppeared: baseRadius = 25
            case .logoAnimating: baseRadius = 15
            case .completed: baseRadius = 12
            }
        } else {
            baseRadius = 12
        }
        
        // Dynamic shadow during animation
        let shadowModifier = (1 - animationProgress) * 5
        return baseRadius + shadowModifier
    }
    
    private var iconShadowY: CGFloat {
        if showSplash {
            switch splashPhase {
            case .initial: return 8
            case .textAppeared: return 12
            case .logoAnimating: return 6 + (sin(animationProgress * .pi) * 3)
            case .completed: return 6
            }
        } else {
            return 6
        }
    }
    
    private var shadowOpacity: Double {
        let baseOpacity: Double = 0.25
        if splashPhase == .logoAnimating {
            return baseOpacity + (sin(animationProgress * .pi) * 0.15)
        }
        return baseOpacity
    }
    
    private var shadowOffsetX: CGFloat {
        if splashPhase == .logoAnimating {
            return sin(animationProgress * .pi * 2) * 2
        }
        return 0
    }
    
    private var iconOpacity: Double {
        if showSplash {
            return 1.0
        } else {
            return currentStep.contentType == .introduction ? (animateContent ? 1.0 : 0.0) : 0.0
        }
    }
    
    // MARK: - 3D Rotation Effects
    private var rotationAngle: Double {
        if splashPhase == .logoAnimating {
            return sin(animationProgress * .pi) * Double(8)
        }
        return 0
    }
    
    private var rotationAxisX: Double {
        sin(animationProgress * .pi * 2) * 0.3
    }
    
    private var rotationAxisY: Double {
        cos(animationProgress * .pi * 1.5) * 0.2
    }
    
    // MARK: - Animation Control
    private func handleSplashPhaseChange(_ newPhase: OnboardingView.SplashPhase) {
        switch newPhase {
        case .logoAnimating:
            // Reset and start enhanced animation
            animationProgress = 0.0
            curveIntensity = 1.0
            
            withAnimation(.interactiveSpring(
                response: 1.4,
                dampingFraction: 0.68,
                blendDuration: 0.25
            )) {
                animationProgress = 1.0
            }
            
            // Subtle curve intensity animation
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                curveIntensity = 0.8
            }
            
        case .completed:
            // Ensure final position
            withAnimation(.easeOut(duration: 0.3)) {
                animationProgress = 1.0
                curveIntensity = 1.0
            }
            
        default:
            break
        }
    }
}
// MARK: - Updated Splash Content (without icon)
struct OnboardingSplashContent: View {
    let splashPhase: OnboardingView.SplashPhase
    let geometry: GeometryProxy
    let onAnimationComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon space (now handled by UnifiedAppIcon)
            Rectangle()
                .fill(Color.clear)
                .frame(width: 120, height: 120)
            
            // Welcome text
            VStack(spacing: 16) {
              
                
                Text("Vela Browser")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.3, blue: 0.9),
                                Color(red: 0.7, green: 0.4, blue: 1.0),
                                Color(red: 0.4, green: 0.2, blue: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .opacity(textOpacity)
                    .offset(y: textOffsetY)
                    .animation(.easeOut(duration: 1.0).delay(0.3), value: splashPhase)
                
                Text("The future of browsing")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .secondary,
                                .secondary.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(textOpacity)
                    .offset(y: textOffsetY)
                    .animation(.easeOut(duration: 1.0).delay(0.6), value: splashPhase)
            }
            .opacity(splashPhase == .logoAnimating ? 0 : 1)
            .animation(.easeOut(duration: 0.8), value: splashPhase)
            
            Spacer()
        }
        .onAppear {
            // Trigger completion after extended animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
                onAnimationComplete()
            }
        }
    }
    
    private var textOpacity: Double {
        switch splashPhase {
        case .initial: return 0
        case .textAppeared: return 1
        case .logoAnimating, .completed: return 0
        }
    }
    
    private var textOffsetY: CGFloat {
        switch splashPhase {
        case .initial: return 20
        case .textAppeared: return 0
        case .logoAnimating, .completed: return -20
        }
    }
}

// MARK: - Updated Title View (without icon logic)
struct OnboardingTitleView: View {
    let step: OnboardingStep
    let animateContent: Bool
    let showIcon: Bool = false // Icon is now handled separately
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 32) {
                // Icon space (now handled by UnifiedAppIcon)
                if step.contentType == .introduction {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 64, height: 64)
                }
                
                // Enhanced permissions badge
                if step.contentType == .permissions {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        
                        Text("Permissions Required")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.6, blue: 0.0),
                                        Color(red: 1.0, green: 0.3, blue: 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .orange.opacity(0.5), radius: 12, x: 0, y: 6)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    )
                    .scaleEffect(animateContent ? 1.0 : 0.85)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2), value: animateContent)
                }
                
                // Enhanced text content
                VStack(alignment: .leading, spacing: 20) {
                    Text(step.title)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .primary,
                                    .primary.opacity(0.8),
                                    .primary.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
                        .scaleEffect(animateContent ? 1.0 : 0.94)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 1.0, dampingFraction: 0.85).delay(0.4), value: animateContent)
                    
                    Text(step.subtitle)
                        .font(.system(.title2, design: .rounded, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .secondary,
                                    .secondary.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 12)
                        .animation(.easeOut(duration: 1.2).delay(0.7), value: animateContent)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}
// MARK: - Title View

// MARK: - Content Card View
struct OnboardingContentCardView: View {
    let step: OnboardingStep
    let animateContent: Bool
    let colorScheme: ColorScheme
    @Binding  var spaceName: String
    @Binding  var selectedColor: Space.SpaceColor
    
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Group {
                switch step.contentType {
                case .introduction:
                    IntroductionContentView(step: step, animateContent: animateContent)
                case .permissions:
                    PermissionsContentView()
                case .createSpace:
                    CreateSpaceContentView(spaceName: $spaceName, selectedColor: $selectedColor)
                case .feature, .completion:
                    FeatureContentView(step: step, animateContent: animateContent)
                }
            }
            .padding(.all, 32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3),
                                colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(colorScheme == .dark ? 0.15 : 0.3),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .background(
                        VisualEffectView(material: .contentBackground, blendingMode: .withinWindow)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    )
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.1),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 30)
            .animation(.spring(response: 0.7, dampingFraction: 0.9).delay(0.4), value: animateContent)
            
            Spacer()
        }
        .frame(width: 650, height: 450)
    }
}

// MARK: - Bottom Bar View
struct OnboardingBottomBarView: View {
    let viewModel: OnboardingViewModel
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
                viewModel: viewModel,
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
            VisualEffectView(material: .underWindowBackground, blendingMode: .withinWindow)
                .overlay(
                    LinearGradient(
                        colors: [
                            .secondary.opacity(0.15),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(primaryAccentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(primaryAccentColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(primaryAccentColor.opacity(0.3), lineWidth: 1)
                        )
                )
            
            GeometryReader { progressGeometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.15))
                        .frame(height: 5)
                    
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
                            height: 5
                        )
                        .shadow(color: primaryAccentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                }
            }
            .frame(width: 140, height: 5)
        }
    }
}

// MARK: - Action Buttons View
struct OnboardingActionButtonsView: View {
    let viewModel: OnboardingViewModel
    let step: OnboardingStep
    let animateContent: Bool
    let primaryAccentColor: Color
    let secondaryAccentColor: Color
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if step.isOptional {
                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.secondary.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(animateContent ? 1.0 : 0.95)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateContent)
            }
            
            Button(action: onNext) {
                HStack(spacing: 10) {
                    Text(step.buttonText)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    
                    Image(systemName: step.buttonText == "Start Browsing" ? "sparkles" : "arrow.right.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .disabled(step.contentType == .createSpace ? (viewModel.spaceName.isEmpty) : false)
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
                                        colors: [primaryAccentColor.opacity(0.4), secondaryAccentColor.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: primaryAccentColor.opacity(0.5),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                .scaleEffect(animateContent ? 1.0 : 0.92)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateContent)
            }
            .buttonStyle(PlainButtonStyle())
            //.hoverEffect(.lift)
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
    let imageName: String?
    
    enum ContentType {
        case introduction
        case permissions
        case feature
        case createSpace
        case completion
    }
    
    init(icon: String, title: String, subtitle: String, description: String, buttonText: String, isOptional: Bool = false, contentType: ContentType, imageName: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.buttonText = buttonText
        self.isOptional = isOptional
        self.contentType = contentType
        self.imageName = imageName
    }
}

// MARK: - Enhanced Content Views
struct IntroductionContentView: View {
    let step: OnboardingStep
    let animateContent: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
                
                if let imageName = step.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.4),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .scaleEffect(animateContent ? 1.0 : 0.9)
                        .opacity(animateContent ? 1.0 : 0.7)
                        .animation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.5), value: animateContent)
                }
            }
            
            VStack(spacing: 12) {
                Text("Welcome to the future of browsing")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.7), value: animateContent)
                
                Text(step.description)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .lineSpacing(4)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.9), value: animateContent)
            }
            .padding(.horizontal, 12)
        }
    }
}

struct PermissionsContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            PermissionRow(
                icon: "calendar",
                title: "Calendar and Contacts",
                description: "Allows you to check upcoming meetings and join calls.",
                isGranted: true
            )
            
            PermissionRow(
                icon: "folder.fill",
                title: "Files and Folders",
                description: "Allows you to find documents and see recently opened files.",
                isGranted: true
            )
            
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
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(.secondary.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if isGranted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Text("Granted")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.green.opacity(0.15))
                )
            } else {
                Button(action: {}) {
                    Text("Grant Access")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.secondary.opacity(0.15), lineWidth: 1)
                )
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct CreateSpaceContentView: View {
    @Binding var spaceName: String
    @Binding var selectedColor: Space.SpaceColor
   
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Space Name")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Work, Personal, Research...", text: $spaceName)
                    .font(.system(.body, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedColor.color.opacity(0.4), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Color Theme")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(Space.SpaceColor.allCases, id: \.self) { color in
                        let mainColor = Color.spaceColor(color)
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedColor = color
                            }
                        }) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [mainColor, mainColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedColor == color ? .white : .clear,
                                            lineWidth: 2
                                        )
                                )
                                .shadow(
                                    color: selectedColor == color ? mainColor.opacity(0.5) : .clear,
                                    radius: 6,
                                    x: 0,
                                    y: 3
                                )
                                .scaleEffect(selectedColor == color ? 1.15 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Preview of selected color
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedColor.color.opacity(0.2))
                .frame(height: 60)
                .overlay(
                    Text("Preview: \(spaceName.isEmpty ? "Your Space" : spaceName)")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(selectedColor.color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedColor.color.opacity(0.4), lineWidth: 1)
                )
                .opacity(spaceName.isEmpty && selectedColor == .purple ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 0.4), value: spaceName)
        }
    }
}

struct FeatureContentView: View {
    let step: OnboardingStep
    let animateContent: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Show image if available, otherwise show icon
            if let imageName = step.imageName {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.clear)
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                    
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.4),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .scaleEffect(animateContent ? 1.0 : 0.9)
                        .opacity(animateContent ? 1.0 : 0.7)
                        .animation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.3), value: animateContent)
                }
            } else {
                // Icon-based display for steps without images
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .purple.opacity(0.15),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.6)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: animateContent)
                    
                    Image(systemName: step.icon)
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                        .rotationEffect(.degrees(animateContent ? 0 : 10))
                        .scaleEffect(animateContent ? 1.0 : 0.9)
                        .animation(.spring(response: 0.8, dampingFraction: 0.9).delay(0.4), value: animateContent)
                }
            }
            
            VStack(spacing: 12) {
                // Feature highlight for certain content types
                if step.contentType == .completion {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                        
                        Text("Ready to Go!")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.purple.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(.purple.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6).delay(0.6), value: animateContent)
                }
                
                Text(step.description)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.5), value: animateContent)
                
                // Add keyboard shortcut hint for command palette step
                if step.icon == "command.circle.fill" {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("⌘")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                            Text("K")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary.opacity(0.8))
                        )
                        
                        Text("Quick access anytime")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.7), value: animateContent)
                }
            }
        }
    }
}
