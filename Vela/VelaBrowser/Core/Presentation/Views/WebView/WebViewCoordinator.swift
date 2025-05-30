import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: WebViewRepresentable
    
    init(_ parent: WebViewRepresentable) {
        self.parent = parent
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView else { return }
        
        DispatchQueue.main.async {
            switch keyPath {
            case #keyPath(WKWebView.isLoading):
                self.parent.isLoading = webView.isLoading
                
            case #keyPath(WKWebView.estimatedProgress):
                self.parent.estimatedProgress = webView.estimatedProgress
                
            case #keyPath(WKWebView.title):
                // TODO: Update tab title
                break
                
            case #keyPath(WKWebView.url):
                // TODO: Update tab URL
                break
                
            default:
                break
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.parent.isLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.parent.isLoading = false
            self.parent.estimatedProgress = 1.0
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.parent.isLoading = false
            self.parent.estimatedProgress = 0
        }
        print("Navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.parent.isLoading = false
            self.parent.estimatedProgress = 0
        }
        print("Provisional navigation failed: \(error.localizedDescription)")
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle new window requests by loading in current webview
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
    
    deinit {
        // Clean up observers
        parent.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
        parent.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        parent.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        parent.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
    }
}
