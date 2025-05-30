import Foundation
import WebKit

/// Represents a single browser tab with its own WKWebView.
final class Tab: ObservableObject, Identifiable {
    let id: UUID = UUID()

    /// Current page title.
    @Published var title: String
    /// Current page URL.
    @Published var url: URL?
    /// Loading state of the associated web view.
    @Published var isLoading: Bool = false
    /// Progress of the current navigation.
    @Published var estimatedProgress: Double = 0

    /// Web view displaying this tab's content.
    let webView: WKWebView

    init(url: URL) {
        self.title = url.absoluteString
        self.url = url
        self.webView = WKWebView(frame: .zero)
    }
}
