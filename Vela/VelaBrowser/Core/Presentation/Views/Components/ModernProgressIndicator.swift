//
//  ModernProgressIndicator.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//



import SwiftUI

// Custom Modern Progress Indicator
struct VelaProgressIndicator: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    @State private var glowOffset: Double = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 3)
            
            // Progress fill with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.blue,
                            Color.cyan.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(0, animatedProgress * 150), height: 3)
                .overlay(
                    // Shimmer effect
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60)
                        .offset(x: glowOffset)
                        .animation(
                            Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: glowOffset
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 1.5))
                .shadow(color: Color.blue.opacity(0.4), radius: 2, x: 0, y: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 1.5))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = progress
            }
            // Start shimmer animation
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                glowOffset = 150
            }
        }
        .onChange(of: progress) {_, newProgress in
            withAnimation(.easeInOut(duration: 0.2)) {
                animatedProgress = newProgress
            }
        }
    }
}

// Alternative Circular Progress Indicator
struct CircularProgressIndicator: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                .frame(width: 20, height: 20)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [Color.blue, Color.cyan, Color.blue],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.blue.opacity(0.3), radius: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.2)) {
                animatedProgress = newProgress
            }
        }
    }
}
