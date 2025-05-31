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

class SuggestionViewModel: ObservableObject {
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
        // Example: Filter a predefined list of bookmarks or history
        let history = ["SwiftUI tutorial", "iOS development", "Combine framework"]
        guard !query.isEmpty else { return [] }
        return history
            .filter { $0.lowercased().contains(query.lowercased()) }
            .prefix(5)
            .map { SearchSuggestion(
                title: $0,
                subtitle: nil,
                url: "https://www.google.com/search?q=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                type: .history
            ) }
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
                    return SearchSuggestion(title: suggestion, subtitle: nil, url: searchURL, type: .search)
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
}
