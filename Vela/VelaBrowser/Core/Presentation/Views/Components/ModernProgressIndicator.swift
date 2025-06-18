//
//  ModernProgressIndicator.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

// Custom Modern Progress Indicator with Progressive Gradient
struct VelaProgressIndicator: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    @State private var glowOffset: Double = 0
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 4)
                
                // Progress fill with progressive gradient
                Rectangle()
                    .fill(progressiveGradient)
                    .frame(width: max(0, animatedProgress * geometry.size.width), height: 4)
                    .overlay(
                        // Enhanced shimmer effect
                        Rectangle()
                            .fill(shimmerGradient)
                            .frame(width: 40)
                            .offset(x: glowOffset - 20)
                            .opacity(animatedProgress > 0.05 ? 1 : 0)
                            .animation(
                                Animation.linear(duration: 2.0).repeatForever(autoreverses: false),
                                value: glowOffset
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
            }
        
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    animatedProgress = progress
                }
                // Start shimmer animation with container width
                startShimmerAnimation(containerWidth: geometry.size.width)
            }
            .onChange(of: progress) { _, newProgress in
                withAnimation(.easeOut(duration: 0.3)) {
                    animatedProgress = newProgress
                }
            }
        }
        .frame(height: 4) // Set a default height for the GeometryReader
    }
    
    // Progressive gradient that changes based on progress
    private var progressiveGradient: LinearGradient {
        let baseColors: [Color]
        let progressStops: [Double]
        
        switch animatedProgress {
        case 0...0.2:
            // Early stage - soft blue
            baseColors = [
                Color.blue.opacity(0.6),
                Color.blue.opacity(0.8),
                Color.blue
            ]
            progressStops = [0, 0.5, 1]
            
        case 0.2...0.5:
            // Mid-early stage - blue to cyan
            baseColors = [
                Color.blue.opacity(0.7),
                Color.blue,
                Color.cyan.opacity(0.8),
                Color.cyan
            ]
            progressStops = [0, 0.3, 0.7, 1]
            
        case 0.5...0.8:
            // Mid-late stage - cyan to green
            baseColors = [
                Color.blue,
                Color.cyan,
                Color.mint.opacity(0.9),
                Color.green.opacity(0.8)
            ]
            progressStops = [0, 0.25, 0.6, 1]
            
        default:
            // Final stage - green to success
            baseColors = [
                Color.cyan,
                Color.mint,
                Color.green,
                Color.green.opacity(0.9)
            ]
            progressStops = [0, 0.2, 0.7, 1]
        }
        
        return LinearGradient(
            stops: zip(baseColors, progressStops).map { color, stop in
                Gradient.Stop(color: color, location: stop)
            },
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Shimmer gradient that adapts to progress
    private var shimmerGradient: LinearGradient {
        let shimmerIntensity = min(0.8, animatedProgress * 1.2)
        
        return LinearGradient(
            colors: [
                Color.white.opacity(0),
                Color.white.opacity(shimmerIntensity * 0.4),
                Color.white.opacity(shimmerIntensity * 0.8),
                Color.white.opacity(shimmerIntensity * 0.4),
                Color.white.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Shadow color that intensifies with progress
    private var shadowColor: Color {
        switch animatedProgress {
        case 0...0.3:
            return Color.blue.opacity(0.3)
        case 0.3...0.6:
            return Color.cyan.opacity(0.4)
        case 0.6...0.9:
            return Color.mint.opacity(0.4)
        default:
            return Color.green.opacity(0.5)
        }
    }
    
    private func startShimmerAnimation(containerWidth: CGFloat) {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            glowOffset = containerWidth + 20 // Extend slightly beyond container
        }
    }
}
