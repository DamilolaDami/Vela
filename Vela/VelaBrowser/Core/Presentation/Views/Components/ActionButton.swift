//
//  ActionButton.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//
import SwiftUI


struct ActionButton: View {
    let icon: String
    var isActive: Bool = false
    var activeColor: Color = .blue
    var badge: Int = 0
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isActive ? activeColor.opacity(0.15) :
                        (isHovered ? Color.black.opacity(0.05) : Color.clear)
                    )
                    .frame(width: 28, height: 28)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(
                        isActive ? activeColor :
                        (isHovered ? .primary : .secondary)
                    )
                
                // Badge for downloads
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                        .offset(x: 10, y: -10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(tooltip) // Native macOS tooltip
    }
}
