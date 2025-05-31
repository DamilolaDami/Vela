import SwiftUI

struct AddressBar: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onCommit: () -> Void
    let currentURL: URL?
    
    @ObservedObject var suggestionVM: SuggestionViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main address bar
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
                        .onChange(of: text) { _, newValue in
                            print("AddressBar: Text changed to '\(newValue)'")
                            suggestionVM.fetchSuggestions(for: newValue) // Fixed method name
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
            .onChange(of: isFocused) { _, focused in
                print("AddressBar: Focus changed to \(focused)")
                if focused && !isEditing {
                    startEditing()
                } else if !focused {
                    endEditing()
                }
            }
            .onTapGesture {
                if !isEditing {
                    startEditing()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: suggestionVM.isShowingSuggestions)
    }
    
    private func startEditing() {
        print("AddressBar: Starting editing")
        isEditing = true
        isFocused = true
        if let currentURL = currentURL {
            text = currentURL.absoluteString
        }
    }
    
    private func endEditing() {
        print("AddressBar: Ending editing")
        isEditing = false
        isFocused = false
        suggestionVM.clearSuggestions()
    }
    
    private func clearText() {
        text = ""
        suggestionVM.clearSuggestions()
    }
}

