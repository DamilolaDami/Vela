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
    @Published var columnVisibility = NavigationSplitViewVisibility.all
    
    private let createTabUseCase: CreateTabUseCaseProtocol
    private let tabRepository: TabRepositoryProtocol
    private let spaceRepository: SpaceRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private enum UserDefaultsKeys {
        static let lastSelectedSpaceId = "lastSelectedSpaceId"
    }
    
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
                    
                    // Retrieve the last selected space ID from UserDefaults
                    if let lastSpaceIdString = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastSelectedSpaceId),
                       let lastSpaceId = UUID(uuidString: lastSpaceIdString),
                       let savedSpace = spaces.first(where: { $0.id == lastSpaceId }) {
                        self.currentSpace = savedSpace
                    } else {
                        self.currentSpace = self.spaces.first
                    }
                    
                    self.loadTabs()
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupBindings() {
        $currentTab
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] tab in
                guard let self = self, !self.isEditing else { return }
                self.addressText = tab?.url?.absoluteString ?? ""
                self.isLoading = tab?.isLoading ?? false
            }
            .store(in: &cancellables)
        
        $currentSpace
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] space in
                guard let self = self else { return }
                if let spaceId = space?.id {
                    UserDefaults.standard.set(spaceId.uuidString, forKey: UserDefaultsKeys.lastSelectedSpaceId)
                } else {
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastSelectedSpaceId)
                }
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
        loadTabs()
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
    
    // MARK: - Tab Management
    
    func createNewTab(with url: URL? = nil, inBackground: Bool = false, shouldReloadTabs: Bool = false) {
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
                    guard let self = self else { return }
                    self.configureNewTab(tab, inBackground: inBackground, previousTab: previousTab)
                    if shouldReloadTabs {
                        self.loadTabs()
                    }
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
    
    func updateTab(_ tab: Tab) {
        tabRepository.update(tab: tab)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to update tab \(tab.id): \(error)")
                    }
                },
                receiveValue: { [weak self] updatedTab in
                    guard let self = self else { return }
                    
                    if let index = self.tabs.firstIndex(where: { $0.id == tab.id }) {
                        self.tabs[index] = updatedTab
                    }
                    
                    if self.currentTab?.id == updatedTab.id {
                        self.currentTab = updatedTab
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func closeTab(_ tab: Tab) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        
        tabs.remove(at: tabIndex)
        
        if currentTab?.id == tab.id {
            if tabs.isEmpty {
                createNewTab()
            } else {
                let newIndex = min(tabIndex, tabs.count - 1)
                currentTab = tabs[newIndex]
            }
        }
    }
    
    func closeAndDeleteTab(_ tab: Tab) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) else {
            print("Tab \(tab.id) not found in tabs array")
            return
        }
        
        tabs.remove(at: tabIndex)
        
        tabRepository.delete(tabId: tab.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to delete tab \(tab.id): \(error)")
                    }
                },
                receiveValue: { [weak self] in
                    guard let self = self else { return }
                    
                    if self.currentTab?.id == tab.id {
                        if self.tabs.isEmpty {
                            self.createNewTab()
                        } else {
                            let newIndex = min(tabIndex, self.tabs.count - 1)
                            self.currentTab = self.tabs[newIndex]
                        }
                    }
                    
                    if let space = self.currentSpace {
                        let updatedSpace = space
                        updatedSpace.tabs.removeAll { $0.id == tab.id }
                        self.updateSpace(updatedSpace)
                    }
                    
                    print("Closed and deleted tab \(tab.id): \(tab.title ?? "Untitled"), \(tab.url?.absoluteString ?? "no URL")")
                }
            )
            .store(in: &cancellables)
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
        
        if let current = currentTab,
           tabsToRemove.contains(where: { $0.id == current.id }) {
            currentTab = tab
        }
    }
    
    func reopenLastClosedTab() {
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
        print("Handling keyboard shortcut: \(shortcut)")
        
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
            selectTabAtIndex(index - 1)
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
    
    // MARK: - UI Actions
    
    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            sidebarCollapsed.toggle()
            if columnVisibility == .all {
                columnVisibility = .detailOnly
            } else {
                columnVisibility = .all
            }
            print("columnVisibility : \(columnVisibility)")
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
        guard let spaceId = currentSpace?.id else {
            tabs = []
            currentTab = nil
            return
        }
        
        // Skip if tabs are already loaded for the current space
        if !tabs.isEmpty && tabs.first?.spaceId == spaceId {
            return
        }
        
        tabRepository.getBySpace(spaceId: spaceId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to load tabs for space \(spaceId): \(error)")
                        self?.tabs = []
                        self?.currentTab = nil
                    }
                },
                receiveValue: { [weak self] tabs in
                    guard let self = self else { return }
                    print("Loaded \(tabs.count) tabs for space \(spaceId)")
                    self.tabs = tabs
                    self.currentTab = tabs.first
                    
                    // Configure web views only for new tabs
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
    // Legacy methods
    func reloadTab(_ tab: Tab) {
        tab.webView?.reload()
    }
    
    func duplicateTab(_ tab: Tab) {
        guard let url = tab.url else { return }
        createNewTab(with: url)
    }
    
    func pinTab(_ tab: Tab) {
        tab.isPinned = !tab.isPinned
    }
    
    func muteTab(_ tab: Tab) {
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

    static func from(event: NSEvent) -> KeyboardShortcut? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""

        // Key codes (based on standard macOS key codes)
        let tKeyCode: UInt16 = 17    // T
        let wKeyCode: UInt16 = 13    // W
        let kKeyCode: UInt16 = 40    // K
        let lKeyCode: UInt16 = 37    // L
        let sKeyCode: UInt16 = 1     // S
        let rKeyCode: UInt16 = 15    // R
        let periodKeyCode: UInt16 = 47 // .
        let leftBracketKeyCode: UInt16 = 33 // [
        let rightBracketKeyCode: UInt16 = 30 // ]
        let tabKeyCode: UInt16 = 48  // Tab
        let numberKeyCodes: [UInt16: Int] = [ // Cmd+1-9
            18: 1, 19: 2, 20: 3, 21: 4, 23: 5, 22: 6, 26: 7, 28: 8, 25: 9
        ]

        // Command-based shortcuts
        if modifiers.contains(.command) {
            // Cmd+T: New Tab
            if keyCode == tKeyCode && characters == "t" && !modifiers.contains(.shift) {
                return .newTab
            }
            // Cmd+Shift+T: New Tab in Background (or reopenClosedTab, context dependent)
            if keyCode == tKeyCode && characters == "t" && modifiers.contains(.shift) {
                return .newTabInBackground // Adjust if reopenClosedTab is needed
            }
            // Cmd+W: Close Tab
            if keyCode == wKeyCode && characters == "w" && !modifiers.contains(.option) {
                return .closeTab
            }
            // Cmd+Option+W: Close Other Tabs
            if keyCode == wKeyCode && characters == "w" && modifiers.contains(.option) {
                return .closeOtherTabs
            }
            // Cmd+Shift+K: Duplicate Tab
            if keyCode == kKeyCode && characters == "k" && modifiers.contains(.shift) && !modifiers.contains(.option) {
                return .duplicateTab
            }
            // Cmd+Shift+Option+K: Duplicate Tab in Background
            if keyCode == kKeyCode && characters == "k" && modifiers.contains(.shift) && modifiers.contains(.option) {
                return .duplicateTabInBackground
            }
            // Cmd+L: Focus Address Bar
            if keyCode == lKeyCode && characters == "l" {
                return .focusAddressBar
            }
            // Cmd+Shift+S: Toggle Sidebar
            if keyCode == sKeyCode && characters == "s" && modifiers.contains(.shift) {
                return .toggleSidebar
            }
            // Cmd+R: Reload
            if keyCode == rKeyCode && characters == "r" && !modifiers.contains(.shift) {
                return .reload
            }
            // Cmd+Shift+R: Reload Ignoring Cache
            if keyCode == rKeyCode && characters == "r" && modifiers.contains(.shift) {
                return .reloadIgnoringCache
            }
            // Cmd+[: Go Back
            if keyCode == leftBracketKeyCode && characters == "[" {
                return .goBack
            }
            // Cmd+]: Go Forward
            if keyCode == rightBracketKeyCode && characters == "]" {
                return .goForward
            }
            // Cmd+.: Stop Loading
            if keyCode == periodKeyCode && characters == "." {
                return .stop
            }
            // Cmd+1-9: Select Tab
            if let tabNumber = numberKeyCodes[keyCode] {
                return .selectTab(tabNumber)
            }
        }

        // Control-based shortcuts
        if modifiers.contains(.control) && keyCode == tabKeyCode {
            if modifiers.contains(.shift) {
                return .previousTab // Ctrl+Shift+Tab
            } else {
                return .nextTab // Ctrl+Tab
            }
        }

        // Additional Command+Shift shortcuts
        if modifiers.contains(.command) && modifiers.contains(.shift) {
            // Cmd+Shift+]: Next Tab
            if keyCode == rightBracketKeyCode && characters == "]" {
                return .nextTab
            }
            // Cmd+Shift+[: Previous Tab
            if keyCode == leftBracketKeyCode && characters == "[" {
                return .previousTab
            }
        }

        return nil
    }
}
