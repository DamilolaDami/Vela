//
//  SpaceInfoPopover.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

struct SpaceInfoPopover: View {
    let space: Space

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.spaceColor(space.color))
                .frame(width: 12, height: 12)
            Text(space.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
