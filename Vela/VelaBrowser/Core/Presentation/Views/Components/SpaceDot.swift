//
//  SpaceDot.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

struct SpaceDot: View {
    @ObservedObject var viewModel: BrowserViewModel
    let space: Space
    @State private var isHovered = false

    var isSelected: Bool {
        viewModel.currentSpace?.id == space.id
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectSpace(space)
                viewModel.isShowingSpaceInfoPopover = false
            }
        }) {
            Circle()
                .fill(isSelected ? Color.spaceColor(space.color) : .gray.opacity(0.4))
                .frame(width: isSelected ? 12 : 10, height: isSelected ? 12 : 10)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .black.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .shadow(color: isSelected ? Color.spaceColor(space.color).opacity(0.3) : .black.opacity(0.1), radius: 2)
                .scaleEffect(isHovered ? 1.2 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
                if hovering {
                    viewModel.spaceForInfoPopover = space
                    viewModel.isShowingSpaceInfoPopover = true
                } else {
                    // Delay hiding to allow popover interaction
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if !isHovered {
                            viewModel.isShowingSpaceInfoPopover = false
                            viewModel.spaceForInfoPopover = nil
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
