//
//  VelaPilotViewModel.swift
//  Vela
//
//  Created by damilola on 6/1/25.
//

import SwiftUI

@MainActor
class VelaPilotViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCommandIndex = 0
    @Published var isVisible = false
    @Published var filteredCommands: [VelaPilotCommand] = []
    @Published var browserViewModel: BrowserViewModel
    @Published var bookmarkViewModel: BookmarkViewModel
    
    init(broswerViewModel: BrowserViewModel, bookmarkViewModel: BookmarkViewModel) {
        self._browserViewModel = .init(wrappedValue: broswerViewModel)
        self._bookmarkViewModel = .init(wrappedValue: bookmarkViewModel)
        filteredCommands = getContextualCommands()
    }
    
    let allCommands: [VelaPilotCommand] = [
        // Tab Commands
        VelaPilotCommand(
            title: "New Tab",
            subtitle: "Open a new tab",
            icon: "plus",
            category: .tabs,
            action: .newTab,
            keywords: ["new", "tab", "create"],
            shortcut: "⌘T"
        ),
        VelaPilotCommand(
            title: "New Tab in Background",
            subtitle: "Open a new tab without switching to it",
            icon: "plus.rectangle.on.rectangle",
            category: .tabs,
            action: .custom("new_tab_background"),
            keywords: ["new", "tab", "background", "create"],
            shortcut: "⌘⇧T"
        ),
        VelaPilotCommand(
            title: "Close Tab",
            subtitle: "Close current tab",
            icon: "xmark",
            category: .tabs,
            action: .closeTab,
            keywords: ["close", "tab", "remove"],
            shortcut: "⌘W",
            contextRequirement: .hasCurrentTab
        ),
        VelaPilotCommand(
            title: "Close Other Tabs",
            subtitle: "Close all tabs except current one",
            icon: "xmark.circle",
            category: .tabs,
            action: .custom("close_other_tabs"),
            keywords: ["close", "other", "tabs"],
            shortcut: "⌘⌥W",
            contextRequirement: .hasMultipleTabs
        ),
        VelaPilotCommand(
            title: "Close Tabs to Right",
            subtitle: "Close all tabs to the right of current tab",
            icon: "xmark.rectangle.portrait",
            category: .tabs,
            action: .custom("close_tabs_right"),
            keywords: ["close", "tabs", "right"],
            contextRequirement: .hasMultipleTabs
        ),
        VelaPilotCommand(
            title: "Reopen Closed Tab",
            subtitle: "Restore recently closed tab",
            icon: "arrow.uturn.left",
            category: .tabs,
            action: .custom("reopen_tab"),
            keywords: ["reopen", "restore", "undo"],
            shortcut: "⌘⇧T"
        ),
        VelaPilotCommand(
            title: "Duplicate Tab",
            subtitle: "Create a copy of current tab",
            icon: "doc.on.doc",
            category: .tabs,
            action: .custom("duplicate_tab"),
            keywords: ["duplicate", "copy", "clone"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Duplicate Tab in Background",
            subtitle: "Create a copy of current tab in background",
            icon: "doc.on.doc.fill",
            category: .tabs,
            action: .custom("duplicate_tab_background"),
            keywords: ["duplicate", "copy", "clone", "background"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Pin Tab",
            subtitle: "Pin current tab",
            icon: "pin",
            category: .tabs,
            action: .custom("pin_tab"),
            keywords: ["pin", "favorite", "keep"],
            contextRequirement: .hasCurrentTab
        ),
        VelaPilotCommand(
            title: "Move Tab to New Window",
            subtitle: "Detach current tab to a new window",
            icon: "macwindow.on.rectangle",
            category: .tabs,
            action: .custom("move_tab_window"),
            keywords: ["move", "window", "detach"],
            contextRequirement: .hasCurrentTab
        ),
        VelaPilotCommand(
            title: "Mute Tab",
            subtitle: "Toggle audio for current tab",
            icon: "speaker.slash",
            category: .tabs,
            action: .custom("mute_tab"),
            keywords: ["mute", "silence", "audio"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Mute All Other Tabs",
            subtitle: "Silence audio from all tabs except current",
            icon: "speaker.slash.circle",
            category: .tabs,
            action: .custom("mute_other_tabs"),
            keywords: ["mute", "silence", "other", "tabs"],
            contextRequirement: .hasMultipleTabs
        ),
        VelaPilotCommand(
            title: "Next Tab",
            subtitle: "Switch to next tab",
            icon: "chevron.right.circle",
            category: .tabs,
            action: .custom("next_tab"),
            keywords: ["next", "tab", "switch"],
            shortcut: "⌘⇧]",
            contextRequirement: .hasMultipleTabs
        ),
        VelaPilotCommand(
            title: "Previous Tab",
            subtitle: "Switch to previous tab",
            icon: "chevron.left.circle",
            category: .tabs,
            action: .custom("previous_tab"),
            keywords: ["previous", "tab", "switch"],
            shortcut: "⌘⇧[",
            contextRequirement: .hasMultipleTabs
        ),
        
        // Navigation Commands
        VelaPilotCommand(
            title: "Open Website",
            subtitle: "Navigate to any URL",
            icon: "globe",
            category: .navigation,
            action: .custom("open_url"),
            keywords: ["open", "go", "navigate", "visit"],
            shortcut: "⌘O"
        ),
        VelaPilotCommand(
            title: "Search Web",
            subtitle: "Search using default search engine",
            icon: "magnifyingglass",
            category: .navigation,
            action: .custom("search_web"),
            keywords: ["search", "google", "find"]
        ),
        VelaPilotCommand(
            title: "Go Back",
            subtitle: "Navigate to previous page",
            icon: "chevron.left",
            category: .navigation,
            action: .custom("go_back"),
            shortcut: "⌘[",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Go Forward",
            subtitle: "Navigate to next page",
            icon: "chevron.right",
            category: .navigation,
            action: .custom("go_forward"),
            shortcut: "⌘]",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Reload Page",
            subtitle: "Refresh current page",
            icon: "arrow.clockwise",
            category: .navigation,
            action: .custom("reload"),
            shortcut: "⌘R",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Hard Reload",
            subtitle: "Refresh page ignoring cache",
            icon: "arrow.clockwise.circle",
            category: .navigation,
            action: .custom("hard_reload"),
            shortcut: "⌘⇧R",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Stop Loading",
            subtitle: "Stop loading current page",
            icon: "stop.circle",
            category: .navigation,
            action: .custom("stop_loading"),
            keywords: ["stop", "cancel", "halt"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Home Page",
            subtitle: "Navigate to home page",
            icon: "house",
            category: .navigation,
            action: .custom("go_home"),
            keywords: ["home", "start", "homepage"]
        ),
        VelaPilotCommand(
            title: "Focus Address Bar",
            subtitle: "Focus the address/URL bar",
            icon: "location",
            category: .navigation,
            action: .custom("focus_address"),
            keywords: ["address", "url", "bar", "focus"],
            shortcut: "⌘L"
        ),
        
        // Page Actions
        VelaPilotCommand(
            title: "Print Page",
            subtitle: "Print current page",
            icon: "printer",
            category: .pageActions,
            action: .custom("print_page"),
            keywords: ["print", "paper"],
            shortcut: "⌘P",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Save Page As PDF",
            subtitle: "Export current page as PDF",
            icon: "doc.richtext",
            category: .pageActions,
            action: .custom("save_pdf"),
            keywords: ["save", "pdf", "export"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Save Page",
            subtitle: "Save current page to disk",
            icon: "square.and.arrow.down",
            category: .pageActions,
            action: .custom("save_page"),
            keywords: ["save", "download", "file"],
            shortcut: "⌘S",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Share Page",
            subtitle: "Share current page URL",
            icon: "square.and.arrow.up",
            category: .pageActions,
            action: .custom("share_page"),
            keywords: ["share", "send", "link"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Copy Page URL",
            subtitle: "Copy current page URL to clipboard",
            icon: "doc.on.clipboard",
            category: .pageActions,
            action: .custom("copy_url"),
            keywords: ["copy", "url", "link", "clipboard"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Copy Page Title",
            subtitle: "Copy current page title to clipboard",
            icon: "textformat",
            category: .pageActions,
            action: .custom("copy_title"),
            keywords: ["copy", "title", "clipboard"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Email Page",
            subtitle: "Email current page link",
            icon: "envelope",
            category: .pageActions,
            action: .custom("email_page"),
            keywords: ["email", "mail", "send"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        
        // Zoom & Display
        VelaPilotCommand(
            title: "Zoom In",
            subtitle: "Increase page zoom level",
            icon: "plus.magnifyingglass",
            category: .display,
            action: .custom("zoom_in"),
            keywords: ["zoom", "in", "larger", "magnify"],
            shortcut: "⌘+",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Zoom Out",
            subtitle: "Decrease page zoom level",
            icon: "minus.magnifyingglass",
            category: .display,
            action: .custom("zoom_out"),
            keywords: ["zoom", "out", "smaller"],
            shortcut: "⌘-",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Reset Zoom",
            subtitle: "Reset page zoom to default",
            icon: "magnifyingglass",
            category: .display,
            action: .custom("reset_zoom"),
            keywords: ["zoom", "reset", "default"],
            shortcut: "⌘0",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Full Screen",
            subtitle: "Enter full screen mode",
            icon: "arrow.up.left.and.arrow.down.right",
            category: .display,
            action: .custom("full_screen"),
            keywords: ["fullscreen", "full", "screen"],
            shortcut: "⌃⌘F"
        ),
        VelaPilotCommand(
            title: "Hide Sidebar",
            subtitle: "Toggle sidebar visibility",
            icon: "sidebar.left",
            category: .display,
            action: .custom("toggle_sidebar"),
            keywords: ["sidebar", "hide", "show", "toggle"],
            shortcut: "⌘⇧S"
        ),
        
        // Find & Search
        VelaPilotCommand(
            title: "Find in Page",
            subtitle: "Search for text in current page",
            icon: "magnifyingglass.circle",
            category: .search,
            action: .custom("find_in_page"),
            keywords: ["find", "search", "page", "text"],
            shortcut: "⌘F",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Find Next",
            subtitle: "Find next occurrence",
            icon: "chevron.down.circle",
            category: .search,
            action: .custom("find_next"),
            keywords: ["find", "next", "continue"],
            shortcut: "⌘G",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Find Previous",
            subtitle: "Find previous occurrence",
            icon: "chevron.up.circle",
            category: .search,
            action: .custom("find_previous"),
            keywords: ["find", "previous", "back"],
            shortcut: "⌘⇧G",
            contextRequirement: .hasCurrentTabWithURL
        ),
        
        // Bookmark Commands
        VelaPilotCommand(
            title: "Bookmark Page",
            subtitle: "Save current page to bookmarks",
            icon: "bookmark.fill",
            category: .bookmarks,
            action: .bookmarkPage,
            keywords: ["bookmark", "save", "favorite"],
            shortcut: "⌘D",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Show Bookmarks",
            subtitle: "View all bookmarks",
            icon: "book",
            category: .bookmarks,
            action: .custom("show_bookmarks"),
            keywords: ["bookmarks", "favorites", "saved"]
        ),
        VelaPilotCommand(
            title: "Bookmark All Tabs",
            subtitle: "Save all open tabs to bookmarks",
            icon: "book.circle",
            category: .bookmarks,
            action: .custom("bookmark_all_tabs"),
            keywords: ["bookmark", "all", "tabs", "save"],
            contextRequirement: .hasMultipleTabs
        ),
        VelaPilotCommand(
            title: "Add to Reading List",
            subtitle: "Save for later reading",
            icon: "text.badge.plus",
            category: .bookmarks,
            action: .custom("reading_list"),
            keywords: ["reading", "list", "later", "save"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Show Reading List",
            subtitle: "View reading list items",
            icon: "text.book.closed",
            category: .bookmarks,
            action: .custom("show_reading_list"),
            keywords: ["reading", "list", "show", "view"]
        ),
        
        // History Commands
        VelaPilotCommand(
            title: "Show History",
            subtitle: "View browsing history",
            icon: "clock",
            category: .history,
            action: .custom("show_history"),
            keywords: ["history", "past", "visited"]
        ),
        VelaPilotCommand(
            title: "Clear History",
            subtitle: "Clear browsing history",
            icon: "clock.badge.xmark",
            category: .history,
            action: .custom("clear_history"),
            keywords: ["clear", "history", "delete", "remove"]
        ),
        VelaPilotCommand(
            title: "Clear Recent History",
            subtitle: "Clear history from last hour",
            icon: "clock.arrow.circlepath",
            category: .history,
            action: .custom("clear_recent_history"),
            keywords: ["clear", "recent", "history", "hour"]
        ),
        
        // Downloads
        VelaPilotCommand(
            title: "Show Downloads",
            subtitle: "View download manager",
            icon: "arrow.down.circle",
            category: .downloads,
            action: .custom("show_downloads"),
            keywords: ["downloads", "files", "manager"]
        ),
        VelaPilotCommand(
            title: "Clear Downloads",
            subtitle: "Clear download history",
            icon: "trash.circle",
            category: .downloads,
            action: .custom("clear_downloads"),
            keywords: ["clear", "downloads", "clean"]
        ),
        
        // Developer Commands
        VelaPilotCommand(
            title: "Open Developer Tools",
            subtitle: "Launch web inspector",
            icon: "hammer.fill",
            category: .developer,
            action: .openDevTools,
            keywords: ["dev", "tools", "inspector", "debug"],
            shortcut: "⌘⌥I",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "View Page Source",
            subtitle: "Show HTML source code",
            icon: "doc.text",
            category: .developer,
            action: .custom("view_source"),
            keywords: ["source", "html", "code"],
            shortcut: "⌘⌥U",
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "JavaScript Console",
            subtitle: "Open JavaScript console",
            icon: "terminal",
            category: .developer,
            action: .custom("js_console"),
            keywords: ["javascript", "console", "js"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Network Monitor",
            subtitle: "Monitor network requests",
            icon: "network",
            category: .developer,
            action: .custom("network_monitor"),
            keywords: ["network", "requests", "monitor"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Run Lighthouse Audit",
            subtitle: "Performance and accessibility audit",
            icon: "speedometer",
            category: .developer,
            action: .custom("lighthouse"),
            keywords: ["lighthouse", "audit", "performance", "accessibility"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Clear Site Data",
            subtitle: "Clear cookies and cache for current site",
            icon: "trash",
            category: .developer,
            action: .custom("clear_site_data"),
            keywords: ["clear", "cache", "cookies", "data"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Toggle JavaScript",
            subtitle: "Enable/disable JavaScript for current site",
            icon: "curlybraces",
            category: .developer,
            action: .custom("toggle_js"),
            keywords: ["javascript", "js", "toggle", "disable"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Responsive Design Mode",
            subtitle: "Test responsive layouts",
            icon: "rectangle.on.rectangle",
            category: .developer,
            action: .custom("responsive_mode"),
            keywords: ["responsive", "mobile", "design", "test"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Page Performance",
            subtitle: "Analyze page performance metrics",
            icon: "chart.line.uptrend.xyaxis",
            category: .developer,
            action: .custom("page_performance"),
            keywords: ["performance", "metrics", "speed"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        
        // AI Commands
        VelaPilotCommand(
            title: "Summarize Page",
            subtitle: "AI-powered page summary",
            icon: "brain",
            category: .ai,
            action: .aiSummarize,
            keywords: ["summarize", "ai", "summary", "tldr"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Ask AI About Page",
            subtitle: "Chat with AI about current content",
            icon: "message.badge.waveform",
            category: .ai,
            action: .custom("ai_chat"),
            keywords: ["ai", "ask", "chat", "question"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Extract Key Points",
            subtitle: "Find important information using AI",
            icon: "list.bullet.rectangle",
            category: .ai,
            action: .custom("extract_points"),
            keywords: ["extract", "points", "key", "important"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Translate Page",
            subtitle: "Translate page to another language",
            icon: "globe.badge.chevron.backward",
            category: .ai,
            action: .custom("translate_page"),
            keywords: ["translate", "language", "convert"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Read Aloud",
            subtitle: "Text-to-speech for current page",
            icon: "speaker.wave.2",
            category: .ai,
            action: .custom("read_aloud"),
            keywords: ["read", "aloud", "speech", "voice"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        
        // Privacy & Security
        VelaPilotCommand(
            title: "Private/Incognito Tab",
            subtitle: "Open new private browsing tab",
            icon: "eye.slash",
            category: .privacy,
            action: .custom("private_tab"),
            keywords: ["private", "incognito", "secure"],
            shortcut: "⌘⇧N"
        ),
        VelaPilotCommand(
            title: "Clear All Data",
            subtitle: "Clear all browsing data",
            icon: "trash.circle.fill",
            category: .privacy,
            action: .custom("clear_all_data"),
            keywords: ["clear", "all", "data", "privacy"]
        ),
        VelaPilotCommand(
            title: "Block Trackers",
            subtitle: "Toggle tracker blocking",
            icon: "shield.lefthalf.filled",
            category: .privacy,
            action: .custom("block_trackers"),
            keywords: ["block", "trackers", "privacy", "shield"]
        ),
        VelaPilotCommand(
            title: "Cookie Settings",
            subtitle: "Manage cookie preferences",
            icon: "app.gift",
            category: .privacy,
            action: .custom("cookie_settings"),
            keywords: ["cookies", "settings", "privacy"]
        ),
        
        // Window Management
        VelaPilotCommand(
            title: "New Window",
            subtitle: "Open a new browser window",
            icon: "macwindow",
            category: .window,
            action: .custom("new_window"),
            keywords: ["new", "window", "open"],
            shortcut: "⌘N"
        ),
        VelaPilotCommand(
            title: "Close Window",
            subtitle: "Close current window",
            icon: "xmark.circle",
            category: .window,
            action: .custom("close_window"),
            keywords: ["close", "window"],
            shortcut: "⌘⇧W"
        ),
        VelaPilotCommand(
            title: "Minimize Window",
            subtitle: "Minimize current window",
            icon: "minus.circle",
            category: .window,
            action: .custom("minimize_window"),
            keywords: ["minimize", "window", "hide"],
            shortcut: "⌘M"
        ),
        
        // Integration Commands
        VelaPilotCommand(
            title: "Share to Slack",
            subtitle: "Send current page to Slack",
            icon: "bubble.left.and.bubble.right",
            category: .integrations,
            action: .custom("share_slack"),
            keywords: ["slack", "share", "send"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Save to Notion",
            subtitle: "Add page to Notion workspace",
            icon: "square.and.pencil",
            category: .integrations,
            action: .custom("save_notion"),
            keywords: ["notion", "save", "notes"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Create Calendar Event",
            subtitle: "Schedule meeting with this link",
            icon: "calendar.badge.plus",
            category: .integrations,
            action: .custom("calendar_event"),
            keywords: ["calendar", "meeting", "schedule", "event"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        VelaPilotCommand(
            title: "Add to Todoist",
            subtitle: "Save page as task to Todoist",
            icon: "checkmark.circle",
            category: .integrations,
            action: .custom("add_todoist"),
            keywords: ["todoist", "task", "todo"],
            contextRequirement: .hasCurrentTabWithURL
        ),
        
        // Settings Commands
        VelaPilotCommand(
            title: "Toggle Dark Mode",
            subtitle: "Switch between light and dark themes",
            icon: "moon.fill",
            category: .settings,
            action: .toggleDarkMode,
            keywords: ["dark", "mode", "theme", "light"],
            shortcut: "⌘⇧D"
        ),
        VelaPilotCommand(
            title: "Focus Mode",
            subtitle: "Minimize distractions",
            icon: "eye.slash",
            category: .settings,
            action: .focusMode,
            keywords: ["focus", "distraction", "zen", "minimal"]
        ),
        VelaPilotCommand(
            title: "Restore Session",
            subtitle: "Restore previous browsing session",
            icon: "clock.arrow.circlepath",
            category: .settings,
            action: .restoreSession,
            keywords: ["restore", "session", "tabs", "previous"]
        ),
        VelaPilotCommand(
            title: "Preferences",
            subtitle: "Open browser preferences",
            icon: "gear",
            category: .settings,
            action: .custom("preferences"),
            keywords: ["preferences", "settings", "options"],
            shortcut: "⌘,"
        ),
        VelaPilotCommand(
            title: "Extensions",
            subtitle: "Manage browser extensions",
            icon: "puzzlepiece",
            category: .settings,
            action: .custom("extensions"),
            keywords: ["extensions", "plugins", "addons"]
        ),
        VelaPilotCommand(
            title: "Keyboard Shortcuts",
            subtitle: "View all keyboard shortcuts",
            icon: "keyboard",
            category: .settings,
            action: .custom("shortcuts"),
            keywords: ["keyboard", "shortcuts", "keys", "hotkeys"]
        )
    ]
    
    // Context requirements for commands
    enum ContextRequirement {
        case none
        case hasCurrentTab
        case hasCurrentTabWithURL
        case hasMultipleTabs
        case isLoading
    }
    
    // Get contextually relevant commands based on current browser state
    private func getContextualCommands() -> [VelaPilotCommand] {
        return allCommands.filter { command in
            switch command.contextRequirement {
            case .none:
                return true
            case .hasCurrentTab:
                return browserViewModel.currentTab != nil
            case .hasCurrentTabWithURL:
                return browserViewModel.currentTab?.url != nil
            case .hasMultipleTabs:
                return browserViewModel.tabs.count > 1
            case .isLoading:
                return browserViewModel.currentTab?.isLoading == true
            }
        }
    }
    
    func show() {
        isVisible = true
        searchText = ""
        selectedCommandIndex = 0
        filteredCommands = getContextualCommands()
    }
    
    func hide() {
        isVisible = false
        searchText = ""
        selectedCommandIndex = 0
    }
    
    func updateSearch(_ text: String) {
        searchText = text
        selectedCommandIndex = 0
        
        let contextualCommands = getContextualCommands()
        
        if text.isEmpty {
            filteredCommands = contextualCommands
        } else {
            filteredCommands = contextualCommands.filter { command in
                // Search in title
                if command.title.localizedCaseInsensitiveContains(text) {
                    return true
                }
                // Search in subtitle
                if ((command.subtitle?.localizedCaseInsensitiveContains(text)) != nil) {
                    return true
                }
                // Search in keywords
                return command.keywords.contains { keyword in
                    keyword.localizedCaseInsensitiveContains(text)
                }
            }
        }
    }
    
    func selectNext() {
        DispatchQueue.main.async {
            self.selectedCommandIndex = min(self.selectedCommandIndex + 1, self.filteredCommands.count - 1)
        }
    }
    
    func selectPrevious() {
        DispatchQueue.main.async {
            self.selectedCommandIndex = max(self.selectedCommandIndex - 1, 0)
        }
    }
    
    func executeSelectedCommand() {
        guard selectedCommandIndex < filteredCommands.count else { return }
        let command = filteredCommands[selectedCommandIndex]
        executeCommand(command)
        hide()
        browserViewModel.showCommandPalette = false
    }
    
    // Add this method to get the global index for grouped commands
    func getGlobalIndex(for command: VelaPilotCommand) -> Int? {
        return filteredCommands.firstIndex(of: command)
    }
    
    // Add this method to check if a command is selected
    func isCommandSelected(_ command: VelaPilotCommand) -> Bool {
        guard let globalIndex = getGlobalIndex(for: command) else { return false }
        return globalIndex == selectedCommandIndex
    }
    
    private func executeCommand(_ command: VelaPilotCommand) {
        print("Executing command: \(command.title)")
        
        switch command.action {
        case .openURL(let url):
            browserViewModel.openURL(url)
        case .search(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let searchURL = "https://www.google.com/search?q=\(encodedQuery)"
            browserViewModel.openURL(searchURL)
        case .toggleDarkMode:
            break;
            //  browserViewModel.toggleDarkMode()
        case .openDevTools:
            print("Opening developer tools")
            
            // browserViewModel.openDeveloperTools() // Uncomment if implemented
        case .closeTab:
            browserViewModel.closeCurrentTab()
        case .newTab:
            browserViewModel.createNewTab(shouldReloadTabs: false, focusAddressBar: true)
        case .bookmarkPage:
            print("opening bookmark for selected")
            bookmarkViewModel.showAddBookmarkSheet()
           
        case .aiSummarize:
            break;
            // browserViewModel.summarizePage() // Uncomment if implemented
        case .focusMode:
            break;
            //  browserViewModel.toggleFocusMode()
        case .restoreSession:
            break;
            // browserViewModel.restorePreviousSession()
        case .custom(let action):
            switch action {
                // Tab Commands
            case "reopen_tab":
                browserViewModel.reopenLastClosedTab()
            case "duplicate_tab":
                browserViewModel.duplicateCurrentTab(inBackground: false)
            case "pin_tab":
                if let currentTab = browserViewModel.currentTab {
                    browserViewModel.pinTab(currentTab)
                }
            case "mute_tabs":
                break;
                //   browserViewModel.muteAllTabs()
                // Navigation Commands
            case "open_url":
                browserViewModel.focusAddressBar()
            case "search_web":
                browserViewModel.focusAddressBar()
            case "go_back":
                browserViewModel.goBack()
            case "go_forward":
                browserViewModel.goForward()
            case "reload":
                browserViewModel.reload()
                // Bookmark Commands
            case "show_bookmarks":
                bookmarkViewModel.showAddBookmarkSheet()
            case "reading_list":
                break;
                // browserViewModel.addToReadingList()
                // Developer Commands
            case "view_source":
                break;
                //  browserViewModel.viewPageSource()
            case "lighthouse":
                break;
                print("Running Lighthouse audit")
                // browserViewModel.runLighthouseAudit() // Uncomment if implemented
            case "clear_cache":
                break;
                // browserViewModel.clearCache()
            case "toggle_js":
                browserViewModel.updateJavaScript(enabled: !browserViewModel.isJavaScriptEnabled)
                break;
                
                // AI Commands
            case "ai_chat":
                break;
                print("Initiating AI chat about page")
                // browserViewModel.initiateAIChat() // Uncomment if implemented
            case "extract_points":
                break;
                print("Extracting key points from page")
                // browserViewModel.extractKeyPoints() // Uncomment if implemented
                // Integration Commands
            case "share_slack":
                break;
                //  browserViewModel.shareToSlack()
            case "save_notion":
                break;
                // browserViewModel.saveToNotion()
            case "calendar_event":
                break;
                //    browserViewModel.createCalendarEvent()
            default:
                print("Unhandled custom action: \(action)")
            }
        }
    }
}
