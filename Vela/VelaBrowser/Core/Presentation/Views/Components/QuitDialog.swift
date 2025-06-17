//
//  QuitManager.swift
//  Vela
//
//  Created by damilola on 6/14/25.
//

import Foundation
import SwiftUI

class QuitManager: ObservableObject {
    @Published var showingQuitDialog = false
    @Published var dontAskAgain = false
    var quitConfirmHandler: (() -> Void)?
    
    func showQuitDialog() {
        showingQuitDialog = true
    }
    
    func confirmQuit() {
        if dontAskAgain {
            // Save the preference to UserDefaults
            UserDefaults.standard.set(true, forKey: "DontAskOnQuit")
        }
        
        showingQuitDialog = false
        
        // Call the handler to actually quit through the app delegate
        quitConfirmHandler?()
    }
    
    func cancelQuit() {
        showingQuitDialog = false
    }
}


// MARK: - Custom Quit Dialog
struct QuitDialog: View {
    @EnvironmentObject var quitManager: QuitManager
    @State private var dontAskAgain = false
    @State private var isHoveringCancel = false
    @State private var isHoveringQuit = false
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon and Header
            VStack(spacing: 16) {
                // Enhanced app icon with subtle glow effect
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Image("1024-mac")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 6) {
                    Text("Quit Vela?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Your work will be saved automatically before closing.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Don't ask again option with improved styling
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dontAskAgain.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: dontAskAgain ? "checkmark.square.fill" : "square")
                            .foregroundColor(dontAskAgain ? .blue : .secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Don't ask me again")
                            .font(.callout)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                
                Spacer()
            }
            
            // Action buttons with enhanced styling
            HStack(spacing: 12) {
                // Cancel button
                Button("Cancel") {
                    quitManager.cancelQuit()
                }
                .buttonStyle(.plain)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(minWidth: 80)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHoveringCancel ? Color.primary.opacity(0.08) : Color.primary.opacity(0.05))
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .scaleEffect(isHoveringCancel ? 1.02 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveringCancel = hovering
                    }
                }
                
                // Quit button with enhanced styling
                Button("Quit Vela") {
                    quitManager.dontAskAgain = dontAskAgain
                    quitManager.confirmQuit()
                }
                .buttonStyle(.plain)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(minWidth: 100)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: isHoveringQuit ? [Color.red.opacity(0.9), Color.red] : [Color.red, Color.red.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: isHoveringQuit ? 4 : 2, y: isHoveringQuit ? 2 : 1)
                )
                .scaleEffect(isHoveringQuit ? 1.02 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveringQuit = hovering
                    }
                }
            }
        }
        .padding(28)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            // Check if user previously selected "Don't ask again"
            if UserDefaults.standard.bool(forKey: "DontAskOnQuit") {
                quitManager.confirmQuit()
            }
        }
        .onKeyPress(.escape) {
            quitManager.cancelQuit()
            return .handled
        }
        .onKeyPress(.return) {
            quitManager.dontAskAgain = dontAskAgain
            quitManager.confirmQuit()
            return .handled
        }
    }
}
