//
//  QueryType.swift
//  Vela
//
//  Created by damilola on 6/22/25.
//

import Foundation


enum QueryType: String, CaseIterable {
    case url = "url"
    case calculation = "calculation"
    case unitConversion = "unit_conversion"
    case weatherQuery = "weather"
    case timeQuery = "time"
    case quickAnswer = "quick_answer"
    case search = "search"
    case command = "command"
    case bookmark = "bookmark"
    case history = "history"
    case tab = "tab"
    
    var icon: String {
        switch self {
        case .url: return "link"
        case .calculation: return "plus.forwardslash.minus"
        case .unitConversion: return "arrow.left.arrow.right"
        case .weatherQuery: return "cloud.sun"
        case .timeQuery: return "clock"
        case .quickAnswer: return "lightbulb"
        case .search: return "magnifyingglass"
        case .command: return "terminal"
        case .bookmark: return "bookmark"
        case .history: return "clock.arrow.circlepath"
        case .tab: return "square.stack"
        }
    }
    
    var priority: Int {
        switch self {
        case .quickAnswer, .calculation, .unitConversion: return 100
        case .url: return 90
        case .command: return 85
        case .weatherQuery, .timeQuery: return 80
        case .bookmark: return 70
        case .history: return 60
        case .tab: return 55
        case .search: return 50
        }
    }
}

struct SearchSuggestion: Identifiable, Hashable, Observable{
    let id = UUID()
    let title: String
    let subtitle: String?
    let url: String?
    let type: QueryType
    let icon: String?
    let metadata: [String: String]?
    let preview: PreviewData?
    var relevanceScore: Double
    let timestamp: Date
    
    init(
        title: String,
        subtitle: String? = nil,
        url: String? = nil,
        type: QueryType = .search,
        icon: String? = nil,
        metadata: [String: String]? = nil,
        preview: PreviewData? = nil,
        relevanceScore: Double = 0.5,
        timestamp: Date = Date()
    ) {
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.type = type
        self.icon = icon
        self.metadata = metadata
        self.preview = preview
        self.relevanceScore = relevanceScore
        self.timestamp = timestamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(type)
        hasher.combine(url)
    }
    
    static func == (lhs: SearchSuggestion, rhs: SearchSuggestion) -> Bool {
        lhs.title == rhs.title && lhs.type == rhs.type && lhs.url == rhs.url
    }
}

struct PreviewData {
    let text: String?
    let imageURL: String?
    let data: [String: Any]?
}

// MARK: - Search Commands

enum SearchCommand: String, CaseIterable {
    case bookmarks = "bm"
    case history = "h"
    case tabs = "t"
    case downloads = "dl"
    case settings = "set"
    case calculator = "calc"
    case weather = "w"
    case translate = "tr"
    
    var description: String {
        switch self {
        case .bookmarks: return "Search bookmarks"
        case .history: return "Search browsing history"
        case .tabs: return "Search open tabs"
        case .downloads: return "Search downloads"
        case .settings: return "Open settings"
        case .calculator: return "Calculator"
        case .weather: return "Weather"
        case .translate: return "Translate"
        }
    }
    
    var placeholder: String {
        switch self {
        case .bookmarks: return "bm search term"
        case .history: return "h search term"
        case .tabs: return "t search term"
        case .downloads: return "dl search term"
        case .settings: return "set preference"
        case .calculator: return "calc 2+2"
        case .weather: return "w location"
        case .translate: return "tr hello to spanish"
        }
    }
}

// MARK: - Analytics Models

struct SearchAnalyticsEvent {
    let query: String
    let suggestion: SearchSuggestion?
    let action: SearchAction
    let timestamp: Date
    let responseTime: TimeInterval?
    let position: Int?
}

enum SearchAction {
    case query
    case suggestionClick
    case autocompleteAccept
    case voiceSearch
    case commandUse
}

// MARK: - Cache Models

class CachedSuggestions {
    let suggestions: [SearchSuggestion]
    let timestamp: Date
    let expirationDate: Date
    let popularity: Double
    
    init(suggestions: [SearchSuggestion], popularity: Double = 0.5) {
        self.suggestions = suggestions
        self.timestamp = Date()
        self.expirationDate = Date().addingTimeInterval(300) // 5 minutes
        self.popularity = popularity
    }
    
    var isExpired: Bool {
        Date() > expirationDate
    }
}

// MARK: - User Preferences

struct UserPreferences {
    let preferredSearchEngine: String
    let enableVoiceSearch: Bool
    let enableQuickAnswers: Bool
    let enableWeatherSuggestions: Bool
    let preferredUnits: UnitSystem
    let location: String?
    let recentSearches: [String]
    let favoriteCommands: [SearchCommand]
}

enum UnitSystem: String, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"
}

// MARK: - Context Models

struct SearchContext {
    let currentURL: String?
    let timeOfDay: TimeOfDay
    let dayOfWeek: DayOfWeek
    let userLocation: String?
    let recentActivity: [String]
    let openTabs: [String]
}

enum TimeOfDay: String, CaseIterable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

enum DayOfWeek: String, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    static var current: DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let days: [DayOfWeek] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        return days[weekday - 1]
    }
}
