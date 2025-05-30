import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: WebViewRepresentable?
    weak var tab: Tab? // Keep 'weak' since Tab is a class
    private var isObserving = false

    init(_ parent: WebViewRepresentable, tab: Tab) {
        self.parent = parent
        self.tab = tab
        super.init() // Ensure NSObject initializer is called
    }
    
    func addObservers(to webView: WKWebView) {
        guard !isObserving else { return }
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
        
        isObserving = true
    }
    
    func removeObservers(from webView: WKWebView) {
        guard isObserving else { return }
        
        do {
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        } catch {
            print("Error removing observers: \(error)")
        }
        
        isObserving = false
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView,
              let tab = self.tab,
              webView == tab.webView else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            
            switch keyPath {
            case #keyPath(WKWebView.isLoading):
                tab.isLoading = webView.isLoading
                if let parent = self.parent {
                    parent.isLoading = webView.isLoading
                }

            case #keyPath(WKWebView.estimatedProgress):
                if let parent = self.parent {
                    parent.estimatedProgress = webView.estimatedProgress
                }

            case #keyPath(WKWebView.title):
                if let newTitle = webView.title, tab.title != newTitle {
                    tab.title = newTitle.isEmpty ? "Untitled" : newTitle
                }

            case #keyPath(WKWebView.url):
                if let newURL = webView.url, tab.url != newURL {
                    tab.url = newURL
                }

            default:
                break
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            tab.isLoading = true
            self.parent?.isLoading = true
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            tab.isLoading = false
            self.parent?.isLoading = false
            self.parent?.estimatedProgress = 1.0
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            tab.isLoading = false
            self.parent?.isLoading = false
            self.parent?.estimatedProgress = 0
        }
        print("Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tab = self.tab else { return }
            tab.isLoading = false
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
        if let webView = tab?.webView {
            removeObservers(from: webView)
        }
        print("WebViewCoordinator deinit for tab: \(tab?.url?.absoluteString ?? "nil")")
    }
}
