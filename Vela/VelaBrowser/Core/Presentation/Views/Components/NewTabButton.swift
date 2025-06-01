//
//  NewTabButton.swift
//  Vela
//
//  Created by damilola on 6/1/25.
//

import SwiftUI


struct NewTabButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                
                Text("New Tab")
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isHovered ?
                        Color(NSColor.controlAccentColor).opacity(0.1) :
                        Color.clear
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
