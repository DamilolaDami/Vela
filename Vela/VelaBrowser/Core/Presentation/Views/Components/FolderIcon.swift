//
//  FolderIcon.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//


import SwiftUI

struct FolderIcon: View {
    let isOpen: Bool
    
    var body: some View {
        ZStack {
            // Shadow layer
            folderShape
                .fill(Color.black.opacity(0.15))
                .offset(x: 2, y: 3)
                .blur(radius: 3)
            
            // Main folder body
            folderShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.78, blue: 0.35),
                            Color(red: 0.85, green: 0.68, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    folderShape
                        .stroke(
                            Color(red: 0.75, green: 0.58, blue: 0.15),
                            lineWidth: 1.5
                        )
                )
            
            // Folder tab
            folderTab
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.75, blue: 0.32),
                            Color(red: 0.82, green: 0.65, blue: 0.22)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    folderTab
                        .stroke(
                            Color(red: 0.75, green: 0.58, blue: 0.15),
                            lineWidth: 1.5
                        )
                )
            
            // Inner highlight
            if !isOpen {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: 80, height: 60)
                    .offset(y: 8)
            }
            
            // Papers/documents inside (when open)
            if isOpen {
                documentsStack
            }
        }
        .frame(width: 100, height: 80)
        .animation(.easeInOut(duration: 0.3), value: isOpen)
    }
    
    private var folderShape: some Shape {
        FolderShape(isOpen: isOpen)
    }
    
    private var folderTab: some Shape {
        FolderTab()
    }
    
    private var documentsStack: some View {
        VStack(spacing: -2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 50 - CGFloat(index * 4), height: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                    .offset(x: CGFloat(index * 2), y: CGFloat(index * -1))
                    .opacity(isOpen ? 1 : 0)
                    .scaleEffect(isOpen ? 1 : 0.8)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: isOpen)
            }
        }
        .offset(y: 15)
    }
}

struct FolderShape: Shape {
    let isOpen: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 8
        let tabWidth: CGFloat = 30
        let tabHeight: CGFloat = 12
        
        if isOpen {
            // Open folder - more rectangular with slight perspective
            path.move(to: CGPoint(x: cornerRadius, y: tabHeight))
            path.addLine(to: CGPoint(x: width - cornerRadius, y: tabHeight))
            path.addQuadCurve(
                to: CGPoint(x: width, y: tabHeight + cornerRadius),
                control: CGPoint(x: width, y: tabHeight)
            )
            path.addLine(to: CGPoint(x: width - 5, y: height - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: width - 5 - cornerRadius, y: height),
                control: CGPoint(x: width - 5, y: height)
            )
            path.addLine(to: CGPoint(x: cornerRadius + 5, y: height))
            path.addQuadCurve(
                to: CGPoint(x: 5, y: height - cornerRadius),
                control: CGPoint(x: 5, y: height)
            )
            path.addLine(to: CGPoint(x: 0, y: tabHeight + cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: tabHeight),
                control: CGPoint(x: 0, y: tabHeight)
            )
        } else {
            // Closed folder - traditional folder shape
            path.move(to: CGPoint(x: cornerRadius, y: tabHeight))
            path.addLine(to: CGPoint(x: tabWidth, y: tabHeight))
            path.addLine(to: CGPoint(x: tabWidth + 8, y: 0))
            path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: width, y: cornerRadius),
                control: CGPoint(x: width, y: 0)
            )
            path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: width - cornerRadius, y: height),
                control: CGPoint(x: width, y: height)
            )
            path.addLine(to: CGPoint(x: cornerRadius, y: height))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: height - cornerRadius),
                control: CGPoint(x: 0, y: height)
            )
            path.addLine(to: CGPoint(x: 0, y: tabHeight + cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: tabHeight),
                control: CGPoint(x: 0, y: tabHeight)
            )
        }
        
        path.closeSubpath()
        return path
    }
}

struct FolderTab: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let tabWidth: CGFloat = 35
        let tabHeight: CGFloat = 12
        let cornerRadius: CGFloat = 4
        
        path.move(to: CGPoint(x: cornerRadius, y: tabHeight))
        path.addLine(to: CGPoint(x: tabWidth - 8, y: tabHeight))
        path.addLine(to: CGPoint(x: tabWidth, y: 0))
        path.addLine(to: CGPoint(x: tabWidth + 8, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: tabWidth + 8 + cornerRadius, y: cornerRadius),
            control: CGPoint(x: tabWidth + 8 + cornerRadius, y: 0)
        )
        path.addLine(to: CGPoint(x: tabWidth + 8 + cornerRadius, y: tabHeight))
        path.addLine(to: CGPoint(x: cornerRadius, y: tabHeight))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: tabHeight - cornerRadius),
            control: CGPoint(x: 0, y: tabHeight)
        )
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        path.addLine(to: CGPoint(x: tabWidth - 8, y: 0))
        path.addLine(to: CGPoint(x: tabWidth, y: tabHeight))
        path.addLine(to: CGPoint(x: cornerRadius, y: tabHeight))
        
        return path
    }
}
