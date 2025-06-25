//
//  SearchSuggestion.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//
import SwiftUI


enum SuggestionType {
    case url
    case search
    case bookmark
    case history
    case chatGPT
    case question
    
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
        case .chatGPT:
            return "message.circle" 
        case .question:
            return "questionmark.circle"
        }
    }
}

