//
//  SettingsView.swift
//  Vela
//
//  Created by damilola on 6/18/25.
//

import SwiftUI

struct VelaSettingsView: View {
    @State private var selectedTab = 0
    @State private var isAnimating = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Design tokens for theming and maintainability
    private enum Design {
        static let primaryGradient = LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.08, green: 0.08, blue: 0.15),
                Color(red: 0.12, green: 0.12, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let textGradient = LinearGradient(
            colors: [.white, Color(red: 0.9, green: 0.9, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let glassBackground = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.15)
        static let cornerRadius: CGFloat = 20
        static let padding: CGFloat = 30
        static let compactPadding: CGFloat = 16
        
        // Toolbar specific design tokens
        static let selectedButtonBackground = Color(NSColor.secondarySystemFill)
        static let buttonCornerRadius: CGFloat = 8
    }
    

    
    var body: some View {
        VStack(spacing: 0) {
            // Content area
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Design.primaryGradient.ignoresSafeArea())
        .toolbar(id: "settingsToolbar") {
            // General tab - placed in principal position
            ToolbarItem(id: "general", placement: .principal) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 0
                    }
                } label: {
                    VStack {
                        Image(systemName: "gear")
                        Text("General")
                    }
                    .foregroundStyle(selectedTab == 0 ? .blue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .frame(minWidth: 50, minHeight: 45)
                    .background(
                        selectedTab == 0 ?
                        Design.selectedButtonBackground : Color.clear
                    )
                    .cornerRadius(Design.buttonCornerRadius)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // Links tab
            ToolbarItem(id: "links", placement: .principal) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 1
                    }
                } label: {
                    VStack {
                        Image(systemName: "link")
                        Text("Links")
                    }
                    .foregroundStyle(selectedTab == 1 ? .blue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(minWidth: 50, minHeight: 45)
                    .background(
                        selectedTab == 1 ?
                        Design.selectedButtonBackground : Color.clear
                    )
                    .cornerRadius(Design.buttonCornerRadius)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // Shortcuts tab
            ToolbarItem(id: "shortcuts", placement: .principal) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 2
                    }
                } label: {
                    VStack {
                        Image(systemName: "keyboard")
                        Text("Shortcuts")
                    }
                    
                    .foregroundStyle(selectedTab == 2 ? .blue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(minWidth: 50, minHeight: 45)
                    .background(
                        selectedTab == 2 ?
                        Design.selectedButtonBackground : Color.clear
                    )
                    .cornerRadius(Design.buttonCornerRadius)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // Advanced tab
            ToolbarItem(id: "advanced", placement: .principal) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 3
                    }
                } label: {
                    VStack {
                        Image(systemName: "cpu")
                        Text("Advanced")
                    }
                    .foregroundStyle(selectedTab == 3 ? .blue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(minWidth: 50, minHeight: 45)
                    .background(
                        selectedTab == 3 ?
                        Design.selectedButtonBackground : Color.clear
                    )
                    .cornerRadius(Design.buttonCornerRadius)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .frame(minWidth: horizontalSizeClass == .compact ? 600 : 900, minHeight: 600)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case 0:
            ModernGeneralSettingsView()
        case 1:
            ModernLinksSettingsView()
        case 2:
            ModernSplitShortcutsView()
        case 3:
            ModernAdvancedSettingsView()
        default:
            ModernGeneralSettingsView()
        }
    }
}


struct ModernTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.4, blue: 1.0),
                                Color(red: 0.2, green: 0.6, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else if isHovered {
                        Color.white.opacity(0.15)
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct ModernGeneralSettingsView: View {
    @State private var autoUpdate = true
    @State private var warnBeforeQuitting = true
    @State private var enableNotifications = true
    @State private var darkMode = false
    @StateObject var defaultBroswerMnager = DefaultBrowserManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                ModernSettingsSection(title: "Application", icon: "app.fill", iconColor: .blue) {
                    ModernSettingsToggle(
                        title: "Automatically update Vela",
                        subtitle: "Get the latest features and security updates",
                        isOn: $autoUpdate
                    )
                    
                    ModernSettingsToggle(
                        title: "Warn before quitting",
                        subtitle: "Prevent accidental closure of important sessions",
                        isOn: $warnBeforeQuitting
                    )
                    
                    ModernSettingsToggle(
                        title: "Enable notifications",
                        subtitle: "Get notified about downloads and updates",
                        isOn: $enableNotifications
                    )
                    
                    // Default Browser Setting
                    if !defaultBroswerMnager.isDefault{
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Default Browser")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Vela is not your default browser")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                           
                                Button("Make Default") {
                                    // Action to make Vela default browser
                                    makeDefaultBrowser()
                                }
                                .buttonStyle(ModernAccentButtonStyle())
                            
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.03))
                    }
                }
                
                ModernSettingsSection(title: "Appearance", icon: "paintbrush.fill", iconColor: .purple) {
                    ModernSettingsToggle(
                        title: "Dark mode",
                        subtitle: "Use dark interface colors",
                        isOn: $darkMode
                    )
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Theme Settings")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Customize your browsing experience")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button("Customize") {
                            // Action
                        }
                        .buttonStyle(ModernAccentButtonStyle())
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.03))
                }
            }
            .padding(30)
        }
    }
    
    private func makeDefaultBrowser() {
        defaultBroswerMnager.setAsDefault()
    }
}

struct ModernLinksSettingsView: View {
    @State private var openLittleVela = true
    @State private var linksInLittleVela = true
    @State private var peekEnabled = true
    @State private var archiveAfter = "6 hours"
    
    let archiveOptions = ["1 hour", "3 hours", "6 hours", "12 hours", "1 day", "Never"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Little Vela Preview
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "macwindow")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Text("Little Vela")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Animated browser mockup
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.3),
                                        Color.pink.opacity(0.3),
                                        Color.purple.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 140)
                        
                        VStack(spacing: 12) {
                            // Browser window mockup
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.95))
                                .frame(width: 320, height: 80)
                                .overlay(
                                    VStack(spacing: 8) {
                                        HStack(spacing: 6) {
                                            Circle().fill(Color.red.opacity(0.8)).frame(width: 10, height: 10)
                                            Circle().fill(Color.yellow.opacity(0.8)).frame(width: 10, height: 10)
                                            Circle().fill(Color.green.opacity(0.8)).frame(width: 10, height: 10)
                                            Spacer()
                                            Text("vela.app")
                                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                .foregroundColor(.gray)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 8)
                                        
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 20)
                                            .cornerRadius(4)
                                            .padding(.horizontal, 12)
                                        
                                        Spacer()
                                    }
                                )
                            
                            Text("A smaller, focused window for quick browsing")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                ModernSettingsSection(title: "Little Vela", icon: "rectangle.inset.filled", iconColor: .orange) {
                    ModernSettingsToggle(
                        title: "Enable Little Vela shortcuts",
                        subtitle: "Press ⌃⌘N to open a compact browsing window",
                        isOn: $openLittleVela
                    )
                    
                    ModernSettingsToggle(
                        title: "Open external links in Little Vela",
                        subtitle: "Links from other apps open in a compact window",
                        isOn: $linksInLittleVela
                    )
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-archive after")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Automatically close idle Little Vela windows")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Picker("", selection: $archiveAfter) {
                            ForEach(archiveOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.03))
                }
                
                ModernSettingsSection(title: "Peek Preview", icon: "eye.fill", iconColor: .cyan) {
                    ModernSettingsToggle(
                        title: "Enable Peek preview",
                        subtitle: "Hold Shift and click links for quick preview",
                        isOn: $peekEnabled
                    )
                }
            }
            .padding(30)
        }
    }
}


struct ShortcutItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let shortcut: String
    let category: String
    let description: String
    let isActive: Bool
    
    init(name: String, shortcut: String, category: String, description: String, isActive: Bool = true) {
        self.name = name
        self.shortcut = shortcut
        self.category = category
        self.description = description
        self.isActive = isActive
    }
}

struct ModernSplitShortcutsView: View {
    @State private var searchText = ""
    @State private var selectedShortcut: ShortcutItem?
    
    let shortcuts = [
        // File Menu
        ShortcutItem(name: "New Tab", shortcut: "⌘T", category: "File",
                    description: "Opens a new tab in the current window. The new tab will be placed next to the currently active tab."),
        ShortcutItem(name: "New Tab in Background", shortcut: "⇧⌘T", category: "File",
                    description: "Creates a new tab without switching focus to it. Useful for opening multiple links while staying on your current page."),
        ShortcutItem(name: "New Window", shortcut: "⌘N", category: "File",
                    description: "Opens a completely new browser window. Each window operates independently with its own tabs and session."),
        ShortcutItem(name: "New Incognito Window", shortcut: "⇧⌘N", category: "File",
                    description: "Opens a private browsing window where your browsing history, cookies, and site data won't be saved."),
        ShortcutItem(name: "Close Tab", shortcut: "⌘W", category: "File",
                    description: "Closes the currently active tab. If it's the last tab in the window, the entire window will close."),
        ShortcutItem(name: "Close Other Tabs", shortcut: "⌥⌘W", category: "File",
                    description: "Closes all tabs except the currently active one. Useful for decluttering when you have many tabs open."),
        ShortcutItem(name: "Close Window", shortcut: "⇧⌘W", category: "File",
                    description: "Closes the entire browser window and all its tabs. A confirmation dialog may appear if multiple tabs are open."),
        
        // Edit Menu
        ShortcutItem(name: "Duplicate Tab", shortcut: "⇧⌘K", category: "Edit",
                    description: "Creates an exact copy of the current tab, including its browsing history and scroll position."),
        ShortcutItem(name: "Focus Address Bar", shortcut: "⌘L", category: "Edit",
                    description: "Moves the cursor to the address/URL bar, allowing you to quickly type a new web address or search query."),
        ShortcutItem(name: "Find in Page", shortcut: "⌘F", category: "Edit",
                    description: "Opens the find dialog to search for specific text within the current webpage. Results are highlighted as you type."),
        ShortcutItem(name: "Find Next", shortcut: "⌘G", category: "Edit",
                    description: "Jumps to the next occurrence of your search term when using Find in Page."),
        ShortcutItem(name: "Find Previous", shortcut: "⇧⌘G", category: "Edit",
                    description: "Jumps to the previous occurrence of your search term when using Find in Page."),
        
        // View Menu
        ShortcutItem(name: "Settings", shortcut: "⌘,", category: "View",
                    description: "Opens the browser's preferences and settings panel where you can customize various options."),
        ShortcutItem(name: "Toggle Sidebar", shortcut: "⇧⌘S", category: "View",
                    description: "Shows or hides the sidebar which may contain bookmarks, history, or other navigation tools."),
        ShortcutItem(name: "Toggle Full Screen", shortcut: "⌃⌘F", category: "View",
                    description: "Switches between full screen and windowed mode. In full screen, the browser takes up the entire display."),
        ShortcutItem(name: "Select Next Tab", shortcut: "⇧⌘]", category: "View",
                    description: "Switches to the tab to the right of the current tab. Cycles back to the first tab when at the end."),
        ShortcutItem(name: "Select Previous Tab", shortcut: "⇧⌘[", category: "View",
                    description: "Switches to the tab to the left of the current tab. Cycles to the last tab when at the beginning."),
        ShortcutItem(name: "Zoom In", shortcut: "⌘+", category: "View",
                    description: "Increases the zoom level of the current webpage, making text and images appear larger."),
        ShortcutItem(name: "Zoom Out", shortcut: "⌘-", category: "View",
                    description: "Decreases the zoom level of the current webpage, making text and images appear smaller."),
        ShortcutItem(name: "Reset Zoom", shortcut: "⌘0", category: "View",
                    description: "Resets the zoom level to 100% (default size) for the current webpage."),
        
        // Navigation Menu
        ShortcutItem(name: "Back", shortcut: "⌘[", category: "Navigation",
                    description: "Navigates back to the previous page in your browsing history for the current tab."),
        ShortcutItem(name: "Forward", shortcut: "⌘]", category: "Navigation",
                    description: "Navigates forward to the next page in your browsing history (only works after going back)."),
        ShortcutItem(name: "Reload", shortcut: "⌘R", category: "Navigation",
                    description: "Refreshes the current webpage, reloading it from the server to get the latest version."),
        ShortcutItem(name: "Reload Ignoring Cache", shortcut: "⇧⌘R", category: "Navigation",
                    description: "Performs a hard refresh, bypassing the browser cache to ensure you get the very latest version of the page."),
        ShortcutItem(name: "Stop Loading", shortcut: "⌘.", category: "Navigation",
                    description: "Stops loading the current webpage if it's taking too long or if you want to cancel the request."),
        ShortcutItem(name: "Home", shortcut: "⇧⌘H", category: "Navigation",
                    description: "Navigates to your configured home page or start page."),
        
        // Pilot Menu
        ShortcutItem(name: "Show/Hide Pilot", shortcut: "⌘K", category: "Pilot",
                    description: "Toggles the Pilot command palette, which provides quick access to browser functions and commands."),
        
        // History Menu
        ShortcutItem(name: "Show All History", shortcut: "⌘Y", category: "History",
                    description: "Opens the full browsing history view where you can search and navigate through previously visited pages."),
        ShortcutItem(name: "Reopen Last Closed Tab", shortcut: "⇧⌥⌘T", category: "History",
                    description: "Restores the most recently closed tab, including its history and scroll position."),
        
        // Bookmarks Menu
        ShortcutItem(name: "Add Bookmark", shortcut: "⌘D", category: "Bookmarks",
                    description: "Saves the current webpage to your bookmarks for quick access later."),
        ShortcutItem(name: "Show All Bookmarks", shortcut: "⇧⌘B", category: "Bookmarks",
                    description: "Opens the bookmarks manager where you can organize, edit, and access all your saved bookmarks."),
        ShortcutItem(name: "Bookmark All Tabs", shortcut: "⇧⌘D", category: "Bookmarks",
                    description: "Creates bookmarks for all currently open tabs, typically organized in a new folder."),
        
        // Spaces Menu
        ShortcutItem(name: "New Space", shortcut: "⌃⌘N", category: "Spaces",
                    description: "Creates a new workspace or space where you can organize related tabs and browsing sessions."),
        ShortcutItem(name: "Switch to Next Space", shortcut: "⌃⌘→", category: "Spaces",
                    description: "Moves to the next workspace in your spaces collection."),
        ShortcutItem(name: "Switch to Previous Space", shortcut: "⌃⌘←", category: "Spaces",
                    description: "Moves to the previous workspace in your spaces collection."),
        ShortcutItem(name: "Move Tab to New Space", shortcut: "⇧⌘M", category: "Spaces",
                    description: "Moves the current tab to a new workspace, helping you organize your browsing sessions."),
        ShortcutItem(name: "Show All Spaces", shortcut: "⌃⌘S", category: "Spaces",
                    description: "Opens an overview of all your workspaces, allowing you to switch between them or manage their contents.")
    ]
    
    var filteredShortcuts: [ShortcutItem] {
        if searchText.isEmpty {
            return shortcuts
        }
        return shortcuts.filter { shortcut in
            shortcut.name.localizedCaseInsensitiveContains(searchText) ||
            shortcut.shortcut.localizedCaseInsensitiveContains(searchText) ||
            shortcut.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var groupedShortcuts: [String: [ShortcutItem]] {
        Dictionary(grouping: filteredShortcuts) { $0.category }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar - Shortcuts list
            VStack(alignment: .leading, spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Type a feature name or shortcut", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Default Shortcuts Header
                Text("Default Shortcuts")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
                // Shortcuts list
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredShortcuts, id: \.id) { shortcut in
                            ShortcutListRow(
                                shortcut: shortcut,
                                isSelected: selectedShortcut?.id == shortcut.id
                            ) {
                                selectedShortcut = shortcut
                            }
                        }
                    }
                }
            }
            .frame(width: 380)
            VStack {
            }
            .frame(width: 4)
            .background(Color.white.opacity(0.08))
            
            // Right panel - Shortcut details
            VStack(alignment: .leading, spacing: 0) {
                if let selected = selectedShortcut {
                    ShortcutDetailPanel(shortcut: selected)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Select a shortcut")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Choose a keyboard shortcut from the list to see its description and usage details.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
//            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        }
        .onAppear {
            // Select first shortcut by default
            if selectedShortcut == nil && !shortcuts.isEmpty {
                selectedShortcut = shortcuts.first
            }
        }
    }
}

struct ShortcutListRow: View {
    let shortcut: ShortcutItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(shortcut.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !shortcut.isActive {
                        Text("Not assigned")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                // Shortcut display
                if shortcut.isActive {
                    Text(shortcut.shortcut.isEmpty ? "---" : shortcut.shortcut)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
                        )
                } else {
                    Text("---")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShortcutDetailPanel: View {
    let shortcut: ShortcutItem
    
    // Helper function to parse shortcut keys
    private func parseShortcutKeys(_ shortcutString: String) -> [String] {
        let keyMapping: [String: String] = [
            "⌘": "command",
            "⇧": "shift",
            "⌥": "option",
            "⌃": "control"
        ]
        
        var keys: [String] = []
        var remaining = shortcutString
        
        // Extract modifier keys first
        for (symbol, name) in keyMapping {
            if remaining.contains(symbol) {
                keys.append(name)
                remaining = remaining.replacingOccurrences(of: symbol, with: "")
            }
        }
        
        // Add the final key (letter/number/symbol)
        if !remaining.isEmpty {
            keys.append(remaining.lowercased())
        }
        
        return keys
    }
    
    // Helper function to get system image for key
    private func getSystemImageForKey(_ key: String) -> String {
        switch key.lowercased() {
        case "command": return "command"
        case "shift": return "shift"
        case "option": return "option"
        case "control": return "control"
        case "t": return "t.square"
        case "n": return "n.square"
        case "w": return "w.square"
        case "l": return "l.square"
        case "f": return "f.square"
        case "g": return "g.square"
        case "r": return "r.square"
        case "d": return "d.square"
        case "k": return "k.square"
        case "y": return "y.square"
        case "b": return "b.square"
        case "m": return "m.square"
        case "s": return "s.square"
        case "h": return "h.square"
        case "[": return "bracketleft"
        case "]": return "bracketright"
        case "+": return "plus"
        case "-": return "minus"
        case "0": return "0.square"
        case ",": return "comma"
        case ".": return "period"
        case "→": return "arrow.right"
        case "←": return "arrow.left"
        default: return "questionmark.square"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with dynamic navigation buttons
            HStack {
                // Dynamic shortcut key buttons
                let parsedKeys = parseShortcutKeys(shortcut.shortcut)
                
                HStack(spacing: 8) {
                    ForEach(Array(parsedKeys.enumerated()), id: \.offset) { index, key in
                        Button(action: {}) {
                            Image(systemName: getSystemImageForKey(key))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.separator.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                        }
                        .buttonStyle(KeyboardButtonStyle())
                        
                        // Add plus symbol between keys (except for the last one)
                        if index < parsedKeys.count - 1 {
                            Text("+")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(shortcut.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Category badge
                Text(shortcut.category)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.2))
                    )
                
                // Description
                Text(shortcut.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct KeyboardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernAdvancedSettingsView: View {
    @State private var soundEffects = true
    @State private var hapticFeedback = true
    @State private var developerMode = false
    @State private var experimentalFeatures = false
    @State private var restoreWindows = true
    @State private var allowWindowDragging = true
    @State private var showFullURL = true
    @State private var enableSharedQuotes = true
    @State private var enablePictureInPicture = true
    @State private var allowThemeData = false
    @State private var enableBoosts = true
    @State private var systemInfo: [String: String] = [:]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                ModernSettingsSection(title: "Experience", icon: "sparkles", iconColor: .yellow) {
                    ModernSettingsToggle(
                        title: "Sound effects",
                        subtitle: "Play audio feedback for actions",
                        isOn: $soundEffects
                    )
                    
                    ModernSettingsToggle(
                        title: "Haptic feedback",
                        subtitle: "Feel subtle vibrations for interactions",
                        isOn: $hapticFeedback
                    )
                }
                
                ModernSettingsSection(title: "Developer", icon: "hammer.fill", iconColor: .red) {
                    ModernSettingsToggle(
                        title: "Developer mode",
                        subtitle: "Enable advanced debugging features",
                        isOn: $developerMode
                    )
                    
                    ModernSettingsToggle(
                        title: "Experimental features",
                        subtitle: "Try new features before they're released",
                        isOn: $experimentalFeatures
                    )
                }
                
                ModernSettingsSection(title: "Browser Behavior", icon: "safari.fill", iconColor: .green) {
                    ModernSettingsToggle(
                        title: "Restore windows from previous session",
                        subtitle: "Reopen windows when starting the app",
                        isOn: $restoreWindows
                    )
                    
                    ModernSettingsToggle(
                        title: "Allow window dragging from top of webpages",
                        subtitle: "Enable dragging windows from webpage tops",
                        isOn: $allowWindowDragging
                    )
                    
                    ModernSettingsToggle(
                        title: "Show full URL when Toolbar is enabled",
                        subtitle: "Display complete URL in the address bar",
                        isOn: $showFullURL
                    )
                }
                
                ModernSettingsSection(title: "Sharing & Media", icon: "square.and.arrow.up.fill", iconColor: .purple) {
                    ModernSettingsToggle(
                        title: "Enable Shared Quotes when highlighting text",
                        subtitle: "Share highlighted text easily",
                        isOn: $enableSharedQuotes
                    )
                    
                    ModernSettingsToggle(
                        title: "Enable Picture in Picture when you leave a video tab",
                        subtitle: "Keep videos playing in a small window",
                        isOn: $enablePictureInPicture
                    )
                }
                
                ModernSettingsSection(title: "Privacy", icon: "lock.fill", iconColor: .blue) {
                    ModernSettingsToggle(
                        title: "Allow websites to get your theme data",
                        subtitle: "Share theme preferences with websites",
                        isOn: $allowThemeData
                    )
                }
               
                
                // System info section with real-time data
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("System Information")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 12) {
                        if let version = systemInfo["Version"] {
                            SystemInfoRow(label: "Version", value: version)
                        }
                        if let build = systemInfo["Build"] {
                            SystemInfoRow(label: "Build", value: build)
                        }
                        if let webKit = systemInfo["WebKit"] {
                            SystemInfoRow(label: "WebKit", value: webKit)
                        }
                        if let platform = systemInfo["Platform"] {
                            SystemInfoRow(label: "Platform", value: platform)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 30)
            .task {
                fetchSystemInfo()
            }
        }
    }
    
    private func fetchSystemInfo() {
        let task = Process()
        task.launchPath = "/usr/bin/sw_vers"
        task.arguments = []
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            var info: [String: String] = [:]
            output.enumerateLines { line, _ in
                let components = line.split(separator: ":")
                if components.count == 2 {
                    let key = String(components[0].trimmingCharacters(in: .whitespaces))
                    let value = String(components[1].trimmingCharacters(in: .whitespaces))
                    info[key] = value
                }
            }
            systemInfo["Version"] = info["ProductVersion"]
            systemInfo["Build"] = info["BuildVersion"]
            systemInfo["Platform"] = "macOS \(info["ProductVersion"] ?? "Unknown")"
            // WebKit version requires a different approach, e.g., via Safari or a WebView
            systemInfo["WebKit"] = "N/A" // Placeholder; requires WebView inspection
        }
    }
}

// MARK: - Helper Views

struct ModernSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct ModernSettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(ModernToggleStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.03))
    }
}

struct ModernShortcutRow: View {
    let shortcut: ShortcutItem
    let isEven: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(shortcut.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(shortcut.shortcut)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(isEven ? Color.white.opacity(0.02) : Color.clear)
    }
}

struct SystemInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}


// MARK: - Custom Styles

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Button(action: {
                configuration.isOn.toggle()
            }) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ?
                          LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)], startPoint: .leading, endPoint: .center))
                    .frame(width: 44, height: 26)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(x: configuration.isOn ? 8 : -8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: configuration.isOn)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ModernAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Alternative Implementation with Singleton Pattern
class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    var windowController: NSWindowController?
    
    private init() {}
    
    @MainActor func showSettings() {
        if let existingController = windowController {
            existingController.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        let settingsView = VelaSettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Settings"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        
        let windowController = NSWindowController(window: window)
        self.windowController = windowController
        
        // Set up window delegate to clean up when closed
        window.delegate = SettingsWindowDelegate.shared
        
        windowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}

class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowDelegate()
    
    func windowWillClose(_ notification: Notification) {
        SettingsWindowManager.shared.windowController = nil
    }
}

// MARK: - Usage in AppDelegate
extension VelaAppDelegate {
    @MainActor @objc func openSettingsWindowAlternative(_ sender: Any?) {
        SettingsWindowManager.shared.showSettings()
    }
}
