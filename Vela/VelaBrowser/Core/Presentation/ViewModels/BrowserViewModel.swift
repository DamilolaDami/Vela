
import Foundation
import Combine
import SwiftUI
import WebKit

@MainActor
class BrowserViewModel: ObservableObject {
    @Published var spaces: [Space] = []
    @Published var currentSpace: Space?
    @Published var currentTab: Tab?
    @Published var tabs: [Tab] = []
    @Published var isLoading = false
    @Published var addressText = ""
    @Published var isEditing = false
    @Published var sidebarCollapsed: Bool = false
    
    private let createTabUseCase: CreateTabUseCaseProtocol
    private let tabRepository: TabRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        createTabUseCase: CreateTabUseCaseProtocol,
        tabRepository: TabRepositoryProtocol
    ) {
        self.createTabUseCase = createTabUseCase
        self.tabRepository = tabRepository
        setupInitialState()
        setupBindings()
    }
    
    private func setupInitialState() {
        let defaultSpace = Space(name: "Personal", color: .blue)
        spaces = [defaultSpace]
        currentSpace = defaultSpace
        loadTabs()
    }
    
    private func setupBindings() {
        $currentTab
            .sink { [weak self] tab in
                guard let self = self, !self.isEditing else { return }
                self.addressText = tab?.url?.absoluteString ?? ""
            }
            .store(in: &cancellables)
    }
    
    func createNewTab(with url: URL? = nil) {
        self.currentTab = nil
        createTabUseCase.execute(url: url, in: currentSpace?.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to create tab: \(error)")
                    }
                },
                receiveValue: { [weak self] tab in
                    // Create a new WKWebView for this tab
                    let configuration = WKWebViewConfiguration()
                    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
                    configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
                    configuration.preferences.isFraudulentWebsiteWarningEnabled = false
                    configuration.applicationNameForUserAgent = "Safari/605.1.15"
                    
                    let webView = WKWebView(frame: .zero, configuration: configuration)
                    webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
                    
                    tab.webView = webView // Assign the WKWebView to the tab
                    self?.tabs.append(tab)
                    self?.currentTab = tab
                    print("Done")
                }
            )
            .store(in: &cancellables)
    }
    
    func selectTab(_ tab: Tab) {
        print("Selecting tab: \(tab.url?.absoluteString ?? "nil")")
        currentTab = tab
     
    }
    
    func closeTab(_ tab: Tab) {
        tabs.removeAll { $0.id == tab.id }
        if currentTab?.id == tab.id {
            currentTab = tabs.first
        }
    }
    
    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            sidebarCollapsed.toggle()
        }
    }
    
    func navigateToURL() {
        guard !addressText.isEmpty else { return }

        isLoading = true
        let urlPattern = "^(https?\\:\\/\\/)?([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}(\\/.*)?$"
        let isURL = addressText.range(of: urlPattern, options: .regularExpression) != nil

        var url: URL?
        if isURL {
            let urlString = addressText.hasPrefix("http") ? addressText : "https://\(addressText)"
            url = URL(string: urlString)
        } else {
            let query = addressText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? addressText
            let searchURLString = "https://www.google.com/search?q=\(query)"
            url = URL(string: searchURLString)
        }

        if let url = url {
            if let tab = currentTab, let webView = tab.webView {
                // Update only the current tab's state
                tab.url = url
                tab.title = addressText // Set initial title, will be updated by WebViewCoordinator
                webView.load(URLRequest(url: url))
            } else {
                createNewTab(with: url)
            }
        }

        isEditing = false
        isLoading = false
    }
    
    private func loadTabs() {
        guard let spaceId = currentSpace?.id else { return }
        
        tabRepository.getBySpace(spaceId: spaceId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] tabs in
                    print("\(tabs.count)")
                    self?.tabs = tabs
                    self?.currentTab = tabs.first
                }
            )
            .store(in: &cancellables)
    }
}
