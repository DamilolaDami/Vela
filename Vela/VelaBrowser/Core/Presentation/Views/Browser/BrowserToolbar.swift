import SwiftUI


struct BrowserToolbar: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var bookmarkViewModel: BookmarkViewModel
    @ObservedObject var suggestionVM: SuggestionViewModel
    var body: some View {
        HStack(spacing: 12) {
            // Navigation buttons
            HStack(spacing: 8) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(canGoBack ? .primary : .gray)
                }
                .disabled(!canGoBack)
                .buttonStyle(ArcNavigationButtonStyle(isEnabled: canGoBack))
                
                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(canGoForward ? .primary : .gray)
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
                currentURL: viewModel.currentTab?.url,
                suggestionVM: suggestionVM
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
                
                Button(action: toggleBookmark) {
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
        .sheet(isPresented: $bookmarkViewModel.isShowingAddBookmarkSheet) {
            if let url = viewModel.currentTab?.url {
                AddBookmarkSheet(
                    bookmarkViewModel: bookmarkViewModel,
                    url: url,
                    title: viewModel.currentTab?.title
                )
            } else {
                AddBookmarkSheet(bookmarkViewModel: bookmarkViewModel)
            }
        }
       
       
    }
    
    // MARK: - Computed Properties
    
    private var canGoBack: Bool {
        viewModel.currentTab?.canGoBack ?? false
    }
   
    
    private var canGoForward: Bool {
        viewModel.currentTab?.canGoForward ?? false
    }
    
    private var isBookmarked: Bool {
        guard let url = viewModel.currentTab?.url else { return false }
        return bookmarkViewModel.bookmarks.contains { bookmark in
            bookmark.url?.absoluteString == url.absoluteString
        }
    }
    
    private var hasURL: Bool {
        viewModel.currentTab?.url != nil
    }
    
    // MARK: - Actions
    
    func goBack() {
        print("Attempting to go back. Can go back: \(viewModel.currentTab?.webView?.canGoBack ?? false)")
        viewModel.currentTab?.webView?.goBack()
    }

    func goForward() {
        print("Attempting to go forward. Can go forward: \(viewModel.currentTab?.webView?.canGoForward ?? false)")
        viewModel.currentTab?.webView?.goForward()
    }
    
    private func refresh() {
        if viewModel.isLoading {
            viewModel.stopLoading()
        } else {
            viewModel.reload()
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
    
    private func toggleBookmark() {
        guard let url = viewModel.currentTab?.url else { return }
        
        if isBookmarked {
            removeBookmark(url: url)
        } else {
            showAddBookmarkSheet(url: url)
        }
    }
    
    private func showAddBookmarkSheet(url: URL) {
        // Get page title from current tab or use URL as fallback
        let title = viewModel.currentTab?.title ?? url.host ?? url.absoluteString
        
        // Set up the bookmark view model for adding
        bookmarkViewModel.bookmarkToEdit = nil
        bookmarkViewModel.isShowingAddBookmarkSheet = true
    }
    
    private func removeBookmark(url: URL) {
        guard let bookmark = bookmarkViewModel.bookmarks.first(where: {
            $0.url?.absoluteString == url.absoluteString
        }) else { return }
        
        bookmarkViewModel.deleteBookmark(bookmark)
        NotificationService.shared.showSuccess("Bookmark removed")
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

