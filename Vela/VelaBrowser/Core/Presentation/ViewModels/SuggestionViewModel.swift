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
    static let shared = AddressBarViewModel()
    @Published var isShowingEnterAddressPopup = false
    @Published var suggestions: [SearchSuggestion] = []
    @Published var isShowingSuggestions: Bool = false
    @Published var selectedIndex: Int? = nil // For keyboard navigation
    private var cancellables = Set<AnyCancellable>()
    private var searchSubject = PassthroughSubject<String, Never>()
    private var currentTask: AnyCancellable?
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0 // 5 seconds timeout
        return URLSession(configuration: config)
    }()
    
    // Services
    private let queryClassifier = QueryClassifier.shared
    private let calculatorService = CalculatorService.shared
    private let unitConversionService = UnitConversionService.shared
    private let weatherService = WeatherService.shared
    private let cacheService = SmartCacheService.shared
    private let fuzzyMatchingService = FuzzyMatchingService.shared

    init() {
        searchSubject
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.fetchSuggestionsInternal(for: query)
            }
            .store(in: &cancellables)
        
        // Preload popular suggestions
        cacheService.preloadPopularSuggestions()
    }

    func fetchSuggestions(for query: String) {
        searchSubject.send(query)
    }

    private func fetchSuggestionsInternal(for query: String) {
        guard !query.isEmpty else {
            clearSuggestions()
            return
        }

        // Check cache first
        if let cachedSuggestions = cacheService.retrieve(for: query.lowercased()) {
            DispatchQueue.main.async {
                self.suggestions = cachedSuggestions.sorted { $0.relevanceScore > $1.relevanceScore }
                self.isShowingSuggestions = !self.suggestions.isEmpty
            }
            return
        }

        // Classify the query
        let queryType = queryClassifier.classifyQuery(query)
        var localSuggestions: [SearchSuggestion] = []

        // Handle all query types and always include additional suggestions
        Task {
            // Always generate local suggestions (history, bookmarks, etc.)
            localSuggestions.append(contentsOf: generateLocalSuggestions(for: query))

            // Handle specific query type
            switch queryType {
            case .calculation:
                if let calcSuggestion = calculatorService.evaluate(query) {
                    localSuggestions.append(calcSuggestion)
                }
                
            case .unitConversion:
                if let conversionSuggestion = unitConversionService.convert(query) {
                    localSuggestions.append(conversionSuggestion)
                }
                
            case .weatherQuery:
                if let location = extractLocation(from: query) {
                    if let weatherSuggestion = await weatherService.getWeatherSuggestion(for: location) {
                        localSuggestions.append(weatherSuggestion)
                    }
                }
                
            case .command:
                localSuggestions.append(contentsOf: generateCommandSuggestions(for: query))
                
            case .url:
                if let urlSuggestion = generateURLSuggestion(for: query) {
                    localSuggestions.append(urlSuggestion)
                }
                
            case .timeQuery:
                localSuggestions.append(generateTimeSuggestion(for: query))
                
            case .search, .quickAnswer, .bookmark, .history, .tab:
                break // Already handled in generateLocalSuggestions
            }

            // Always fetch Google suggestions
            await fetchGoogleSuggestions(for: query) { apiSuggestions in
                let combinedSuggestions = self.combineAndRankSuggestions(
                    local: localSuggestions,
                    api: apiSuggestions,
                    query: query,
                    primaryType: queryType
                )
                DispatchQueue.main.async {
                    self.suggestions = combinedSuggestions.prefix(10).map { $0 }
                    self.isShowingSuggestions = !self.suggestions.isEmpty
                    self.cacheService.store(self.suggestions, for: query)
                }
            }
        }
    }

    func selectSuggestion(_ suggestion: SearchSuggestion) -> String {
        DispatchQueue.main.async {
            self.selectedIndex = nil
            self.isShowingSuggestions = false
        }
        // Log analytics event
        let analyticsEvent = SearchAnalyticsEvent(
            query: suggestion.title,
            suggestion: suggestion,
            action: .suggestionClick,
            timestamp: .now,
            responseTime: nil,
            position: selectedIndex
        )
        // In a real app, send analyticsEvent to analytics service
        return suggestion.url ?? suggestion.title
    }

    func clearSuggestions() {
        DispatchQueue.main.async {
            self.suggestions = []
            self.isShowingSuggestions = false
            self.selectedIndex = nil
        }
    }

    func selectNextSuggestion() {
        DispatchQueue.main.async {
            if self.suggestions.isEmpty {
                self.selectedIndex = nil
            } else if let index = self.selectedIndex {
                self.selectedIndex = min(index + 1, self.suggestions.count - 1)
            } else {
                self.selectedIndex = 0
            }
        }
    }

    func selectPreviousSuggestion() {
        DispatchQueue.main.async {
            if let index = self.selectedIndex {
                self.selectedIndex = max(index - 1, 0)
            }
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

    private func generateLocalSuggestions(for query: String) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []

        // History and bookmarks
        let history = ["SwiftUI tutorial", "iOS development", "Combine framework"]
        let historyMatches = history
            .filter { fuzzyMatchingService.fuzzyMatchScore(text: $0, query: query) > 0.5 }
            .map { SearchSuggestion(
                title: $0,
                subtitle: "History",
                url: "https://www.google.com/search?q=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                type: .history,
                icon: QueryType.history.icon,
                relevanceScore: fuzzyMatchingService.fuzzyMatchScore(text: $0, query: query)
            ) }
        
        suggestions.append(contentsOf: historyMatches)

        // Question-like suggestions
        if query.isQuestionLike {
            let questionSuggestion = SearchSuggestion(
                title: query,
                subtitle: "Ask this question",
                url: "https://www.google.com/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                type: .quickAnswer,
                icon: QueryType.quickAnswer.icon,
                relevanceScore: 0.9
            )
            suggestions.append(questionSuggestion)
        }

        return suggestions
    }

    private func generateURLSuggestion(for query: String) -> SearchSuggestion? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        let normalizedURL = trimmedQuery.hasPrefix("http://") || trimmedQuery.hasPrefix("https://") ? trimmedQuery : "https://\(trimmedQuery)"
        return SearchSuggestion(
            title: trimmedQuery,
            subtitle: "Website",
            url: normalizedURL,
            type: .url,
            icon: QueryType.url.icon,
            relevanceScore: 1.0
        )
    }

    private func generateTimeSuggestion(for query: String) -> SearchSuggestion {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let currentTime = formatter.string(from: Date())
        return SearchSuggestion(
            title: currentTime,
            subtitle: "Current Time",
            type: .timeQuery,
            icon: QueryType.timeQuery.icon,
            relevanceScore: 0.95
        )
    }

    private func generateCommandSuggestions(for query: String) -> [SearchSuggestion] {
        let components = query.lowercased().components(separatedBy: " ")
        guard let commandStr = components.first,
              let command = SearchCommand(rawValue: commandStr) else {
            return []
        }
        
        return [SearchSuggestion(
            title: command.description,
            subtitle: command.placeholder,
            type: .command,
            icon: QueryType.command.icon,
            relevanceScore: 0.95
        )]
    }

    private func extractLocation(from query: String) -> String? {
        let components = query.lowercased().components(separatedBy: " ")
        let weatherKeywords = ["weather", "temperature", "forecast", "rain", "sunny", "cloudy"]
        let locationWords = components.filter { !weatherKeywords.contains($0) }
        return locationWords.joined(separator: " ").capitalized
    }

    private func fetchGoogleSuggestions(for query: String, completion: @escaping ([SearchSuggestion]) -> Void) async {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "https://suggestqueries.google.com/complete/search?client=firefox&q=\(encodedQuery)"
        
        guard let url = URL(string: endpoint) else {
            print("Invalid URL: \(endpoint)")
            completion([])
            return
        }

        let publisher = session.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map(\.data)
            .decode(type: GoogleSuggestionResponse.self, decoder: JSONDecoder())
            .map { response in
                response.suggestions.enumerated().map { (index, suggestion) in
                    let searchURL = "https://www.google.com/search?q=\(suggestion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    let suggestionType: QueryType = suggestion.isQuestionLike ? .quickAnswer : .search
                    return SearchSuggestion(
                        title: suggestion,
                        subtitle: suggestionType == .quickAnswer ? "Question" : "Search",
                        url: searchURL,
                        type: suggestionType,
                        icon: suggestionType.icon,
                        relevanceScore: 0.8 - Double(index) * 0.05
                    )
                }
            }
            .replaceError(with: [SearchSuggestion]())
            .receive(on: DispatchQueue.main)

        currentTask = publisher.sink { suggestions in
            completion(suggestions)
        }
        currentTask?.store(in: &cancellables)
    }

    private func combineAndRankSuggestions(local: [SearchSuggestion], api: [SearchSuggestion], query: String, primaryType: QueryType) -> [SearchSuggestion] {
        var combined = Array(Set(local + api)) // Remove duplicates
        
        // Boost relevance score for primary query type
        combined = combined.map { suggestion in
            var modified = suggestion
            if suggestion.type == primaryType {
                modified.relevanceScore = min(modified.relevanceScore + 0.2, 1.0) // Boost primary type
            }
            return modified
        }
        
        // Sort with primary type first, then by relevance score
        combined.sort { (s1, s2) in
            if s1.type == primaryType && s2.type != primaryType {
                return true
            } else if s2.type == primaryType && s1.type != primaryType {
                return false
            }
            let score1 = s1.relevanceScore * Double(s1.type.priority)
            let score2 = s2.relevanceScore * Double(s2.type.priority)
            return score1 > score2
        }
        
        return combined
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
