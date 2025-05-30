import SwiftUI

struct AddressBar: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onCommit: () -> Void
    let currentURL: URL?
    
    @State private var showingSuggestions = false
    @State private var suggestions: [SearchSuggestion] = []
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Security indicator
            if let url = currentURL, !isEditing {
                HStack(spacing: 6) {
                    Image(systemName: url.scheme == "https" ? "lock.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(url.scheme == "https" ? .green : .orange)
                    
                    Text(url.host ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.leading, 12)
                .onTapGesture {
                    startEditing()
                }
            } else {
                // Address input field
                TextField("Search or enter address", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14, weight: .regular))
                    .focused($isFocused)
                    .padding(.horizontal, 12)
                    .onSubmit {
                        onCommit()
                        endEditing()
                    }
                    .onChange(of: text) { newValue in
                        if isEditing && !newValue.isEmpty {
                            updateSuggestions(for: newValue)
                        } else {
                            suggestions = []
                            showingSuggestions = false
                        }
                    }
            }
            
            Spacer(minLength: 0)
            
            // Action buttons
            HStack(spacing: 4) {
                if isEditing && !text.isEmpty {
                    Button(action: clearText) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    if isEditing {
                        onCommit()
                        endEditing()
                    } else {
                        startEditing()
                    }
                }) {
                    Image(systemName: isEditing ? "arrow.right.circle.fill" : "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.trailing, 8)
        }
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isEditing ? .regularMaterial : .ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isEditing ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.1),
                            lineWidth: isEditing ? 2 : 1
                        )
                )
        )
        .overlay(alignment: .topLeading) {
            if showingSuggestions && !suggestions.isEmpty {
                suggestionsList
                    .offset(y: 40)
            }
        }
        .onChange(of: isFocused) { focused in
            if !focused {
                endEditing()
            }
        }
        .onTapGesture {
            if !isEditing {
                startEditing()
            }
        }
    }
    
    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(suggestions.prefix(5), id: \.id) { suggestion in
                Button(action: {
                    selectSuggestion(suggestion)
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
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.clear)
               // .hoverEffect(.highlight)
                
                if suggestion != suggestions.last {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
    }
    
    private func startEditing() {
        isEditing = true
        isFocused = true
        if let currentURL = currentURL {
            text = currentURL.absoluteString
        }
    }
    
    private func endEditing() {
        isEditing = false
        isFocused = false
        showingSuggestions = false
        suggestions = []
    }
    
    private func clearText() {
        text = ""
        suggestions = []
        showingSuggestions = false
    }
    
    private func selectSuggestion(_ suggestion: SearchSuggestion) {
        text = suggestion.url
        onCommit()
        endEditing()
    }
    
    private func updateSuggestions(for query: String) {
        // Generate mock suggestions - replace with real search suggestions
        var newSuggestions: [SearchSuggestion] = []
        
        // URL suggestion if it looks like a URL
        if query.contains(".") && !query.contains(" ") {
            let url = query.hasPrefix("http") ? query : "https://\(query)"
            newSuggestions.append(
                SearchSuggestion(
                    title: query,
                    subtitle: "Go to \(query)",
                    url: url,
                    type: .url
                )
            )
        }
        
        // Search suggestions
        let searchSuggestions = [
            "\(query) tutorial",
            "\(query) documentation",
            "\(query) examples",
            "\(query) github"
        ].map { suggestion in
            SearchSuggestion(
                title: suggestion,
                subtitle: "Search Google",
                url: "https://www.google.com/search?q=\(suggestion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                type: .search
            )
        }
        
        newSuggestions.append(contentsOf: searchSuggestions.prefix(4))
        
        suggestions = newSuggestions
        showingSuggestions = !suggestions.isEmpty
    }
}


