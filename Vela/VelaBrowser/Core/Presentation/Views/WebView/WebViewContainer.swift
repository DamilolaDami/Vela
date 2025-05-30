import SwiftUI
import WebKit

struct WebViewContainer: View {
    let tab: Tab
    @State private var webView: WKWebView?
    @State private var isLoading = false
    @State private var estimatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            WebViewRepresentable(
                tab: tab,
                webView: $webView,
                isLoading: $isLoading,
                estimatedProgress: $estimatedProgress
            )
            
            // Loading indicator
            if isLoading {
                VStack {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
            }
            
            // Progress bar
            if estimatedProgress > 0 && estimatedProgress < 1 {
                VStack {
                    ProgressView(value: estimatedProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1, y: 0.5)
                    Spacer()
                }
            }
        }
        .onAppear {
            loadURL()
        }
        .onChange(of: tab.url) { _ in
            loadURL()
        }
    }
    
    private func loadURL() {
        guard let url = tab.url else { return }
        
        DispatchQueue.main.async {
            let request = URLRequest(url: url)
            webView?.load(request)
        }
    }
}
