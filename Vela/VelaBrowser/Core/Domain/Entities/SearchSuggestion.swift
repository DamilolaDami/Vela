//
//  SearchSuggestion.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//
import SwiftUI


struct SearchSuggestion: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let url: String?
    let type: SuggestionType
    
    static func == (lhs: SearchSuggestion, rhs: SearchSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

enum SuggestionType {
    case url
    case search
    case bookmark
    case history
    
    var icon: String {
        switch self {
        case .url:
            return "globe"
        case .search:
            return "magnifyingglass"
        case .bookmark:
            return "heart"
        case .history:
            return "clock"
        }
    }
}
