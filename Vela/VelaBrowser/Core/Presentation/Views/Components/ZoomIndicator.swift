//
//  ZoomIndicator.swift
//  Vela
//
//  Created by damilola on 6/4/25.
//

import SwiftUI

struct ZoomIndicator: View {
    var zoomLevel: Double
    var isZooming: Bool
    
    @State private var hasAppeared = false
    @State private var animationTrigger = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
            
            Text("\(Int(zoomLevel * 100))%")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 12,
                    x: 0,
                    y: 4
                )
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 3,
                    x: 0,
                    y: 1
                )
        )
        .scaleEffect(hasAppeared ? 1.0 : 0.8)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0),
            value: hasAppeared
        )
        .scaleEffect(animationTrigger ? 1.08 : 1.0)
        .animation(
            .spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0),
            value: animationTrigger
        )
     
        .onAppear {
            hasAppeared = true
        }
        .onChange(of: zoomLevel) {_, _ in
            withAnimation {
                animationTrigger.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animationTrigger.toggle()
                }
            }
        }
        .onChange(of: isZooming) {_, newValue in
            if newValue {
                withAnimation {
                    animationTrigger.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        animationTrigger.toggle()
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        ZoomIndicator(zoomLevel: 1.25, isZooming: true)
    }
}
