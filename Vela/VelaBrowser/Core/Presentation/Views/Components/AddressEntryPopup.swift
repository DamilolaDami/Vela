//
//  AddressEntryPopup.swift
//  Vela
//
//  Created by damilola on 6/18/25.
//

import SwiftUI
import AppKit

struct AddressEntryPopup: View {
    @Binding var isPresented: Bool
    @Binding var addressText: String
    let onURLSubmit: (String) -> Void
    
    @ObservedObject var suggestionVM: AddressBarViewModel
    @State private var searchText: String = ""
    @State private var autocompleteText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // Dynamic width calculation
    private var dynamicWidth: CGFloat {
        let baseWidth: CGFloat = 380
        let maxWidth: CGFloat = 500
        let textLength = searchText.count
        
        // Start growing after 30 characters, reach max at 80 characters
        let growthStartLength = 30
        let growthEndLength = 80
        
        if textLength <= growthStartLength {
            return baseWidth
        }
        
        let growthRange = growthEndLength - growthStartLength
        let currentGrowth = min(textLength - growthStartLength, growthRange)
        let growthRatio = CGFloat(currentGrowth) / CGFloat(growthRange)
        
        return baseWidth + (maxWidth - baseWidth) * growthRatio
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar with autocomplete
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                AutocompleteTextField(
                    text: $searchText,
                    autocompleteText: $autocompleteText,
                    placeholder: "Search or Enter URL...",
                    onSubmit: {
                        handleSubmit()
                    },
                    onTextChange: { newValue in
                        suggestionVM.fetchSuggestions(for: newValue)
                        updateAutocomplete()
                    }
                )
                .focused($isTextFieldFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Show suggestions if typing
                        if !searchText.isEmpty && suggestionVM.isShowingSuggestions {
                            ForEach(Array(suggestionVM.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                                SuggestionRow(
                                    suggestion: suggestion,
                                    isSelected: suggestionVM.selectedIndex == index,
                                    searchQuery: searchText
                                ) {
                                    handleSuggestionTap(suggestion)
                                }
                                .id(index) // Add ID for scrolling
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .onChange(of: suggestionVM.selectedIndex) { oldValue, newValue in
                    // Auto-scroll to selected item
                    if let selectedIndex = newValue {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(selectedIndex, anchor: .center)
                        }
                    }
                    // Update autocomplete when selection changes
                    updateAutocomplete()
                }
            }
        }
        .frame(width: dynamicWidth, height: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
        .animation(.easeInOut(duration: 0.15), value: dynamicWidth) // Smooth width transition
        .onAppear {
            // Auto-fill with current URL if available
            searchText = addressText
            isTextFieldFocused = true
        }
        .onKeyPress(.downArrow) {
            suggestionVM.selectNextSuggestion()
            return .handled
        }
        .onKeyPress(.upArrow) {
            suggestionVM.selectPreviousSuggestion()
            return .handled
        }
        .onKeyPress(.return) {
            handleSubmit()
            return .handled
        }
        .onKeyPress(.escape) {
            DispatchQueue.main.async {
                self.isPresented = false
            }
            return .handled
        }
        .onKeyPress(.tab) {
            // Accept autocomplete suggestion
            if !autocompleteText.isEmpty {
                searchText = autocompleteText
                autocompleteText = ""
                suggestionVM.fetchSuggestions(for: searchText)
            }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            // Accept autocomplete on right arrow (like Safari)
            if !autocompleteText.isEmpty && searchText.count < autocompleteText.count {
                searchText = autocompleteText
                autocompleteText = ""
                suggestionVM.fetchSuggestions(for: searchText)
                return .handled
            }
            return .ignored
        }
    }
    
    private func updateAutocomplete() {
        guard !searchText.isEmpty else {
            autocompleteText = ""
            return
        }
        
        // Get the best matching suggestion for autocomplete
        let bestMatch: String?
        
        if let selectedIndex = suggestionVM.selectedIndex,
           selectedIndex < suggestionVM.suggestions.count {
            // Use selected suggestion
            let selectedSuggestion = suggestionVM.suggestions[selectedIndex]
            bestMatch = selectedSuggestion.url ?? selectedSuggestion.title
        } else if let firstSuggestion = suggestionVM.suggestions.first {
            // Use first suggestion if none selected
            bestMatch = firstSuggestion.url ?? firstSuggestion.title
        } else {
            bestMatch = nil
        }
        
        if let match = bestMatch,
           match.lowercased().hasPrefix(searchText.lowercased()),
           match.count > searchText.count {
            autocompleteText = match
        } else {
            autocompleteText = ""
        }
    }
    
    private func handleSubmit() {
        let textToSubmit: String
        
        // If there's autocomplete text, use it
        if !autocompleteText.isEmpty {
            textToSubmit = autocompleteText
        } else if let selectedIndex = suggestionVM.selectedIndex,
                  selectedIndex < suggestionVM.suggestions.count {
            // Use selected suggestion
            let selectedSuggestion = suggestionVM.suggestions[selectedIndex]
            textToSubmit = selectedSuggestion.url ?? selectedSuggestion.title
        } else {
            // Use typed text
            textToSubmit = searchText
        }
        
        self.addressText = textToSubmit
        onURLSubmit(textToSubmit) // Add this to trigger navigation
        isPresented = false
        suggestionVM.clearSuggestions()
    }
    
    private func handleSuggestionTap(_ suggestion: SearchSuggestion) {
        let urlString = suggestionVM.selectSuggestion(suggestion)
        onURLSubmit(urlString)
        isPresented = false
    }
}
// MARK: - Custom Autocomplete TextField

struct AutocompleteTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var autocompleteText: String
    let placeholder: String
    let onSubmit: () -> Void
    let onTextChange: (String) -> Void
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.font = NSFont.systemFont(ofSize: 16)
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear
        textField.focusRingType = .none
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        let customField = nsView as! CustomTextField
        
        // Only update if the text actually changed to avoid cursor jumping
        if customField.userText != text {
            customField.userText = text
            nsView.stringValue = text
        }
        
        // Update autocomplete
        customField.setAutocomplete(autocompleteText, userText: text)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: AutocompleteTextField
        
        init(_ parent: AutocompleteTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? CustomTextField {
                let currentText = textField.stringValue
                
                // Check if user is typing (not just selecting autocomplete)
                if let editor = textField.currentEditor() {
                    let selectedRange = editor.selectedRange
                    
                    // If there's a selection at the end, it's likely autocomplete
                    if selectedRange.length > 0 && selectedRange.location + selectedRange.length == currentText.count {
                        // User typed, update only the user portion
                        let userPortion = String(currentText.prefix(selectedRange.location))
                        textField.userText = userPortion
                        parent.text = userPortion
                        parent.onTextChange(userPortion)
                    } else {
                        // Normal typing, update everything
                        textField.userText = currentText
                        parent.text = currentText
                        parent.onTextChange(currentText)
                    }
                } else {
                    textField.userText = currentText
                    parent.text = currentText
                    parent.onTextChange(currentText)
                }
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

class CustomTextField: NSTextField {
    private var autocompleteText: String = ""
    var userText: String = ""
    private var isSettingAutocomplete = false
    
    func setAutocomplete(_ autocomplete: String, userText: String) {
        guard !isSettingAutocomplete else { return } // Prevent recursion
        
        self.autocompleteText = autocomplete
        self.userText = userText
        
        guard !autocomplete.isEmpty && !userText.isEmpty else {
            if self.stringValue != userText {
                isSettingAutocomplete = true
                self.stringValue = userText
                isSettingAutocomplete = false
            }
            return
        }
        
        // Only show autocomplete if it starts with user text
        guard autocomplete.lowercased().hasPrefix(userText.lowercased()) else {
            if self.stringValue != userText {
                isSettingAutocomplete = true
                self.stringValue = userText
                isSettingAutocomplete = false
            }
            return
        }
        
        // Set the full text only if it's different
        if self.stringValue != autocomplete {
            isSettingAutocomplete = true
            self.stringValue = autocomplete
            isSettingAutocomplete = false
        }
        
        // Select the autocomplete part
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let textEditor = self.currentEditor() {
                let userTextLength = userText.count
                let totalLength = autocomplete.count
                
                if totalLength > userTextLength {
                    let range = NSRange(location: userTextLength, length: totalLength - userTextLength)
                    textEditor.selectedRange = range
                }
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle special keys
        switch event.keyCode {
        case 36: // Return key
            // Accept the full text
            if !autocompleteText.isEmpty {
                isSettingAutocomplete = true
                self.stringValue = autocompleteText
                self.userText = autocompleteText
                isSettingAutocomplete = false
                
                // Move cursor to end
                if let textEditor = self.currentEditor() {
                    textEditor.selectedRange = NSRange(location: autocompleteText.count, length: 0)
                }
            }
            super.keyDown(with: event)
            
        case 48: // Tab key
            // Accept autocomplete
            if !autocompleteText.isEmpty {
                isSettingAutocomplete = true
                self.stringValue = autocompleteText
                self.userText = autocompleteText
                isSettingAutocomplete = false
                
                if let textEditor = self.currentEditor() {
                    textEditor.selectedRange = NSRange(location: autocompleteText.count, length: 0)
                }
            }
            
        case 124: // Right arrow
            // Accept autocomplete if there's a selection
            if let textEditor = self.currentEditor() {
                let selectedRange = textEditor.selectedRange
                if selectedRange.length > 0 && !autocompleteText.isEmpty {
                    isSettingAutocomplete = true
                    self.stringValue = autocompleteText
                    self.userText = autocompleteText
                    isSettingAutocomplete = false
                    
                    textEditor.selectedRange = NSRange(location: autocompleteText.count, length: 0)
                    return
                }
            }
            super.keyDown(with: event)
            
        case 51, 117: // Delete/Backspace
            // Clear autocomplete when deleting
            if let textEditor = self.currentEditor() {
                let selectedRange = textEditor.selectedRange
                if selectedRange.length > 0 {
                    // If there's a selection (likely autocomplete), just delete it
                    let newText = String(self.stringValue.prefix(selectedRange.location))
                    isSettingAutocomplete = true
                    self.stringValue = newText
                    self.userText = newText
                    isSettingAutocomplete = false
                    
                    textEditor.selectedRange = NSRange(location: newText.count, length: 0)
                    return
                }
            }
            super.keyDown(with: event)
            
        default:
            // For regular typing, clear any selection first
            if let textEditor = self.currentEditor() {
                let selectedRange = textEditor.selectedRange
                if selectedRange.length > 0 {
                    let newText = String(self.stringValue.prefix(selectedRange.location))
                    isSettingAutocomplete = true
                    self.stringValue = newText
                    self.userText = newText
                    isSettingAutocomplete = false
                    
                    textEditor.selectedRange = NSRange(location: newText.count, length: 0)
                }
            }
            super.keyDown(with: event)
        }
    }
}

// MARK: - Supporting Views

struct SuggestionRow: View {
    let suggestion: SearchSuggestion
    let isSelected: Bool
    let searchQuery: String // Add search query parameter
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Use type-specific icon
            if suggestion.type != .chatGPT{
                Image(systemName: suggestion.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
            }else{
                Image("chatgpt-2")
                    .resizable()
                    .frame(width: 17, height: 17)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Use attributed text for title
                SwiftUIAttributedText(
                    text: suggestion.title,
                    searchQuery: searchQuery,
                    isSelected: isSelected,
                    fontSize: 14,
                    fontWeight: .medium
                )
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let subtitle = suggestion.subtitle {
                    SwiftUIAttributedText(
                        text: subtitle,
                        searchQuery: searchQuery,
                        isSelected: isSelected,
                        fontSize: 12,
                        fontWeight: .regular
                    )
                    .lineLimit(1)
                }
            }
            Spacer()
            // Add ChatGPT indicator with arrow for .chatGPT type
            if suggestion.type == .chatGPT {
                HStack(spacing: 4) {
                 
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - AttributedText View

struct AttributedText: NSViewRepresentable {
    let text: String
    let searchQuery: String
    let isSelected: Bool
    let fontSize: CGFloat
    let fontWeight: NSFont.Weight
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear
        textField.cell?.lineBreakMode = .byTruncatingTail
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.attributedStringValue = createAttributedString()
    }
    
    private func createAttributedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Base attributes
        let baseColor = isSelected ? NSColor.white : NSColor.labelColor
        let subtitleColor = isSelected ? NSColor.white.withAlphaComponent(0.8) : NSColor.secondaryLabelColor
        let textColor = fontSize == 12 ? subtitleColor : baseColor
        
        let baseFont = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
        let boldFont = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        
        // Apply base attributes to entire string
        attributedString.addAttributes([
            .font: baseFont,
            .foregroundColor: textColor
        ], range: NSRange(location: 0, length: text.count))
        
        // Find and bold search query matches
        if !searchQuery.isEmpty {
            let searchTerms = searchQuery.lowercased().components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            for term in searchTerms {
                let ranges = text.lowercased().ranges(of: term)
                for range in ranges {
                    let nsRange = NSRange(range, in: text)
                    attributedString.addAttributes([
                        .font: boldFont,
                        .foregroundColor: textColor
                    ], range: nsRange)
                }
            }
        }
        
        return attributedString
    }
}

// MARK: - String Extension for Range Finding

extension String {
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        var start = startIndex
        
        while let range = range(of: substring, options: options, range: start..<endIndex, locale: locale) {
            ranges.append(range)
            start = range.upperBound
        }
        
        return ranges
    }
}

struct SwiftUIAttributedText: View {
    let text: String
    let searchQuery: String
    let isSelected: Bool
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    
    var body: some View {
        if searchQuery.isEmpty {
            // Simple case - no highlighting needed
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(textColor)
                .lineLimit(1)
                .truncationMode(.tail)
        } else {
            // Complex case - with search highlighting
            createHighlightedText()
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
    
    private var textColor: Color {
        let baseColor = isSelected ? Color.white : Color.primary
        let subtitleColor = isSelected ? Color.white.opacity(0.8) : Color.secondary
        return fontSize == 12 ? subtitleColor : baseColor
    }
    
    @ViewBuilder
    private func createHighlightedText() -> some View {
        let searchTerms = searchQuery.lowercased().components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        if let firstTerm = searchTerms.first,
           let range = text.lowercased().range(of: firstTerm) {
            
            let beforeMatch = String(text[..<range.lowerBound])
            let match = String(text[range])
            let afterMatch = String(text[range.upperBound...])
            
            (Text(beforeMatch)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(textColor) +
             Text(match)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(textColor) +
             Text(afterMatch)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(textColor))
        } else {
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(textColor)
        }
    }
}
