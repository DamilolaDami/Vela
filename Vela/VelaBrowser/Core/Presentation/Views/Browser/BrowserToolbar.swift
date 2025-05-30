import SwiftUI

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
                .buttonStyle(ArcNavigationButtonStyle(isEnabled: canGoBack))
                
                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(canGoForward ? .primary : .secondary)
                }
                .disabled(!canGoForward)
                .buttonStyle(ArcNavigationButtonStyle(isEnabled: canGoForward))
                
                Button(action: refresh) {
                    Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(ArcNavigationButtonStyle(isEnabled: true))
            }
            
            // Address bar
            AddressBar(
                text: $viewModel.addressText,
                isEditing: $viewModel.isEditing,
                onCommit: viewModel.navigateToURL,
                currentURL: viewModel.currentTab?.url
            )
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: copyURL) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(ArcNavigationButtonStyle(isEnabled: hasURL))
                .disabled(!hasURL)
                
                Button(action: addBookmark) {
                    Image(systemName: isBookmarked ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isBookmarked ? .red : .primary)
                }
                .buttonStyle(ArcNavigationButtonStyle(isEnabled: hasURL, isSpecial: isBookmarked))
                .disabled(!hasURL)
                
                Button(action: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(ArcNavigationButtonStyle(isEnabled: hasURL))
                .disabled(!hasURL)
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
    
    private var hasURL: Bool {
        viewModel.currentTab?.url != nil
    }
    
    // MARK: - Actions
    
    private func goBack() {
        // TODO: Implement navigation back
      //  viewModel.currentTab?.goBack()
    }
    
    private func goForward() {
        // TODO: Implement navigation forward
       // viewModel.currentTab?.goForward()
    }
    
    private func refresh() {
        if viewModel.isLoading {
            // TODO: Stop loading
         //   viewModel.currentTab?.stopLoading()
        } else {
            // TODO: Reload page
           // viewModel.currentTab?.reload()
        }
    }
    
    private func copyURL() {
        guard let url = viewModel.currentTab?.url else { return }
        
        #if os(iOS)
        UIPasteboard.general.string = url.absoluteString
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #endif
        
        NotificationService.shared.showSuccess("URL copied")
    }
    
    private func addBookmark() {
        // TODO: Add/remove bookmark
        if isBookmarked {
            print("Bookmark removed")
        } else {
            print("Bookmark added")
        }
    }
    
    private func shareURL() {
        guard let url = viewModel.currentTab?.url else { return }
        
        #if os(iOS)
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
        #elseif os(macOS)
        let sharingService = NSSharingService(named: .sendViaAirDrop)
        sharingService?.perform(withItems: [url])
        
        #endif
    }
}

// MARK: - Updated Button Style with Subtle Background

struct ArcNavigationButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isSpecial: Bool
    
    init(isEnabled: Bool = true, isSpecial: Bool = false) {
        self.isEnabled = isEnabled
        self.isSpecial = isSpecial
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(buttonBackgroundColor(isPressed: configuration.isPressed))
                    .overlay(
                        Circle()
                            .stroke(buttonBorderColor, lineWidth: 0.5)
                    )
            )
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func buttonBackgroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return Color.primary.opacity(0.05)
        }
        
        if isSpecial {
            return isPressed ? Color.red.opacity(0.2) : Color.red.opacity(0.1)
        }
        
        if isPressed {
            return Color.primary.opacity(0.15)
        }
        
        return Color.primary.opacity(0.08)
    }
    
    private var buttonBorderColor: Color {
        if !isEnabled {
            return Color.primary.opacity(0.1)
        }
        
        if isSpecial {
            return Color.red.opacity(0.3)
        }
        
        return Color.primary.opacity(0.15)
    }
}

