import SwiftUI
import AppKit

struct TabPreviewOverlay: View {
    @ObservedObject var previewManager: TabPreviewManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if previewManager.showPreview, let tab = previewManager.previewTab {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            TabIcon(tab: tab)
                                .scaleEffect(0.8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tab.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                
                                if let url = tab.url {
                                    Text(url.host ?? "")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        
                        // Preview content area
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 280, height: 160)
                            .overlay(
                                VStack {
                                    Image(systemName: "globe")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                    Text("Tab Preview")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .padding(12)
                    .frame(width: 300)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    .position(calculatePreviewPosition(geometry: geometry))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1000)
                    .onAppear {
                        print("🐛 TabPreviewOverlay appeared at position: \(calculatePreviewPosition(geometry: geometry))")
                        print("🐛 Original preview position: \(previewManager.previewPosition)")
                        print("🐛 Geometry frame: \(geometry.frame(in: .global))")
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .coordinateSpace(name: "TabPreviewOverlay")
    }
    
    // Calculate the preview position with proper constraints
    private func calculatePreviewPosition(geometry: GeometryProxy) -> CGPoint {
        let previewWidth: CGFloat = 300
        let previewHeight: CGFloat = 200
        let margin: CGFloat = 20
        let verticalOffset: CGFloat = 30 // Distance below the tab
        
        // Get the target position from the preview manager (this should be in global coordinates)
        let targetPosition = previewManager.previewPosition
        
        // Convert global coordinates to local coordinates within this overlay
        let overlayGlobalFrame = geometry.frame(in: .global)
        let localX = targetPosition.x - overlayGlobalFrame.minX
        let localY = targetPosition.y - overlayGlobalFrame.minY + verticalOffset
        
        // Constrain horizontally within the overlay bounds
        let minX = previewWidth / 2 + margin
        let maxX = geometry.size.width - previewWidth / 2 - margin
        let constrainedX = max(minX, min(localX, maxX))
        
        // Constrain vertically within the overlay bounds
        let minY = previewHeight / 2 + margin
        let maxY = geometry.size.height - previewHeight / 2 - margin
        let constrainedY = max(minY, min(localY, maxY))
        
        print("🐛 Position calculation:")
        print("   Target (global): \(targetPosition)")
        print("   Overlay frame (global): \(overlayGlobalFrame)")
        print("   Local position: (\(localX), \(localY))")
        print("   Constrained: (\(constrainedX), \(constrainedY))")
        
        return CGPoint(x: constrainedX, y: constrainedY)
    }
}

// Alternative approach using a more direct positioning method
struct TabPreviewOverlayV2: View {
    @ObservedObject var previewManager: TabPreviewManager
    
    var body: some View {
        ZStack {
            if previewManager.showPreview, let tab = previewManager.previewTab {
                previewContent(for: tab)
                    .position(calculateDirectPosition())
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1000)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func previewContent(for tab: Tab) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TabIcon(tab: tab)
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    
                    if let url = tab.url {
                        Text(url.host ?? "")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 280, height: 160)
                .overlay(
                    VStack {
                        Image(systemName: "globe")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("Tab Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
        .padding(12)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
    
    private func calculateDirectPosition() -> CGPoint {
        // Use the mouse location directly if needed
        let mouseLocation = NSEvent.mouseLocation
        let screenHeight = NSScreen.main?.frame.height ?? 1000
        
        // Convert from AppKit coordinates (bottom-left origin) to SwiftUI coordinates (top-left origin)
        let swiftUIY = screenHeight - mouseLocation.y
        
        return CGPoint(
            x: mouseLocation.x,
            y: swiftUIY + 50 // Offset below cursor
        )
    }
}
