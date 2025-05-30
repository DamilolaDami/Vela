import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: WebViewRepresentable? 
    weak var tab: Tab? // Keep 'weak' since Tab is a class

    init(_ parent: WebViewRepresentable, tab: Tab) {
        self.parent = parent
        self.tab = tab
        super.init() // Ensure NSObject initializer is called
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView, webView == tab?.webView else { return }

        DispatchQueue.main.async {
            switch keyPath {
            case #keyPath(WKWebView.isLoading):
                self.tab?.isLoading = webView.isLoading
                if let isLoading = self.parent?.isLoading, isLoading != webView.isLoading {
                    self.parent?.isLoading = webView.isLoading
                }

            case #keyPath(WKWebView.estimatedProgress):
                if let estimatedProgress = self.parent?.estimatedProgress, estimatedProgress != webView.estimatedProgress {
                    self.parent?.estimatedProgress = webView.estimatedProgress
                }

            case #keyPath(WKWebView.title):
                if let newTitle = webView.title, self.tab?.title != newTitle {
                    self.tab?.title = newTitle.isEmpty ? "Untitled" : newTitle
                }

            case #keyPath(WKWebView.url):
                if let newURL = webView.url, self.tab?.url != newURL {
                    self.tab?.url = newURL
                }

            default:
                break
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.tab?.isLoading = true
            self.parent?.isLoading = true
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.tab?.isLoading = false
            self.parent?.isLoading = false
            self.parent?.estimatedProgress = 1.0
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.tab?.isLoading = false
            self.parent?.isLoading = false
            self.parent?.estimatedProgress = 0
        }
        print("Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.tab?.isLoading = false
            self.parent?.isLoading = false
            self.parent?.estimatedProgress = 0
        }
        print("Provisional navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    deinit {
        tab?.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
        tab?.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        tab?.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        tab?.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        print("WebViewCoordinator deinit for tab: \(tab?.url?.absoluteString ?? "nil")")
    }
}
