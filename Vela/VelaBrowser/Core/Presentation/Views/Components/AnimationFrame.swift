import SwiftUI

// MARK: - Animation Frame Data
struct AnimationFrame {
    let position: CGPoint
    let velocity: CGPoint
    let scale: CGFloat
    let rotation: Double
    let shadowOffset: CGSize
    let shadowOpacity: Double
}

// MARK: - Physics Calculator
class ProjectileAnimationCalculator {
    static func calculateFrames(
        startPosition: CGPoint,
        endPosition: CGPoint,
        initialVelocityY: CGFloat = 600,
        gravity: CGFloat = 1400,
        frameDuration: Double = 1.0/60.0
    ) -> [AnimationFrame] {
        
        let deltaX = endPosition.x - startPosition.x
        let deltaY = endPosition.y - startPosition.y
        
        // In iOS coordinates, we need to flip the physics
        // Positive deltaY means going down, negative means going up
        let physicsInitialVelocityY = -abs(initialVelocityY) // Always start going "up" in physics terms
        let physicsGravity = abs(gravity) // Gravity always pulls "down" in physics terms
        
        // Solve quadratic equation: deltaY = v0*t + 0.5*g*t²
        // Rearranged: 0.5*g*t² + v0*t - deltaY = 0
        let a = 0.5 * physicsGravity
        let b = physicsInitialVelocityY
        let c = -deltaY
        
        let discriminant = b * b - 4 * a * c
        guard discriminant >= 0 else { return [] }
        
        // Take the positive root for forward time
        let totalTime = (-b + sqrt(discriminant)) / (2 * a)
        guard totalTime > 0 else { return [] }
        
        let initialVelocityX = deltaX / totalTime
        let frameCount = Int(totalTime / frameDuration)
        
        // Calculate peak time and position for scaling reference
        let peakTime = -physicsInitialVelocityY / physicsGravity
        let peakY = startPosition.y + physicsInitialVelocityY * peakTime + 0.5 * physicsGravity * peakTime * peakTime
        
        var frames: [AnimationFrame] = []
        frames.reserveCapacity(frameCount + 1) // Pre-allocate capacity
        
        for i in 0...frameCount {
            let t = Double(i) * frameDuration
            let progress = t / totalTime
            
            // Position calculations (convert back to iOS coordinates)
            let x = startPosition.x + initialVelocityX * CGFloat(t)
            let y = startPosition.y + physicsInitialVelocityY * CGFloat(t) + 0.5 * physicsGravity * CGFloat(t * t)
            
            // Velocity calculations
            let velocityX = initialVelocityX
            let velocityY = physicsInitialVelocityY + physicsGravity * CGFloat(t)
            
            // Enhanced scale calculation based on arc progression
            let scale = calculateScaleForArc(
                currentTime: t,
                peakTime: peakTime,
                totalTime: totalTime,
                currentY: y,
                peakY: peakY,
                startY: startPosition.y,
                endY: endPosition.y
            )
            
            // Rotation based on velocity direction
            let rotation = atan2(Double(velocityY), Double(velocityX)) * 180 / .pi
            
            // Shadow effects (stronger when closer to ground)
            let distanceFromPeak = abs(y - peakY)
            let maxDistanceFromPeak = max(abs(startPosition.y - peakY), abs(endPosition.y - peakY))
            let heightProgress = maxDistanceFromPeak > 0 ? (1.0 - distanceFromPeak / maxDistanceFromPeak) : 0
            let shadowIntensity = 1.0 - heightProgress
            
            let shadowOffset = CGSize(
                width: shadowIntensity * 4,
                height: shadowIntensity * 6
            )
            let shadowOpacity = Double(0.4 * shadowIntensity)
            
            frames.append(AnimationFrame(
                position: CGPoint(x: x, y: y),
                velocity: CGPoint(x: velocityX, y: velocityY),
                scale: scale,
                rotation: rotation,
                shadowOffset: shadowOffset,
                shadowOpacity: shadowOpacity
            ))
        }
        
        return frames
    }
    
    // Enhanced scale calculation for arc-based scaling
    private static func calculateScaleForArc(
        currentTime: Double,
        peakTime: Double,
        totalTime: Double,
        currentY: CGFloat,
        peakY: CGFloat,
        startY: CGFloat,
        endY: CGFloat
    ) -> CGFloat {
        
        let minScale: CGFloat = 0.6  // Starting scale
        let maxScale: CGFloat = 1.4  // Peak scale at arc top
        let endScale: CGFloat = 0.8  // Final scale at destination
        
        // Calculate progress through the arc using time-based approach
        let timeProgress = currentTime / totalTime
        
        // Create a custom scaling curve that peaks at the arc's highest point
        if currentTime <= peakTime {
            // Ascending phase: scale up to maximum at peak
            let ascendProgress = currentTime / peakTime
            // Use ease-out curve for smooth acceleration to peak
            let easedProgress = 1.0 - pow(1.0 - ascendProgress, 2.0)
            return minScale + (maxScale - minScale) * CGFloat(easedProgress)
            
        } else {
            // Descending phase: scale down from peak to destination
            let descendProgress = (currentTime - peakTime) / (totalTime - peakTime)
            // Use ease-in curve for smooth deceleration from peak
            let easedProgress = pow(descendProgress, 1.5)
            return maxScale - (maxScale - endScale) * CGFloat(easedProgress)
        }
    }
}

// MARK: - Download Animation View Modifier
struct DownloadAnimation: ViewModifier {
    @Binding var isTriggered: Bool
    @Binding var tappedPosition: CGPoint
    let targetPosition: CGPoint
    let icon: AnyView
    
    @State private var animationFrames: [AnimationFrame] = []
    @State private var currentFrameIndex: Int = 0
    @State private var isAnimating: Bool = false
    @State private var squishScale: CGFloat = 1.0
    @State private var finalPosition: CGPoint = .zero
    @State private var animationTimer: Timer?
    
    // OPTIMIZED FOR 2-SECOND TOTAL ANIMATION
    private let frameDuration: Double = 1.0/60.0 // Standard 60fps
    private let animationSpeedMultiplier: Double = 2.5 // Increased for faster projectile motion
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isAnimating && !animationFrames.isEmpty && currentFrameIndex < animationFrames.count {
                let currentFrame = animationFrames[currentFrameIndex]
                
                icon
                    .scaleEffect(currentFrame.scale * squishScale)
                    .rotationEffect(.degrees(currentFrame.rotation))
                    .shadow(
                        color: .black.opacity(currentFrame.shadowOpacity),
                        radius: 4,
                        x: currentFrame.shadowOffset.width,
                        y: currentFrame.shadowOffset.height
                    )
                    .position(currentFrame.position)
                    .drawingGroup() // Force layer backing for better performance
            } else if isAnimating && !animationFrames.isEmpty {
                // Show final frame
                icon
                    .scaleEffect(squishScale)
                    .position(finalPosition)
                    .drawingGroup() // Force layer backing for better performance
            }
        }
        .onChange(of: isTriggered) { newValue in
            if newValue {
                startAnimation()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        
        // Stop any existing timer
        stopTimer()
        
        // Calculate physics-based animation frames with optimized parameters for ~1.5s flight
        animationFrames = ProjectileAnimationCalculator.calculateFrames(
            startPosition: tappedPosition,
            endPosition: targetPosition,
            initialVelocityY: 800, // Increased velocity for faster arc
            gravity: 1600, // Increased gravity for faster fall
            frameDuration: frameDuration / animationSpeedMultiplier
        )
        
        guard !animationFrames.isEmpty else {
            print("No animation frames generated")
            return
        }
        
        isAnimating = true
        currentFrameIndex = 0
        squishScale = 1.0
        finalPosition = targetPosition
        
        // Use Timer for better performance instead of nested DispatchQueue calls
        animateWithTimer()
    }
    
    private func animateWithTimer() {
        let adjustedFrameDuration = frameDuration / animationSpeedMultiplier
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: adjustedFrameDuration, repeats: true) { timer in
            guard currentFrameIndex < animationFrames.count else {
                timer.invalidate()
                performSquishAnimation()
                return
            }
            
            currentFrameIndex += 1
        }
    }
    
    private func stopTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func performSquishAnimation() {
        guard let finalFrame = animationFrames.last else { return }
        let finalVelocity = finalFrame.velocity
        
        // Calculate impact intensity based on velocity
        let velocityMagnitude = sqrt(finalVelocity.x * finalVelocity.x + finalVelocity.y * finalVelocity.y)
        let impactIntensity = min(velocityMagnitude / 800.0, 1.0) // Normalize to 0-1
        
        // Calculate squish amounts based on velocity direction
        let velocityAngle = atan2(finalVelocity.y, finalVelocity.x)
        let isVerticalImpact = abs(sin(velocityAngle)) > 0.7
        
        // More natural squish scaling
        let minSquish: CGFloat = 0.5 // Less extreme squish
        let maxSquish: CGFloat = 0.8
        let squishAmount = maxSquish - (maxSquish - minSquish) * impactIntensity
        
        // Asymmetric squish for more natural feel
        let scaleX: CGFloat = isVerticalImpact ? squishAmount : (squishAmount + 0.2)
        let scaleY: CGFloat = isVerticalImpact ? (squishAmount + 0.2) : squishAmount
        
        // OPTIMIZED SQUISH TIMING FOR FASTER COMPLETION
        // Phase 1: Impact squish (reduced duration)
        let impactDuration = 0.04 + (0.01 * impactIntensity) // Reduced from 0.06-0.08 to 0.04-0.05
        
        withAnimation(.easeOut(duration: impactDuration)) {
            squishScale = 1.0 // Reset to ensure clean transition
        }
        
        // Minimal delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
            withAnimation(.easeOut(duration: impactDuration)) {
                // Apply asymmetric squish
                squishScale = (scaleX + scaleY) / 2
            }
        }
        
        // Phase 2: Bounce back (faster spring animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + impactDuration + 0.005) {
            let bounceStiffness = 500.0 + (impactIntensity * 300.0) // Increased stiffness for much faster bounce
            let bounceDamping = 20.0 + (impactIntensity * 8.0) // Better damping ratio
            
            withAnimation(.interpolatingSpring(
                mass: 0.5, // Reduced mass for much snappier feel
                stiffness: bounceStiffness,
                damping: bounceDamping,
                initialVelocity: impactIntensity * 5.0 // Increased velocity
            )) {
                squishScale = 1.0
            }
        }
        
        // OPTIMIZED CLEANUP FOR 2-SECOND TOTAL
        // Total squish animation: ~0.4s (reduced from previous 0.8s+)
        let totalSquishDuration = impactDuration + 0.35 // Much shorter total squish time
        DispatchQueue.main.asyncAfter(deadline: .now() + totalSquishDuration) {
            cleanup()
        }
    }
    
    private func cleanup() {
        stopTimer()
        isAnimating = false
        isTriggered = false
        currentFrameIndex = 0
        animationFrames = []
    }
}

// MARK: - Convenience View Modifier Extension
extension View {
    func downloadAnimation(
        isTriggered: Binding<Bool>,
        tappedPosition: Binding<CGPoint>,
        targetPosition: CGPoint,
        icon: @escaping () -> some View
    ) -> some View {
        self.modifier(DownloadAnimation(
            isTriggered: isTriggered,
            tappedPosition: tappedPosition,
            targetPosition: targetPosition,
            icon: AnyView(icon())
        ))
    }
}

// MARK: - Demo View
struct DownloadAnimationDemo: View {
    @State private var isTriggered = false
    @State private var tappedPosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                // Tappable content area
                VStack(spacing: 20) {
                    Text("Tap anywhere to download!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("2-second total animation:\n~1.5s flight + 0.5s impact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Download Item") {
                        triggerDownload(at: CGPoint(x: geometry.size.width/2, y: geometry.size.height/2))
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    triggerDownload(at: location)
                }
                
                // Download area (bottom left)
                HStack {
                    VStack {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        Text("Downloads")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
            }
            .downloadAnimation(
                isTriggered: $isTriggered,
                tappedPosition: $tappedPosition,
                targetPosition: CGPoint(x: 60, y: geometry.size.height - 100),
                icon: {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.orange)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 2)
                                .frame(width: 40, height: 40)
                        )
                }
            )
        }
        .preferredColorScheme(.light) // Optimize for consistent rendering
    }
    
    private func triggerDownload(at position: CGPoint) {
        tappedPosition = position
        isTriggered = true
    }
}

// MARK: - Preview
struct DownloadAnimationDemo_Previews: PreviewProvider {
    static var previews: some View {
        DownloadAnimationDemo()
    }
}
