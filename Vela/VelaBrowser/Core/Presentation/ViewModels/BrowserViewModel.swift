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
    @Published var isFullScreen: Bool = false
    @Published var isAdBlockingEnabled: Bool = false
    @Published var isJavaScriptEnabled: Bool = true
    @Published var isPopupBlockingEnabled: Bool = true
    @Published var isIncognitoMode: Bool = false
    @Published var showCommandPalette = false
    @Published var noteboardVM: NoteBoardViewModel
    @Published var addressBarVM: AddressBarViewModel
    @Published var detectedSechema: SchemaDetectionService
    @Published var previousSpace: Space?
    @Published var isInBoardMode: Bool = false
    @Published var folders: [Folder] = []
     
    private var popupWindows: [WKWebView: NSWindow] = [:]
    
    // Cache to track loaded tabs for each space
    private var spaceTabsCache: [UUID: [Tab]] = [:]
    private var spaceTabsLoaded: Set<UUID> = []
    
    var adBlockRuleList: WKContentRuleList?
    
    private let createTabUseCase: CreateTabUseCaseProtocol
    private let tabRepository: TabRepositoryProtocol
    private let spaceRepository: SpaceRepositoryProtocol
    private var folderRepository: FolderRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private enum UserDefaultsKeys {
        static let lastSelectedSpaceId = "lastSelectedSpaceId"
    }
    
    var spaceColor: Color {
        currentSpace?.color.color ??  Color(NSColor.tertiarySystemFill)
    }
    

    
    init(
        createTabUseCase: CreateTabUseCaseProtocol,
        tabRepository: TabRepositoryProtocol,
        spaceRepository: SpaceRepositoryProtocol,
        folderRepository: FolderRepositoryProtocol,
        noteboardVM: NoteBoardViewModel,
        addressBarVM: AddressBarViewModel,
        detectedSechema: SchemaDetectionService
    ) {
        self.createTabUseCase = createTabUseCase
        self.tabRepository = tabRepository
        self.spaceRepository = spaceRepository
        self.folderRepository = folderRepository
        self.noteboardVM = noteboardVM
        self.addressBarVM = addressBarVM
        self.detectedSechema = detectedSechema
        setupInitialState()
        setupBindings()
        setupFolderBindings()
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
                    
                    self.loadTabsForCurrentSpace()
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupBindings() {
        $currentSpace
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] space in
                guard let self = self else { return }
                if let spaceId = space?.id {
                    UserDefaults.standard.set(spaceId.uuidString, forKey: UserDefaultsKeys.lastSelectedSpaceId)
                    // Only update NoteBoardViewModel if we're not in board mode
                    if !self.isInBoardMode, let space = space {
                        self.noteboardVM.loadBoards(for: space)
                    }
                } else {
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastSelectedSpaceId)
                }
                
                // Only load tabs if we're not in board mode
                if !self.isInBoardMode {
                    self.loadTabsForCurrentSpace()
                }
            }
            .store(in: &cancellables)
        
        $currentTab
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] tab in
                guard let self = self, !self.isEditing else { return }
                self.addressText = tab?.url?.absoluteString ?? ""
                self.isLoading = tab?.isLoading ?? false
            }
            .store(in: &cancellables)
    }
    
    private func setupFolderBindings() {
         $currentSpace
             .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
             .sink { [weak self] space in
                 guard let self = self, !self.isInBoardMode else { return }
                 self.loadFoldersForCurrentSpace()
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
        // Clean up cache for deleted space
        spaceTabsCache.removeValue(forKey: space.id)
        spaceTabsLoaded.remove(space.id)
        
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
    
    func exitBoardMode() {
        isInBoardMode = false
        self.noteboardVM.selectedBoard = nil
        
        // Restore the previous space if we had one
        if let previous = previousSpace {
            currentSpace = previous
            previousSpace = nil
        }
    }

    // Update the selectSpace method to handle board mode:
    func selectSpace(_ space: Space) {
        // Store current space's tabs in cache before switching
        if let currentSpaceId = currentSpace?.id {
            spaceTabsCache[currentSpaceId] = tabs
            spaceTabsLoaded.insert(currentSpaceId)
        }
        
        // Exit board mode when selecting a space
        if isInBoardMode {
            exitBoardMode()
        }
        
        currentSpace = space
        loadTabsForCurrentSpace()
    }

    func selectBoard(_ board: NoteBoard) {
        // Store the current space before switching to board mode
        if !isInBoardMode {
            previousSpace = currentSpace
        }
        
        isInBoardMode = true
        
        // Don't set currentSpace to nil - this was causing the issue
        // Instead, just update the selected board
        self.noteboardVM.selectedBoard = board
       
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
    func startCreatingNewTab(){
        self.addressText = ""
        self.addressBarVM.isShowingEnterAddressPopup = true
    }
    
    // MARK: - Tab Management
    func createNewTab(with url: URL? = nil, inBackground: Bool = false, shouldReloadTabs: Bool = false, focusAddressBar: Bool = true, folderId: UUID? = nil) {
        let previousTab = currentTab
        
        if !inBackground {
            self.currentTab = nil
        }
        
        createTabUseCase.execute(url: url, in: currentSpace?.id, folderId: folderId)
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
                    
                    // Update cache for current space
                    if let spaceId = self.currentSpace?.id {
                        self.spaceTabsCache[spaceId] = self.tabs
                        self.spaceTabsLoaded.insert(spaceId)
                    }
                    
                    if shouldReloadTabs {
                        self.loadTabsForCurrentSpace(forceReload: true)
                    }
                    // Auto-focus address bar only if explicitly requested and not in background
                    if !inBackground && focusAddressBar {
                        self.addressText = ""
                        self.isEditing = true
                        self.addressBarVM.isShowingEnterAddressPopup = true
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

        // Set up the webView fully before any operations
        tab.setWebView(webView)

        // Load URL and favicon after webView is set
        if let url = tab.url {
            webView.load(URLRequest(url: url))
            // Delay favicon loading until webView is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                tab.reloadFavicon()
            }
        }

        // Subscribe to favicon changes to update the tab in the repository
        tab.$favicon
            .dropFirst() // Ignore initial nil value
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateTab(tab)
            }
            .store(in: &cancellables)

        // Insert new tab at the beginning of the tabs array if not in background
        if inBackground {
            tabs.append(tab)
        } else {
            tabs.insert(tab, at: 0)
        }

        // Update currentSpace.tabs
        if let space = currentSpace {
            let updatedSpace = space
            updatedSpace.tabs = tabs
            updateSpace(updatedSpace)
        }

        if inBackground {
            if let previous = previousTab {
                currentTab = previous
            }
        } else {
            currentTab = tab
        }
    }
    
    func duplicateCurrentTab(inBackground: Bool = false) {
        guard let current = currentTab,
              let url = current.url else { return }
        
        createNewTab(with: url, inBackground: inBackground, focusAddressBar: false)
    }
    
    func selectTab(_ tab: Tab) {
        currentTab?.isLoading = false
        self.addressBarVM.isShowingEnterAddressPopup = false
        // Exit board mode when selecting a tab
        if isInBoardMode {
            exitBoardMode()
        }
        
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
        print("Selecting tab: \(tab.url?.absoluteString ?? "nil")")
        
        currentTab = tab
        addressText = tab.url?.absoluteString ?? ""
        if currentTab?.url == nil {
            self.addressBarVM.isShowingEnterAddressPopup = true
        }
       
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
                    
                    // Update cache
                    if let spaceId = self.currentSpace?.id {
                        self.spaceTabsCache[spaceId] = self.tabs
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func closeTab(_ tab: Tab) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        closeAndDeleteTab(tab)
    }
    
    func closeAndDeleteTab(_ tab: Tab) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) else {
            print("Tab \(tab.id) not found in tabs array")
            return
        }
        
        tabs.remove(at: tabIndex)
        
        // Update cache immediately
        if let spaceId = currentSpace?.id {
            spaceTabsCache[spaceId] = tabs
        }
        
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
                    
                    // Update the currentSpace's tabs and persist it
                    if let space = self.currentSpace {
                        let updatedSpace = space
                        updatedSpace.tabs = self.tabs
                        self.updateSpace(updatedSpace)
                    }
                    
                    if self.currentTab?.id == tab.id {
                        if self.tabs.isEmpty {
                            self.createNewTab()
                        } else {
                            let newIndex = min(tabIndex, self.tabs.count - 1)
                            self.currentTab = self.tabs[newIndex]
                        }
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
    
    func closeTabsToRight(of tab: Tab) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        
        let tabsToRemove = Array(tabs[(tabIndex + 1)...])
        tabs = Array(tabs[0...tabIndex])
        
        // Update cache immediately
        if let spaceId = currentSpace?.id {
            spaceTabsCache[spaceId] = tabs
        }
        
        // Delete removed tabs from repository
        for tabToRemove in tabsToRemove {
            tabRepository.delete(tabId: tabToRemove.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to delete tab \(tabToRemove.id): \(error)")
                        }
                    },
                    receiveValue: { }
                )
                .store(in: &cancellables)
        }
        
        // Update currentSpace's tabs
        if let space = currentSpace {
            let updatedSpace = space
            updatedSpace.tabs = tabs
            updateSpace(updatedSpace)
        }
        
        if let current = currentTab,
           tabsToRemove.contains(where: { $0.id == current.id }) {
            currentTab = tab
        }
    }
    
    func closeOtherTabs(except keepTab: Tab? = nil) {
        let tabToKeep = keepTab ?? currentTab
        guard let keep = tabToKeep else { return }
        
        let tabsToRemove = tabs.filter { $0.id != keep.id }
        tabs = [keep]
        currentTab = keep
        
        // Update cache immediately
        if let spaceId = currentSpace?.id {
            spaceTabsCache[spaceId] = tabs
        }
        
        // Delete removed tabs from repository
        for tabToRemove in tabsToRemove {
            tabRepository.delete(tabId: tabToRemove.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to delete tab \(tabToRemove.id): \(error)")
                        }
                    },
                    receiveValue: { }
                )
                .store(in: &cancellables)
        }
        
        // Update currentSpace's tabs
        if let space = currentSpace {
            let updatedSpace = space
            updatedSpace.tabs = tabs
            updateSpace(updatedSpace)
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
    func zoomIn() {
        currentTab?.zoomIn()
        updateCurrentTab()
      
    }
    func updateCurrentTab() {
       guard let currentTab = currentTab else { return }
        updateTab(currentTab)
    }

        // Zoom out on a specific tab
    func zoomOut() {
        currentTab?.zoomOut()
        updateCurrentTab()
    }

        // Reset zoom for a specific tab
    func resetZoom() {
        currentTab?.resetZoom()
        updateCurrentTab()
    }

        // Set specific zoom level for a tab
    func setZoomLevel(zoomLevel: CGFloat) {
        currentTab?.setZoomLevel(zoomLevel)
        updateCurrentTab()
    }
    
    func openBookmarkForSelected(bookmarkViewModel: BookmarkViewModel, inBackground: Bool = false) {
        guard let selectedBookmarkURL = bookmarkViewModel.currentSelectedBookMark?.url else { return }
        
        createNewTab(with: selectedBookmarkURL, inBackground: inBackground)
    }
    
    func openURL(_ urlString: String) {
        // Implementation to open URL in current or new tab
        guard let url = URL(string: urlString) else { return }
        
        if let currentTab = currentTab {
            currentTab.url = url
        } else {
            createNewTab(with: url, inBackground: false, shouldReloadTabs: false, focusAddressBar: false)
            currentTab?.url = url
        }
    }
    func openQuickAccessURL(_ urlString: String) {
        print("openQuickAccessURL called with: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        // Normalize input URL for comparison
        guard let normalizedInputURL = normalizeURL(url) else {
            print("Failed to normalize input URL")
            return
        }
        print("Normalized input URL: \(normalizedInputURL)")
        
        // Check if current tab's URL matches
        if let currentTab = currentTab,
           let currentTabURL = currentTab.url,
           let normalizedCurrentURL = normalizeURL(currentTabURL),
           normalizedCurrentURL == normalizedInputURL {
            print("Current tab matches URL: \(currentTab.url?.absoluteString ?? "nil")")
            return
        }
        
        // Ensure tabs are loaded for current space
        guard let spaceId = currentSpace?.id else {
            print("No current space selected, creating new tab")
            createNewTab(with: url, inBackground: false, shouldReloadTabs: false, focusAddressBar: false)
            currentTab?.url = url
            return
        }
        
        print("Current space ID: \(spaceId), tabs count: \(tabs.count)")
        
        // Search for existing tab with matching URL
        for tab in tabs {
            guard let tabURL = tab.url else {
                print("Tab \(tab.id) has nil URL")
                continue
            }
            guard let normalizedTabURL = normalizeURL(tabURL) else {
                print("Failed to normalize tab URL: \(tabURL.absoluteString)")
                continue
            }
            print("Checking tab \(tab.id): URL=\(tabURL.absoluteString), Normalized=\(normalizedTabURL)")
            if normalizedTabURL == normalizedInputURL {
                print("Found matching tab: \(tabURL.absoluteString), ID: \(tab.id)")
                selectTab(tab)
                return
            }
        }
        
        print("No matching tab found, creating new tab")
        
        // Create a new tab if no match found
        createNewTab(with: url, inBackground: false, shouldReloadTabs: false, focusAddressBar: false)
        if let newTab = currentTab {
            newTab.url = url
            print("New tab created with URL: \(newTab.url?.absoluteString ?? "nil")")
        }
    }

    // Replace the normalizeURL helper method with:
    private func normalizeURL(_ url: URL) -> String? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        // Remove scheme (http:// or https://)
        components.scheme = nil
        
        // Remove fragments (e.g., #section)
        components.fragment = nil
        
        // Normalize path: remove trailing slashes
         let path = components.path
        if path.hasSuffix("/"){
            components.path = String(path.dropLast())
        }
        
        
        // Remove leading slashes from the resulting string
        guard var normalized = components.string else {
            return nil
        }
        
        while normalized.hasPrefix("/") {
            normalized = String(normalized.dropFirst())
        }
        return normalized.lowercased()
        // Convert to lowercase for case-insensitive comparison
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
        case .toggleVelaPilot:
            self.showCommandPalette.toggle()
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
    
    func getUrl(_ url: String?) -> URL? {
             let inputText = url ?? addressText 

            isLoading = true
            let urlPattern = "^(https?\\:\\/\\/)?([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}(\\/.*)?$"
            let isURL = inputText.range(of: urlPattern, options: .regularExpression) != nil

            var resultURL: URL?
            if isURL {
                let urlString = inputText.hasPrefix("http") ? inputText : "https://\(inputText)"
                resultURL = URL(string: urlString)
            } else {
                let query = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inputText
                let searchURLString = "https://www.google.com/search?q=\(query)"
                resultURL = URL(string: searchURLString)
            }
            
            return resultURL
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
    
    // MARK: - Smart Tab Loading with Caching
    
    private func loadTabsForCurrentSpace(forceReload: Bool = false) {
        guard let spaceId = currentSpace?.id else {
            tabs = []
            currentTab = nil
            return
        }
        
        // Check if tabs are already loaded for this space and we're not forcing a reload
        if !forceReload && spaceTabsLoaded.contains(spaceId), let cachedTabs = spaceTabsCache[spaceId] {
            print("Loading cached tabs for space \(spaceId): \(cachedTabs.count) tabs")
            // **IMPORTANT**: Sort tabs by position when loading from cache
            tabs = cachedTabs.sorted { $0.position < $1.position }
            currentTab = tabs.first
            if currentTab?.url == nil {
                addressBarVM.isShowingEnterAddressPopup = true
            }
            // Ensure WebViews are still properly configured
            tabs.forEach { tab in
                if tab.webView == nil {
                    configureWebViewForTab(tab)
                }
            }
            return
        }
        
        // Load tabs from repository
        print("Loading tabs from repository for space \(spaceId)")
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
                    // **IMPORTANT**: Sort tabs by position when loading from repository
                    self.tabs = tabs.sorted { $0.position < $1.position }
                    self.currentTab = self.tabs.first
                    if currentTab?.url == nil {
                        addressBarVM.isShowingEnterAddressPopup = true
                    }
                    // Cache the loaded tabs
                    self.spaceTabsCache[spaceId] = self.tabs
                    self.spaceTabsLoaded.insert(spaceId)
                    
                    // Configure web views for all tabs
                    self.tabs.forEach { tab in
                        if tab.webView == nil {
                            self.configureWebViewForTab(tab)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func configureWebViewForTab(_ tab: Tab) {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences.isFraudulentWebsiteWarningEnabled = false
        configuration.applicationNameForUserAgent = "Safari/605.1.15"
        
        tab.webView = WKWebView(frame: .zero, configuration: configuration)
        tab.webView?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        if let url = tab.url {
            tab.webView?.load(URLRequest(url: url))
            tab.reloadFavicon()
        }
    }
    
    // Method to force refresh tabs for current space (useful for debugging or manual refresh)
    func forceRefreshCurrentSpaceTabs() {
        if let spaceId = currentSpace?.id {
            spaceTabsLoaded.remove(spaceId)
            spaceTabsCache.removeValue(forKey: spaceId)
        }
        loadTabsForCurrentSpace(forceReload: true)
    }
    
    // Method to clear all cache (useful for memory management)
    func clearTabsCache() {
        spaceTabsCache.removeAll()
        spaceTabsLoaded.removeAll()
        print("Cleared all tabs cache")
    }
    
    // Legacy methods
    func reloadTab(_ tab: Tab) {
        tab.webView?.reload()
    }
    
    func duplicateTab(_ tab: Tab) {
        guard let url = tab.url else { return }
        createNewTab(with: url, focusAddressBar: false)
    }
    
    func pinTab(_ tab: Tab) {
        tab.isPinned = !tab.isPinned
    }
    
    func muteTab(_ tab: Tab) {
        // tab.isMuted = true
    }
    
    func toggleFullScreen(_ isFullScreen: Bool) {
        self.isFullScreen = isFullScreen
        objectWillChange.send() // Trigger UI update
    }
    
    func setupAdBlocking() {
        let adBlockRules = """
        [
            {
                "trigger": {
                    "url-filter": ".*",
                    "resource-type": ["image", "script", "style-sheet", "font"],
                    "if-domain": [
                        "*doubleclick.net",
                        "*googlesyndication.com",
                        "*adnxs.com",
                        "*adservice.google.com",
                        "*google-analytics.com",
                        "*ads.pubmatic.com",
                        "*adroll.com"
                    ]
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": ".*",
                    "resource-type": ["script"],
                    "if-domain": ["*trackers.com"]
                },
                "action": {
                    "type": "block"
                }
            }
        ]
        """
        
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "AdBlockingRules",
            encodedContentRuleList: adBlockRules
        ) { [weak self] ruleList, error in
            guard let self = self else { return }
            if let error = error {
                print("Failed to compile ad blocking rules: \(error)")
                return
            }
            self.adBlockRuleList = ruleList
            if self.isAdBlockingEnabled {
                self.applyAdBlocking()
            }
        }
    }
    
    func updateAdBlocking(enabled: Bool) {
        isAdBlockingEnabled = enabled
        applyAdBlocking()
    }
    
    private func applyAdBlocking() {
        let tabs = tabs
        for tab in tabs {
            guard let webView = tab.webView else { continue }
            webView.configuration.userContentController.removeAllContentRuleLists()
            if isAdBlockingEnabled, let ruleList = adBlockRuleList {
                webView.configuration.userContentController.add(ruleList)
            }
        }
    }
    
    func updateJavaScript(enabled: Bool) {
        isJavaScriptEnabled = enabled
        let tabs = tabs
        for tab in tabs {
            guard let webView = tab.webView else { continue }
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = enabled
            if !enabled {
                webView.reload() // Reload to apply JavaScript disable
            }
        }
    }
    
    func updateIncognitoMode(enabled: Bool) {
//        isIncognitoMode = enabled
//        guard let tabs = tabs else { return }
//        for tab in tabs {
//            guard let webView = tab.webView else { continue }
//            if enabled {
//                webView.configuration.websiteDataStore = .nonPersistent()
//            } else {
//                webView.configuration.websiteDataStore = .default()
//            }
//            webView.reload() // Reload to apply new data store
//        }
    }
    
    func updatePopupBlocking(enabled: Bool) {
        isPopupBlockingEnabled = enabled
        let tabs = tabs
        for tab in tabs {
            guard let webView = tab.webView else { continue }
            webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = !enabled
        }
    }
    
    func addPopupWindow(_ window: NSWindow, for webView: WKWebView) {
            popupWindows[webView] = window
            // Observe window closing to clean up
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.popupWindows.removeValue(forKey: webView)
                print("🪟 Popup window closed for web view: \(webView)")
            }
        }
        
        // Optional: Method to close all popup windows
        func closeAllPopupWindows() {
            for (webView, window) in popupWindows {
                webView.stopLoading()
                window.close()
            }
            popupWindows.removeAll()
            print("🪟 All popup windows closed")
        }

    private func normalizeTabPositions(isPinned: Bool) {
        let tabsToNormalize = tabs.filter { $0.isPinned == isPinned }
            .sorted { $0.position < $1.position }
        
        for (index, tab) in tabsToNormalize.enumerated() {
            tab.position = index
        }
    }
    
    // **NEW METHOD**: Save tab positions to repository
    private func saveTabPositions(isPinned: Bool) {
        let tabsToSave = tabs.filter { $0.isPinned == isPinned }
        
        for tab in tabsToSave {
            tabRepository.update(tab: tab)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to update tab position for \(tab.id): \(error)")
                        }
                    },
                    receiveValue: { _ in
                        print("Successfully updated position for tab \(tab.id): \(tab.position)")
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func createNewTabWithPosition(url: URL? = nil, inBackground: Bool = false, folderId: UUID? = nil) -> Tab? {
        // Create the tab synchronously first
        let newTab = Tab(
            id: UUID(),
            title: url?.host ?? "New Tab", url: url,
            spaceId: currentSpace?.id, isPinned: false,
            position: getNextTabPosition(isPinned: false),
            folderId: nil
        )
        
        // Add to tabs array immediately
        tabs.append(newTab)
        
        // Set as current tab if not in background
        if !inBackground {
            currentTab = newTab
            self.addressBarVM.isShowingEnterAddressPopup = true
        }
        
        // Update cache for current space
        if let spaceId = currentSpace?.id {
            spaceTabsCache[spaceId] = tabs
            spaceTabsLoaded.insert(spaceId)
        }
        
        // Save to persistent storage asynchronously
        createTabUseCase.execute(url: url, in: currentSpace?.id, folderId: folderId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to persist tab: \(error)")
                        // Handle error - maybe remove from tabs array if persistence fails
                    }
                },
                receiveValue: { [weak self] persistedTab in
                    guard let self = self else { return }
                    // Update the temporary tab with the persisted one
                    if let index = self.tabs.firstIndex(where: { $0.id == newTab.id }) {
                        self.tabs[index] = persistedTab
                    }
                }
            )
            .store(in: &cancellables)
        
        return newTab
    }
    
    /// Gets the next available position for a tab
    private func getNextTabPosition(isPinned: Bool) -> Int {
        if isPinned {
            let maxPinnedPosition = tabs.filter { $0.isPinned }.map { $0.position }.max() ?? -1
            return maxPinnedPosition + 1
        } else {
            let maxRegularPosition = tabs.filter { !$0.isPinned }.map { $0.position }.max() ?? -1
            return maxRegularPosition + 1
        }
    }
    
    /// Reorders a tab to a new position
    func reorderTab(_ tab: Tab, to targetIndex: Int, isPinned: Bool) {
        guard let currentIndex = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        
        // Get the relevant tabs (pinned or regular)
        let relevantTabs = tabs.filter { $0.isPinned == isPinned }.sorted { $0.position < $1.position }
        
        // Ensure target index is valid
        let clampedTargetIndex = max(0, min(targetIndex, relevantTabs.count - 1))
        
        // Remove the tab from its current position
        tabs.removeAll { $0.id == tab.id }
        
        // Update the tab's position and pinned status
        var updatedTab = tab
        updatedTab.isPinned = isPinned
        
        // Recalculate positions for all tabs in the section
        var updatedTabs = relevantTabs.filter { $0.id != tab.id }
        updatedTabs.insert(updatedTab, at: clampedTargetIndex)
        
        // Update positions
        for (index, var tab) in updatedTabs.enumerated() {
            tab.position = index
            if let tabIndex = tabs.firstIndex(where: { $0.id == tab.id }) {
                tabs[tabIndex] = tab
            } else {
                tabs.append(tab)
            }
        }
        
        // Sort tabs to maintain order
        tabs.sort { $0.position < $1.position }
        
        // Update cache
        if let spaceId = currentSpace?.id {
            spaceTabsCache[spaceId] = tabs
        }
        
        // Persist changes
        persistTabOrder()
    }
    
    /// Persists the current tab order to storage
    private func persistTabOrder() {
        // Save all tab positions
        for tab in tabs {
            updateTab(tab)
        }
    }
    
    /// Toggles a tab's pinned status
    func toggleTabPinned(_ tab: Tab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        
        var updatedTab = tab
        updatedTab.isPinned = !tab.isPinned
        
        // Update position based on new pinned status
        updatedTab.position = getNextTabPosition(isPinned: updatedTab.isPinned)
        
        tabs[index] = updatedTab
        
        // Reorder tabs to maintain proper positioning
        reorderTabsAfterPinToggle()
        
        // Update cache
        if let spaceId = currentSpace?.id {
            spaceTabsCache[spaceId] = tabs
        }
        
        // Persist the change
        updateTab(updatedTab)
    }
    
    /// Reorders tabs after a pin status change
    private func reorderTabsAfterPinToggle() {
        // Separate pinned and regular tabs
        var pinnedTabs = tabs.filter { $0.isPinned }.sorted { $0.position < $1.position }
        var regularTabs = tabs.filter { !$0.isPinned }.sorted { $0.position < $1.position }
        
        // Reassign positions
        for (index, var tab) in pinnedTabs.enumerated() {
            tab.position = index
            pinnedTabs[index] = tab
        }
        
        for (index, var tab) in regularTabs.enumerated() {
            tab.position = index
            regularTabs[index] = tab
        }
        
        // Update the main tabs array
        tabs = pinnedTabs + regularTabs
    }
    
    // MARK: - Folder Management
        func createFolder(name: String) {
            guard let spaceId = currentSpace?.id else { return }
            let folder = Folder(name: name, spaceId: spaceId, position: folders.count)
            
            folderRepository.create(folder: folder)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            print("Failed to create folder: \(error)")
                        } else {
                            self?.loadFoldersForCurrentSpace()
                        }
                    },
                    receiveValue: { [weak self] newFolder in
                        self?.folders.append(newFolder)
                    }
                )
                .store(in: &cancellables)
        }
        
        func updateFolder(_ folder: Folder) {
            folderRepository.update(folder: folder)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to update folder: \(error)")
                        }
                    },
                    receiveValue: { [weak self] updatedFolder in
                        if let index = self?.folders.firstIndex(where: { $0.id == updatedFolder.id }) {
                            self?.folders[index] = updatedFolder
                        }
                    }
                )
                .store(in: &cancellables)
        }
        
        func deleteFolder(_ folder: Folder) {
            folderRepository.delete(folderId: folder.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            print("Failed to delete folder: \(error)")
                        } else {
                            self?.folders.removeAll { $0.id == folder.id }
                        }
                    },
                    receiveValue: { }
                )
                .store(in: &cancellables)
        }
        
        func addTab(_ tab: Tab, to folder: Folder) {
            var updatedFolder = folder
            updatedFolder.tabs.append(tab)
            updatedFolder.updatedAt = Date()
            
            // Update the tab's spaceId to match the folder's spaceId
            let updatedTab = tab
            updatedTab.spaceId = folder.spaceId
            updatedTab.folderId = folder.id
            // Update both tab and folder
            Publishers.CombineLatest(
                tabRepository.update(tab: updatedTab),
                folderRepository.update(folder: updatedFolder)
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to add tab to folder: \(error)")
                    } else {
                        self?.loadTabsForCurrentSpace()
                        self?.loadFoldersForCurrentSpace()
                    }
                },
                receiveValue: { [weak self] updatedTab, updatedFolder in
                    if let folderIndex = self?.folders.firstIndex(where: { $0.id == folder.id }) {
                        self?.folders[folderIndex] = updatedFolder
                    }
                    if let tabIndex = self?.tabs.firstIndex(where: { $0.id == tab.id }) {
                        self?.tabs[tabIndex] = updatedTab
                    }
                }
            )
            .store(in: &cancellables)
        }
        
    func removeTab(_ tab: Tab, from folder: Folder) {
        // Update the folder by removing the tab
        var updatedFolder = folder
        updatedFolder.tabs.removeAll { $0.id == tab.id }
        updatedFolder.updatedAt = Date()
        
        // Update the tab by clearing its folderId
        let updatedTab = tab
        updatedTab.folderId = nil
        
        // Ensure the tab is added back to the main tabs list if not already present
        if !tabs.contains(where: { $0.id == tab.id }) {
            updatedTab.position = getNextTabPosition(isPinned: updatedTab.isPinned)
            tabs.append(updatedTab)
        } else if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index] = updatedTab
        }
        
        // Update both tab and folder in the repository
        Publishers.CombineLatest(
            tabRepository.update(tab: updatedTab),
            folderRepository.update(folder: updatedFolder)
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to remove tab from folder: \(error)")
                } else {
                    // Reload both tabs and folders to ensure UI reflects changes
                    self?.loadTabsForCurrentSpace()
                    self?.loadFoldersForCurrentSpace()
                }
            },
            receiveValue: { [weak self] updatedTab, updatedFolder in
                guard let self = self else { return }
                // Update folder in folders array
                if let folderIndex = self.folders.firstIndex(where: { $0.id == folder.id }) {
                    self.folders[folderIndex] = updatedFolder
                }
                // Update tab in tabs array
                if let tabIndex = self.tabs.firstIndex(where: { $0.id == updatedTab.id }) {
                    self.tabs[tabIndex] = updatedTab
                }
                // Update currentTab if it was the affected tab
                if self.currentTab?.id == updatedTab.id {
                    self.currentTab = updatedTab
                }
            }
        )
        .store(in: &cancellables)
    }
        
        private func loadFoldersForCurrentSpace() {
            guard let spaceId = currentSpace?.id else {
                folders = []
                return
            }
            
            folderRepository.getBySpace(spaceId: spaceId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            print("Failed to load folders for space \(spaceId): \(error)")
                            self?.folders = []
                        }
                    },
                    receiveValue: { [weak self] folders in
                        self?.folders = folders.sorted { $0.position < $1.position }
                    }
                )
                .store(in: &cancellables)
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
    case toggleVelaPilot          // Cmd+K

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
