import Foundation
import Combine
import WebKit

class Tab: Identifiable, Equatable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var url: URL?
    @Published var favicon: Data?
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    var spaceId: UUID?
    let createdAt: Date
    @Published var lastAccessedAt: Date
    @Published var isPinned: Bool = false
    @Published var position: Int = 0
    @Published var scrollPosition: Double = 0
    var webView: WKWebView?
    private var cancellables = Set<AnyCancellable>()
    
    init(
        id: UUID = UUID(),
        title: String = "New Tab",
        url: URL? = nil,
        favicon: Data? = nil,
        isLoading: Bool = false,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        spaceId: UUID? = nil,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        isPinned: Bool = false,
        position: Int = 0
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.favicon = favicon
        self.isLoading = isLoading
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.spaceId = spaceId
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.isPinned = isPinned
        self.position = position
        
        setupFaviconObserver()
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        lhs.id == rhs.id
    }
    
    private func setupFaviconObserver() {
        $url
            .sink { [weak self] url in
                guard let self = self, let url = url else { return }
                self.loadFavicon(for: url)
            }
            .store(in: &cancellables)
    }
    
    // Public method to trigger favicon reload
    func reloadFavicon() {
        if let url = self.url {
            loadFavicon(for: url)
        }
    }
    
    private func loadFavicon(for url: URL) {
        // Reset favicon
        self.favicon = nil
        
        guard let webView = webView else { return }
        
        // Wait for the page to load before evaluating JavaScript
        let waitForLoadJS = """
        new Promise(resolve => {
            if (document.readyState === 'complete') {
                resolve();
            } else {
                window.addEventListener('load', resolve);
            }
        });
        """
        
        webView.evaluateJavaScript(waitForLoadJS) { [weak self] (_, _) in
            guard let self = self else { return }
            let faviconJS = """
            (function() {
                let link = document.querySelector('link[rel~="icon"]');
                return link ? link.href : null;
            })();
            """
            
            webView.evaluateJavaScript(faviconJS) { [weak self] (result, error) in
                guard let self = self else { return }
                
                if let faviconURLString = result as? String, let faviconURL = URL(string: faviconURLString) {
                    self.fetchFavicon(from: faviconURL)
                } else {
                    // Fallback to default favicon.ico
                    let faviconURL = url.deletingLastPathComponent().appendingPathComponent("favicon.ico")
                    self.fetchFavicon(from: faviconURL)
                }
            }
        }
    }
    
    private func fetchFavicon(from url: URL) {
        URLSession.shared.dataTaskPublisher(for: url)
            .map { Data($0.data) }
            .catch { _ in Just(Data()) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard !data.isEmpty else { return }
                self?.favicon = data
            }
            .store(in: &cancellables)
    }
}
