import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var hasInitialLoad = false

    var body: some View {
        ZStack {
            if let currentTab = viewModel.currentTab, let webView = currentTab.webView {
                WebViewRepresentable(
                    tab: currentTab,
                    isLoading: $viewModel.isWebsiteLoading,
                    estimatedProgress: $viewModel.estimatedProgress,
                    browserViewModel: viewModel
                )
                .id(currentTab.id)
            }
        }
        .onAppear {
            if !hasInitialLoad {
                loadInitialURL()
                hasInitialLoad = true
            }
        }
        .onChange(of: viewModel.currentTab?.id) { _, _ in
            hasInitialLoad = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadInitialURL()
                hasInitialLoad = true
            }
        }
    }

    private func loadInitialURL() {
        guard let currentTab = viewModel.currentTab,
              let webView = currentTab.webView,
              let url = currentTab.url else { return }

        if webView.url != url {
            DispatchQueue.main.async {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
}
