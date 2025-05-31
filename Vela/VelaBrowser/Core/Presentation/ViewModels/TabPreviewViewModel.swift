//
//  TabPreviewManager.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI


class TabPreviewManager: ObservableObject {
    @Published var previewTab: Tab?
    @Published var previewPosition: CGPoint = .zero
    @Published var showPreview = false
    
    private var hoverTimer: Timer?
    private var hideTimer: Timer?
    private let hoverDelay: TimeInterval = 0.8 // Longer delay
    private let hideDelay: TimeInterval = 0.2 // Small delay before hiding
    
    func startHover(for tab: Tab, at position: CGPoint) {
        print("🐛 TabPreviewManager.startHover called for: \(tab.title)")
        
        // Cancel any pending hide operation
        hideTimer?.invalidate()
        hideTimer = nil
        
        // If we're already showing this tab, just update position
        if showPreview && previewTab?.id == tab.id {
            previewPosition = position
            return
        }
        
        // Cancel any existing timer
        hoverTimer?.invalidate()
        
        // Start new timer
        hoverTimer = Timer.scheduledTimer(withTimeInterval: hoverDelay, repeats: false) { _ in
            print("🐛 Timer fired, showing preview")
            DispatchQueue.main.async {
                self.previewTab = tab
                self.previewPosition = position
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showPreview = true
                }
                print("🐛 Preview should now be visible: \(self.showPreview)")
            }
        }
    }
    
    func endHover() {
        print("🐛 TabPreviewManager.endHover called")
        
        // Cancel the show timer
        hoverTimer?.invalidate()
        hoverTimer = nil
        
        // Add a small delay before hiding to prevent flicker
        hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.showPreview = false
                }
                
                // Clear preview data after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.previewTab = nil
                }
            }
        }
    }
    
    func updatePosition(_ position: CGPoint) {
        previewPosition = position
    }
}
