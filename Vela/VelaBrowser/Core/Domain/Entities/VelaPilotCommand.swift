//
//  VelaPilotCommand.swift
//  Vela
//
//  Created by damilola on 6/1/25.
//

import SwiftUI
import Combine

// MARK: - Command Models
struct VelaPilotCommand: Identifiable, Hashable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let category: CommandCategory
    let action: CommandAction
    let keywords: [String]
    let shortcut: String?
    let contextRequirement: ContextRequirement
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        category: CommandCategory,
        action: CommandAction,
        keywords: [String] = [],
        shortcut: String? = nil,
        contextRequirement: ContextRequirement = .none
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.action = action
        self.keywords = keywords + [title.lowercased()]
        self.shortcut = shortcut
        self.contextRequirement = contextRequirement
    }
    
    static func == (lhs: VelaPilotCommand, rhs: VelaPilotCommand) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Context Requirements
enum ContextRequirement {
    case none
    case hasCurrentTab
    case hasCurrentTabWithURL
    case hasMultipleTabs
    case isLoading
}

// MARK: - Command Categories
enum CommandCategory: String, CaseIterable {
    case navigation = "Navigation"
    case tabs = "Tabs"
    case bookmarks = "Bookmarks"
    case developer = "Developer"
    case ai = "AI Assistant"
    case integrations = "Integrations"
    case settings = "Settings"
    case history = "History"
    case downloads = "Downloads"
    case privacy = "Privacy"
    case window = "Window"
    case pageActions = "Page Actions"
    case search = "Search"
    case display = "Display"
    
    var color: Color {
        switch self {
        case .navigation: return .blue
        case .tabs: return .orange
        case .bookmarks: return .yellow
        case .developer: return .green
        case .ai: return .purple
        case .integrations: return .pink
        case .settings: return .gray
        case .history: return .cyan
        case .downloads: return .indigo
        case .privacy: return .red
        case .window: return .teal
        case .pageActions: return .mint
        case .search: return .blue
        case .display: return .brown
        }
    }
    
    var icon: String {
        switch self {
        case .navigation: return "globe"
        case .tabs: return "rectangle.3.group"
        case .bookmarks: return "bookmark"
        case .developer: return "hammer"
        case .ai: return "brain"
        case .integrations: return "square.grid.3x3"
        case .settings: return "gearshape"
        case .history: return "clock"
        case .downloads: return "arrow.down.circle"
        case .privacy: return "lock.shield"
        case .window: return "macwindow"
        case .pageActions: return "doc"
        case .search: return "magnifyingglass"
        case .display: return "display"
        }
    }
}

// MARK: - Command Actions
enum CommandAction {
    case openURL(String)
    case search(String)
    case toggleDarkMode
    case openDevTools
    case closeTab
    case newTab
    case bookmarkPage
    case aiSummarize
    case focusMode
    case restoreSession
    case custom(String)
}
