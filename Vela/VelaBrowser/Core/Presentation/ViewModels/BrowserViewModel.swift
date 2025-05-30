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
    @Published var isWebsiteLoading = false
    @Published var estimatedProgress: Double = 0
    @Published var downloads: [DownloadItem] = []
    @Published var isShowingCreateSpaceSheet: Bool = false
    @Published var isShowingSpaceInfoPopover = false
    @Published var spaceForInfoPopover: Space? = nil
    private let createTabUseCase: CreateTabUseCaseProtocol
    private let tabRepository: TabRepositoryProtocol
    private let spaceRepository: SpaceRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        createTabUseCase: CreateTabUseCaseProtocol,
        tabRepository: TabRepositoryProtocol,
        spaceRepository: SpaceRepositoryProtocol
    ) {
        self.createTabUseCase = createTabUseCase
        self.tabRepository = tabRepository
        self.spaceRepository = spaceRepository
        setupInitialState()
        setupBindings()
        setupKeyboardShortcuts()
    }
    
    private func setupInitialState() {
        spaceRepository.getAllSpaces()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load spaces: \(error)")
                    }
                },
                receiveValue: { [weak self] spaces in
                    guard let self = self else { return }
                    self.spaces = spaces.isEmpty ? [Space(name: "Personal", color: .blue, isDefault: true)] : spaces
                    self.currentSpace = self.spaces.first
                    self.loadTabs() // Load tabs for the initial space
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupBindings() {
        $currentTab
            .sink { [weak self] tab in
                guard let self = self, !self.isEditing else { return }
                self.addressText = tab?.url?.absoluteString ?? ""
                self.isLoading = tab?.isLoading ?? false
            }
            .store(in: &cancellables)
        
        $currentSpace
            .sink { [weak self] space in
                guard let self = self else { return }
                self.loadTabs()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Space Management
    
    func createSpace(_ space: Space) {
        spaceRepository.createSpace(space)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to create space: \(error)")
                    } else {
                        self?.loadSpaces()
                    }
                },
                receiveValue: { [weak self] newSpace in
                    self?.spaces.append(newSpace)
                    self?.currentSpace = newSpace
                }
            )
            .store(in: &cancellables)
    }
    
    func updateSpace(_ space: Space) {
        spaceRepository.updateSpace(space)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to update space: \(error)")
                    }
                },
                receiveValue: { [weak self] in
                    self?.loadSpaces()
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteSpace(_ space: Space) {
//        guard spaces.count > 1 else {
//            print("Cannot delete the last space")
//            return
//        }
        
        spaceRepository.deleteSpace(space)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to delete space: \(error)")
                    } else {
                        self?.loadSpaces()
                        if self?.currentSpace?.id == space.id {
                            self?.currentSpace = self?.spaces.first
                        }
                    }
                },
                receiveValue: { }
            )
            .store(in: &cancellables)
    }
    
    func selectSpace(_ space: Space) {
        currentSpace = space
    }
    
    private func loadSpaces() {
        spaceRepository.getAllSpaces()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load spaces: \(error)")
                    }
                },
                receiveValue: { [weak self] spaces in
                    self?.spaces = spaces.isEmpty ? [Space(name: "Personal", color: .blue, isDefault: true)] : spaces
                    if self?.currentSpace == nil || !spaces.contains(where: { $0.id == self?.currentSpace?.id }) {
                        self?.currentSpace = self?.spaces.first
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func setupKeyboardShortcuts() {
        // Listen for key events globally or setup responder chain
        // This would typically be handled in your main view or app delegate
    }
    
    // MARK: - Tab Management
    
    func createNewTab(with url: URL? = nil, inBackground: Bool = false) {
        let previousTab = currentTab
        
        if !inBackground {
            self.currentTab = nil
        }
        
        createTabUseCase.execute(url: url, in: currentSpace?.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to create tab: \(error)")
                    }
                },
                receiveValue: { [weak self] tab in
                    self?.configureNewTab(tab, inBackground: inBackground, previousTab: previousTab)
                }
            )
            .store(in: &cancellables)
    }
    
    private func configureNewTab(_ tab: Tab, inBackground: Bool, previousTab: Tab?) {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences.isFraudulentWebsiteWarningEnabled = false
        configuration.applicationNameForUserAgent = "Safari/605.1.15"
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        if tab.webView == nil {
            tab.webView = webView
        }
        
        if let url = tab.url {
            tab.webView?.load(URLRequest(url: url))
        }
        
        tabs.append(tab)
        
        // Update currentSpace.tabs
        if let space = currentSpace {
            let updatedSpace = space
            updatedSpace.tabs.append(tab)
            updateSpace(updatedSpace)
        }
        
        if inBackground {
            if let previous = previousTab {
                currentTab = previous
            }
        } else {
            currentTab = tab
        }
        
        print("Created tab with URL: \(tab.url?.absoluteString ?? "nil"), background: \(inBackground)")
    }
    func duplicateCurrentTab(inBackground: Bool = false) {
        guard let current = currentTab,
              let url = current.url else { return }
        
        createNewTab(with: url, inBackground: inBackground)
    }
    
    func selectTab(_ tab: Tab) {
        currentTab?.isLoading = false
        print("Selecting tab: \(tab.url?.absoluteString ?? "nil")")
        currentTab = tab
        addressText = currentTab?.url?.absoluteString ?? ""
    }
    
    func selectTabAtIndex(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        selectTab(tabs[index])
    }
    
    func selectNextTab() {
        guard !tabs.isEmpty,
              let current = currentTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        
        let nextIndex = (currentIndex + 1) % tabs.count
        selectTab(tabs[nextIndex])
    }
    
    func selectPreviousTab() {
        guard !tabs.isEmpty,
              let current = currentTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        
        let previousIndex = currentIndex == 0 ? tabs.count - 1 : currentIndex - 1
        selectTab(tabs[previousIndex])
    }
    
    func closeTab(_ tab: Tab) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        
        tabs.remove(at: tabIndex)
        
        if currentTab?.id == tab.id {
            if tabs.isEmpty {
                // Create a new tab if this was the last one
                createNewTab()
            } else {
                // Select the tab to the right, or the last tab if we closed the rightmost
                let newIndex = min(tabIndex, tabs.count - 1)
                currentTab = tabs[newIndex]
            }
        }
    }
    
    func closeCurrentTab() {
        guard let current = currentTab else { return }
        closeTab(current)
    }
    
    func closeOtherTabs(except keepTab: Tab? = nil) {
        let tabToKeep = keepTab ?? currentTab
        guard let keep = tabToKeep else { return }
        
        tabs = [keep]
        currentTab = keep
    }
    
    func closeTabsToRight(of tab: Tab) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        
        let tabsToRemove = Array(tabs[(tabIndex + 1)...])
        tabs = Array(tabs[0...tabIndex])
        
        // If current tab was removed, select the reference tab
        if let current = currentTab,
           tabsToRemove.contains(where: { $0.id == current.id }) {
            currentTab = tab
        }
    }
    
    func reopenLastClosedTab() {
        // This would require storing recently closed tabs
        // Implementation depends on your data persistence layer
        print("Reopen last closed tab - not implemented")
    }
    
    // MARK: - Navigation
    
    func goBack() {
        currentTab?.webView?.goBack()
    }
    
    func goForward() {
        currentTab?.webView?.goForward()
    }
    
    func reload() {
        currentTab?.webView?.reload()
    }
    
    func reloadIgnoringCache() {
        currentTab?.webView?.reloadFromOrigin()
    }
    
    func stopLoading() {
        currentTab?.webView?.stopLoading()
    }
    
    func focusAddressBar() {
        isEditing = true
    }
    
    // MARK: - Keyboard Shortcut Handlers
    
    func handleKeyboardShortcut(_ shortcut: KeyboardShortcut) {
        switch shortcut {
        case .newTab:
            createNewTab()
        case .newTabInBackground:
            createNewTab(inBackground: true)
        case .duplicateTab:
            duplicateCurrentTab()
        case .duplicateTabInBackground:
            duplicateCurrentTab(inBackground: true)
        case .closeTab:
            closeCurrentTab()
        case .closeOtherTabs:
            closeOtherTabs()
        case .reopenClosedTab:
            reopenLastClosedTab()
        case .nextTab:
            selectNextTab()
        case .previousTab:
            selectPreviousTab()
        case .selectTab(let index):
            selectTabAtIndex(index - 1) // Convert 1-based to 0-based
        case .goBack:
            goBack()
        case .goForward:
            goForward()
        case .reload:
            reload()
        case .reloadIgnoringCache:
            reloadIgnoringCache()
        case .stop:
            stopLoading()
        case .focusAddressBar:
            focusAddressBar()
        case .toggleSidebar:
            toggleSidebar()
        }
    }
    
    // MARK: - Existing Methods
    
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
                tab.url = url
                tab.title = addressText
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
                    print("Loaded \(tabs.count) tabs")
                    self?.tabs = tabs
                    self?.currentTab = tabs.first
                    
                    tabs.forEach { tab in
                        if tab.webView == nil {
                            let configuration = WKWebViewConfiguration()
                            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
                            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
                            configuration.preferences.isFraudulentWebsiteWarningEnabled = false
                            configuration.applicationNameForUserAgent = "Safari/605.1.15"
                            tab.webView = WKWebView(frame: .zero, configuration: configuration)
                            tab.webView?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
                            if let url = tab.url {
                                tab.webView?.load(URLRequest(url: url))
                            }
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Legacy methods - implement as needed
    func reloadTab(_ tab: Tab) {
        tab.webView?.reload()
    }
    
    func duplicateTab(_ tab: Tab) {
        guard let url = tab.url else { return }
        createNewTab(with: url)
    }
    
    func pinTab(_ tab: Tab) {
        // Implement pinning logic
        tab.isPinned = true
    }
    
    func muteTab(_ tab: Tab) {
        // Implement muting logic
       // tab.isMuted = true
    }
}

// MARK: - Keyboard Shortcut Definitions

enum KeyboardShortcut {
    case newTab                    // Cmd+T
    case newTabInBackground        // Cmd+Shift+T
    case duplicateTab             // Cmd+Shift+K
    case duplicateTabInBackground // Cmd+Shift+Option+K
    case closeTab                 // Cmd+W
    case closeOtherTabs          // Cmd+Option+W
    case reopenClosedTab         // Cmd+Shift+T (context dependent)
    case nextTab                 // Cmd+Shift+] or Ctrl+Tab
    case previousTab             // Cmd+Shift+[ or Ctrl+Shift+Tab
    case selectTab(Int)          // Cmd+1-9
    case goBack                  // Cmd+[
    case goForward               // Cmd+]
    case reload                  // Cmd+R
    case reloadIgnoringCache     // Cmd+Shift+R
    case stop                    // Cmd+.
    case focusAddressBar         // Cmd+L
    case toggleSidebar           // Cmd+Shift+S
}

// MARK: - Extension for easy shortcut detection

extension KeyboardShortcut {
    static func from(event: NSEvent) -> KeyboardShortcut? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""
        
        // Command key shortcuts
        if modifiers.contains(.command) {
            switch characters {
            case "t":
                return modifiers.contains(.shift) ? .newTabInBackground : .newTab
            case "w":
                return modifiers.contains(.option) ? .closeOtherTabs : .closeTab
            case "k":
                if modifiers.contains([.shift, .option]) {
                    return .duplicateTabInBackground
                } else if modifiers.contains(.shift) {
                    return .duplicateTab
                }
            case "[":
                return .goBack
            case "]":
                return modifiers.contains(.shift) ? .nextTab : .goForward
            case "r":
                return modifiers.contains(.shift) ? .reloadIgnoringCache : .reload
            case "l":
                return .focusAddressBar
            case "s":
                return modifiers.contains(.shift) ? .toggleSidebar : nil
            case ".":
                return .stop
            case "1"..."9":
                if let number = Int(characters) {
                    return .selectTab(number)
                }
            default:
                break
            }
            
            // Special key codes
            if modifiers.contains(.shift) {
                switch keyCode {
                case 30: // ]
                    return .nextTab
                case 33: // [
                    return .previousTab
                default:
                    break
                }
            }
        }
        
        // Control key shortcuts
        if modifiers.contains(.control) {
            switch keyCode {
            case 48: // Tab
                return modifiers.contains(.shift) ? .previousTab : .nextTab
            default:
                break
            }
        }
        
        return nil
    }
}
