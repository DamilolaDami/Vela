import Foundation
import WebKit

/// View model exposing loading information for a tab's web view.
final class WebViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0

    let tab: Tab
    private var coordinator: WebViewCoordinator!

    init(tab: Tab) {
        self.tab = tab
        self.coordinator = WebViewCoordinator(tab: tab, parent: self)
    }

    func load(url: URL) {
        tab.webView.load(URLRequest(url: url))
    }
}
