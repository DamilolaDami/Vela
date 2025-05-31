import SwiftUI
import WebKit

struct WebViewRepresentable: NSViewRepresentable {
    @ObservedObject var tab: Tab
    @Binding var isLoading: Bool
    @Binding var estimatedProgress: Double
    let browserViewModel: BrowserViewModel // Add this reference

  
    func makeNSView(context: Context) -> WKWebView {
        let webView: WKWebView

        if let existingWebView = tab.webView as? AudioObservingWebView {
            webView = existingWebView
            existingWebView.startObservingAudio()
        } else {
            let configuration = WKWebViewConfiguration()
            
            // Enable JavaScript and full-screen APIs
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            configuration.preferences.isFraudulentWebsiteWarningEnabled = false
            
            // Enable media playback features
            configuration.allowsAirPlayForMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = [] // Allow autoplay and full-screen without user gesture
            
            
            // Additional settings for macOS
            if #available(macOS 11.3, *) {
                configuration.upgradeKnownHostsToHTTPS = false
            }

            let audioWebView = AudioObservingWebView(frame: .zero, configuration: configuration)
            audioWebView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
            audioWebView.allowsBackForwardNavigationGestures = true
            audioWebView.startObservingAudio()

            tab.setWebView(audioWebView)
            webView = audioWebView
        }

        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        #if DEBUG
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        context.coordinator.addObservers(to: webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.addObservers(to: nsView)
        
        if let url = tab.url {
            let shouldLoad = nsView.url != url ||
                           (nsView.url == nil && !nsView.isLoading) ||
                           nsView.url?.absoluteString != url.absoluteString
            
            if shouldLoad {
                context.coordinator.loadURL(url, in: nsView)
            }
        }
        
        DispatchQueue.main.async {
            self.isLoading = nsView.isLoading
            self.estimatedProgress = nsView.estimatedProgress
        }
    }

    func makeCoordinator() -> WebViewCoordinator {
        let coordinator = WebViewCoordinator(self, tab: tab)
        coordinator.browserViewModel = browserViewModel
        return coordinator
    }
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: WebViewCoordinator) {
        coordinator.removeObservers(from: nsView)
        nsView.stopLoading()
    }
    
}
