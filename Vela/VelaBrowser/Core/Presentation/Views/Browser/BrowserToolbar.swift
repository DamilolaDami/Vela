import SwiftUI

struct BrowserToolbar: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Navigation buttons
            HStack(spacing: 8) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(canGoBack ? .primary : .secondary)
                }
                .disabled(!canGoBack)
                .buttonStyle(ArcNavigationButtonStyle())
                
                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(canGoForward ? .primary : .secondary)
                }
                .disabled(!canGoForward)
                .buttonStyle(ArcNavigationButtonStyle())
                
                Button(action: refresh) {
                    Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(ArcNavigationButtonStyle())
            }
            
            // Address bar
            AddressBar(
                text: $viewModel.addressText, // Bind to viewModel
                isEditing: $viewModel.isEditing, // Bind to viewModel
                onCommit: viewModel.navigateToURL, // Call viewModel method
                currentURL: viewModel.currentTab?.url
            )
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: addBookmark) {
                    Image(systemName: isBookmarked ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isBookmarked ? .red : .primary)
                }
                .buttonStyle(ArcNavigationButtonStyle())
                
                Button(action: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(ArcNavigationButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Rectangle())
    }
    
    // MARK: - Computed Properties
    
    private var canGoBack: Bool {
        viewModel.currentTab?.canGoBack ?? false
    }
    
    private var canGoForward: Bool {
        viewModel.currentTab?.canGoForward ?? false
    }
    
    private var isBookmarked: Bool {
        // TODO: Check if current URL is bookmarked
        false
    }
    
    // MARK: - Actions
    
    private func goBack() {
        // TODO: Implement navigation back
    }
    
    private func goForward() {
        // TODO: Implement navigation forward
    }
    
    private func refresh() {
        if viewModel.isLoading {
            // TODO: Stop loading
        } else {
            // TODO: Reload page
        }
    }
    
    private func addBookmark() {
        // TODO: Add/remove bookmark
    }
    
    private func shareURL() {
        // TODO: Share current URL
    }
}

// MARK: - Custom Button Style

struct ArcNavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear)
            )
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
