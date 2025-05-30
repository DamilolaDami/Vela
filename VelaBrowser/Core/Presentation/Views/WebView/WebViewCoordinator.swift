import WebKit

/// Coordinator that observes changes on a WKWebView and updates its tab.
final class WebViewCoordinator: NSObject {
    weak var parent: WebViewModel?
    weak var tab: Tab?

    init(tab: Tab, parent: WebViewModel?) {
        self.tab = tab
        self.parent = parent
        super.init()

        tab.webView.navigationDelegate = self
        tab.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        tab.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        tab.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        tab.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
    }

    deinit {
        if let webView = tab?.webView {
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView, let tab = tab, webView == tab.webView else { return }

        // Capture values to avoid race conditions if the selected tab changes
        let targetTab = tab
        let parent = self.parent

        DispatchQueue.main.async {
            switch keyPath {
            case #keyPath(WKWebView.isLoading):
                targetTab.isLoading = webView.isLoading
                parent?.isLoading = webView.isLoading
            case #keyPath(WKWebView.estimatedProgress):
                targetTab.estimatedProgress = webView.estimatedProgress
                parent?.estimatedProgress = webView.estimatedProgress
            case #keyPath(WKWebView.title):
                if let newTitle = webView.title, targetTab.title != newTitle {
                    targetTab.title = newTitle.isEmpty ? "Untitled" : newTitle
                }
            case #keyPath(WKWebView.url):
                if let newURL = webView.url, targetTab.url != newURL {
                    targetTab.url = newURL
                }
            default:
                break
            }
        }
    }
}

extension WebViewCoordinator: WKNavigationDelegate {}
