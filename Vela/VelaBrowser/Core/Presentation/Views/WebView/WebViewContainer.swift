import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var noteBoardViewModel: NoteBoardViewModel
    @State private var hasInitialLoad = false

    var body: some View {
        ZStack {
            if let currentTab = viewModel.currentTab, let webView = currentTab.webView {
                WebViewRepresentable(
                    tab: currentTab,
                    isLoading: $viewModel.isWebsiteLoading,
                    estimatedProgress: $viewModel.estimatedProgress,
                    browserViewModel: viewModel,
                    noteViewModel: noteBoardViewModel
                
                )
                .id(currentTab.id)
                
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
        .onChange(of: viewModel.currentTab?.id) { oldId, newId in
          
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

class AudioObservingWebView: WKWebView {
    @objc dynamic var isPlayingAudioPrivate: Bool = false

    override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)

        if key == "_isPlayingAudio" {
            if let value = try? self.value(forKey: "_isPlayingAudio") as? Bool {
                isPlayingAudioPrivate = value
            
            }
        }
    }
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "_isPlayingAudio" {
            if let value = (change?[.newKey] as? NSNumber)?.boolValue {
                isPlayingAudioPrivate = value
              
            }
        } else {
            // Always call super for unhandled keys
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func startObservingAudio() {
        addObserver(self, forKeyPath: "_isPlayingAudio", options: [.new, .initial], context: nil)
    }

    func stopObservingAudio() {
        removeObserver(self, forKeyPath: "_isPlayingAudio")
    }

    deinit {
        stopObservingAudio()
    }
}
