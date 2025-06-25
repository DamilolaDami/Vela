//
//  PositionReader.swift
//  Vela
//
//  Created by damilola on 6/24/25.
//

import SwiftUI

struct PositionReader: View {
    let coordinateSpace: CoordinateSpace
    let onChange: (CGPoint) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    let frame = geometry.frame(in: coordinateSpace)
                    let center = CGPoint(x: frame.midX, y: frame.midY)
                    onChange(center)
                }
                .onChange(of: geometry.frame(in: coordinateSpace)) {_, newFrame in
                    let center = CGPoint(x: newFrame.midX, y: newFrame.midY)
                    onChange(center)
                }
        }
    }
}

extension View {
    func onPositionChange(
        in coordinateSpace: CoordinateSpace = .global,
        perform action: @escaping (CGPoint) -> Void
    ) -> some View {
        background(
            PositionReader(coordinateSpace: coordinateSpace, onChange: action)
        )
    }
}
