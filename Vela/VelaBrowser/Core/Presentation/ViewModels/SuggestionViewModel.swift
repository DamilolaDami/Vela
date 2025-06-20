//
//  SuggestionViewModel.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI
import Combine

struct GoogleSuggestionResponse: Codable {
    let suggestions: [String]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(String.self) // Skip query
        suggestions = try container.decode([String].self)
    }
}

class AddressBarViewModel: ObservableObject {
    @Published var isShowingEnterAddressPopup = false
    @Published var suggestions: [SearchSuggestion] = []
    @Published var isShowingSuggestions: Bool = false
    @Published var selectedIndex: Int? = nil // For keyboard navigation
    private var cancellables = Set<AnyCancellable>()
    private var searchSubject = PassthroughSubject<String, Never>()
    private var suggestionCache = [String: [SearchSuggestion]]()
    private var currentTask: AnyCancellable?
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0 // 5 seconds timeout
        return URLSession(configuration: config)
    }()

    init() {
        searchSubject
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.fetchSuggestionsInternal(for: query)
            }
            .store(in: &cancellables)
    }

    func fetchSuggestions(for query: String) {
        searchSubject.send(query)
    }

    private func fetchSuggestionsInternal(for query: String) {
        // Immediately show local suggestions
        let localSuggestions = generateLocalSuggestions(for: query)
        objectWillChange.send()
        suggestions = localSuggestions.prefix(10).map { $0 }
        isShowingSuggestions = !suggestions.isEmpty

        // Fetch API suggestions
        fetchGoogleSuggestions(for: query) { apiSuggestions in
            self.objectWillChange.send()
            self.suggestions = (localSuggestions + apiSuggestions).prefix(10).map { $0 }
            self.isShowingSuggestions = !self.suggestions.isEmpty
        }
    }

    func selectSuggestion(_ suggestion: SearchSuggestion) -> String {
        objectWillChange.send()
        selectedIndex = nil
        return suggestion.url ?? suggestion.title
    }

    func clearSuggestions() {
        objectWillChange.send()
        suggestions = []
        isShowingSuggestions = false
        selectedIndex = nil
    }

    func selectNextSuggestion() {
        objectWillChange.send()
        if suggestions.isEmpty {
            selectedIndex = nil
        } else if let index = selectedIndex {
            selectedIndex = min(index + 1, suggestions.count - 1)
        } else {
            selectedIndex = 0
        }
    }

    func selectPreviousSuggestion() {
        objectWillChange.send()
        if let index = selectedIndex {
            selectedIndex = max(index - 1, 0)
        }
    }

    private func generateLocalSuggestions(for query: String) -> [SearchSuggestion] {
        guard !query.isEmpty else { return [] }
        
        var localSuggestions: [SearchSuggestion] = []
        
        // Check if query is question-like and add a question and ChatGPT suggestion
        if query.isQuestionLike {
            let questionSuggestion = SearchSuggestion(
                title: query,
                subtitle: "Ask this question",
                url: "https://www.google.com/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                type: .question
            )
            let chatGPTSuggestion = SearchSuggestion(
                title: query,
                subtitle: "Ask ChatGPT",
                url: "https://chat.openai.com/?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                type: .chatGPT
            )
            localSuggestions.append(contentsOf: [questionSuggestion, chatGPTSuggestion])
        }
        
        // Example: Filter a predefined list of bookmarks or history
        let history = ["SwiftUI tutorial", "iOS development", "Combine framework"]
        let historyMatches = history
            .filter { $0.lowercased().contains(query.lowercased()) }
            .prefix(5)
            .map { SearchSuggestion(
                title: $0,
                subtitle: nil,
                url: "https://www.google.com/search?q=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                type: .history
            ) }
        
        localSuggestions.append(contentsOf: historyMatches)
        return localSuggestions
    }

    private func fetchGoogleSuggestions(for query: String, completion: @escaping ([SearchSuggestion]) -> Void) {
        // Check cache
        if let cachedSuggestions = suggestionCache[query.lowercased()] {
            completion(cachedSuggestions)
            return
        }

        guard !query.isEmpty else {
            completion([])
            return
        }

        // Helper function to validate domain/URL
        func isValidDomain(_ query: String) -> Bool {
            let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
            // Simple regex for domain-like strings (e.g., google.com, www.google.com)
            let domainRegex = "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$"
            let urlRegex = "^(https?://)?([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}(/.*)?$"
            
            let domainPredicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
            let urlPredicate = NSPredicate(format: "SELF MATCHES %@", urlRegex)
            
            return domainPredicate.evaluate(with: trimmedQuery) || urlPredicate.evaluate(with: trimmedQuery)
        }

        // Check if query is a domain/URL
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        if isValidDomain(trimmedQuery) {
            // Ensure the URL has a scheme (default to https)
            let normalizedURL = trimmedQuery.hasPrefix("http://") || trimmedQuery.hasPrefix("https://") ? trimmedQuery : "https://\(trimmedQuery)"
            let suggestion = SearchSuggestion(title: trimmedQuery, subtitle: nil, url: normalizedURL, type: .url)
            suggestionCache[query.lowercased()] = [suggestion]
            completion([suggestion])
            return
        }

        // Cancel previous task
        currentTask?.cancel()

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "https://suggestqueries.google.com/complete/search?client=firefox&q=\(encodedQuery)"
        guard let url = URL(string: endpoint) else {
            print("Invalid URL: \(endpoint)")
            completion([])
            return
        }

        let publisher = session.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.global(qos: .userInitiated)) // Parse on background thread
            .map(\.data)
            .decode(type: GoogleSuggestionResponse.self, decoder: JSONDecoder())
            .map { response in
                response.suggestions.enumerated().map { (index, suggestion) in
                    let searchURL = "https://www.google.com/search?q=\(suggestion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    
                    // Determine suggestion type based on content
                    let suggestionType: SuggestionType = suggestion.isQuestionLike ? .question : .search
                    
                    return SearchSuggestion(title: suggestion, subtitle: nil, url: searchURL, type: suggestionType)
                }
            }
            .replaceError(with: [SearchSuggestion]()) // Explicitly specify type
            .receive(on: DispatchQueue.main)

        currentTask = publisher.sink { suggestions in
            self.suggestionCache[query.lowercased()] = suggestions
            self.cacheEvictionIfNeeded()
            completion(suggestions)
        }
        currentTask?.store(in: &cancellables)
    }

    private func cacheEvictionIfNeeded() {
        if suggestionCache.count > 100 {
            suggestionCache = Dictionary(uniqueKeysWithValues: suggestionCache.suffix(100))
        }
    }
    
    func cancelSuggestions() {
        DispatchQueue.main.async {
            self.isShowingSuggestions = false
        }
        currentTask?.cancel()
        currentTask = nil
    }
    
    func toggleShowingEnterAddressPopup(_ value: Bool) {
        isShowingEnterAddressPopup = value
    }
}

// MARK: - String Extension for Question Detection
extension String {
    /// Determines if the query appears to be a question
    var isQuestionLike: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespaces).lowercased()
        
        // Check for question words at the beginning
        let questionWords = ["what", "how", "why", "when", "where", "who", "which", "can", "is", "are", "do", "does", "did", "will", "would", "could", "should"]
        
        for word in questionWords {
            if trimmed.hasPrefix(word + " ") {
                return true
            }
        }
        
        // Check for question mark
        if trimmed.hasSuffix("?") {
            return true
        }
        
        // Check for longer phrases that indicate questions
        let questionPhrases = ["how to", "what is", "how do", "why does", "where can"]
        for phrase in questionPhrases {
            if trimmed.hasPrefix(phrase) {
                return true
            }
        }
        
        return false
    }
}
