import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var isLoading = false
    @State private var estimatedProgress: Double = 0

    var body: some View {
        ZStack {
            if let currentTab = viewModel.currentTab, let webView = currentTab.webView {
                WebViewRepresentable(
                    tab: currentTab,
                    isLoading: $isLoading,
                    estimatedProgress: $estimatedProgress
                )
            }

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
        .onChange(of: viewModel.currentTab) { _, _ in
            loadURL()
        }
    }

    private func loadURL() {
        guard let currentTab = viewModel.currentTab,
              let webView = currentTab.webView,
              let url = currentTab.url else { return }

        DispatchQueue.main.async {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
