//
//  SuggestionsListView.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//


import SwiftUI

struct SuggestionsListView: View {
    @ObservedObject var suggestionViewModel: SuggestionViewModel
    let onSuggestionSelected: (String) -> Void
    let onEditingChanged: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestionViewModel.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button(action: {
                    let selectedURL = suggestionViewModel.selectSuggestion(suggestion)
                    onSuggestionSelected(selectedURL)
                    suggestionViewModel.clearSuggestions()
                    onEditingChanged(false)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: suggestion.type.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if let subtitle = suggestion.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Type indicator
                        if let url = suggestion.url{
                            Text(url)
                                .font(.system(size: 10))
                                .lineLimit(1)
                                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                .frame(maxWidth: 65)
                        }
                            
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .background(
                    // Highlight selected suggestion for keyboard navigation
                    suggestionViewModel.selectedIndex == index ? 
                    Color.accentColor.opacity(0.1) : Color(NSColor.clear)
                )
                .onHover { isHovered in
                    if isHovered {
                        suggestionViewModel.selectedIndex = index
                    }
                }
                
                if suggestion.id != suggestionViewModel.suggestions.last?.id {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }
        }
        .glassBackground(material: .hudWindow, blendingMode: .behindWindow)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
//        .onReceive(NotificationCenter.default.publisher(for: NSApplication.keyboardNavigationNotification)) { _ in
//            handleKeyboardNavigation()
//        }
    }
    
    private func handleKeyboardNavigation() {
        // Handle keyboard navigation if needed
        // This can be expanded to handle arrow keys, enter, etc.
    }
}

// Extension to add keyboard navigation support
extension SuggestionsListView {
    func handleKeyPress(_ key: KeyEquivalent) -> Bool {
        switch key {
        case .downArrow:
            suggestionViewModel.selectNextSuggestion()
            return true
        case .upArrow:
            suggestionViewModel.selectPreviousSuggestion()
            return true
        case .return:
            if let selectedIndex = suggestionViewModel.selectedIndex,
               selectedIndex < suggestionViewModel.suggestions.count {
                let suggestion = suggestionViewModel.suggestions[selectedIndex]
                let selectedURL = suggestionViewModel.selectSuggestion(suggestion)
                onSuggestionSelected(selectedURL)
                suggestionViewModel.clearSuggestions()
                onEditingChanged(false)
                return true
            }
            return false
        case .escape:
            suggestionViewModel.clearSuggestions()
            onEditingChanged(false)
            return true
        default:
            return false
        }
    }
}
