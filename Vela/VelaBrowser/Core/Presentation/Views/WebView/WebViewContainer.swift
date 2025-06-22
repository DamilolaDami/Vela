import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var noteBoardViewModel: NoteBoardViewModel
    @ObservedObject var suggestionViewModel: AddressBarViewModel
    @State private var hasInitialLoad = false

    var body: some View {
        ZStack {
            if let currentTab = viewModel.currentTab, let webView = currentTab.webView {
                WebViewRepresentable(
                    tab: currentTab,
                    isLoading: $viewModel.isWebsiteLoading,
                    estimatedProgress: $viewModel.estimatedProgress,
                    browserViewModel: viewModel,
                    suggestionViewModel: suggestionViewModel,
                    noteViewModel: noteBoardViewModel
                
                )
                .id(currentTab.id)
                
            }else{
                Text("no webview")
            }
        }
        .overlay(alignment: .topTrailing, content: {
            Group {
                if let tab = viewModel.currentTab, tab.isZooming {
                    ZoomIndicator(zoomLevel: tab.zoomLevel, isZooming: tab.isZooming)
                        .padding()
                }
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
           
            if !hasInitialLoad {
                loadInitialURL()
                hasInitialLoad = true
            }
        }
//        .onChange(of: viewModel.currentTab?.id) { oldId, newId in
//          
//            hasInitialLoad = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                loadInitialURL()
//                hasInitialLoad = true
//            }
//        }
    }

    private func loadInitialURL() {
        guard let currentTab = viewModel.currentTab,
              let webView = currentTab.webView,
              let url = currentTab.url else {
            print("🚫 loadInitialURL failed: tab=\(String(describing: viewModel.currentTab)), webView=\(String(describing: viewModel.currentTab?.webView)), url=\(String(describing: viewModel.currentTab?.url))")
            return
        }
        if webView.url != url {
            DispatchQueue.main.async {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
}


import WebKit

