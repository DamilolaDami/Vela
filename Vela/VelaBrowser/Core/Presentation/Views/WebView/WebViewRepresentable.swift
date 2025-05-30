import SwiftUI
import WebKit

struct WebViewRepresentable: NSViewRepresentable {
    @ObservedObject var tab: Tab
    @Binding var isLoading: Bool
    @Binding var estimatedProgress: Double

    func makeNSView(context: Context) -> WKWebView {
        let webView: WKWebView
        if let existingWebView = tab.webView {
            webView = existingWebView
        } else {
            let configuration = WKWebViewConfiguration()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            configuration.preferences.isFraudulentWebsiteWarningEnabled = false
            configuration.applicationNameForUserAgent = "Safari/605.1.15"

            webView = WKWebView(frame: .zero, configuration: configuration)
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
            tab.webView = webView
        }

        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        #if DEBUG
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        // Add observers using the safe method
        context.coordinator.addObservers(to: webView)

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update the coordinator's parent reference
        context.coordinator.parent = self
        
        // Only load if the URL is different and valid
        if let url = tab.url, nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
        
        // Update binding values to match current webview state
        DispatchQueue.main.async {
            isLoading = nsView.isLoading
            estimatedProgress = nsView.estimatedProgress
        }
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self, tab: tab)
    }
}
