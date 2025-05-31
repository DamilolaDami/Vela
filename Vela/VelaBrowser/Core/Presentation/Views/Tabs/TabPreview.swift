
import SwiftUI
import WebKit

// MARK: - Tab Preview View
struct TabPreview: View {
    let tab: Tab
    @State private var previewImage: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 320, height: 180)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let previewImage = previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 320, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("Preview not available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Tab information
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    // Favicon
                    TabIcon(tab: tab)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Title
                        Text(tab.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // URL
                        if let url = tab.url {
                            Text(url.absoluteString)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                
                // Additional info row
                HStack {
                    // Loading indicator
                    if tab.isLoading {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Pin indicator
                    if tab.isPinned {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("Pinned")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .frame(width: 344)
        .onAppear {
            captureTabPreview()
        }
    }
    
    private func captureTabPreview() {
        guard let webView = tab.webView else {
            isLoading = false
            return
        }
        
        // Capture the web view as an image
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: 0, y: 0, width: webView.bounds.width, height: webView.bounds.height)
        
        webView.takeSnapshot(with: config) { image, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let image = image {
                    self.previewImage = image
                }
            }
        }
    }
}
