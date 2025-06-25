//
//  QueryClassifier.swift
//  Vela
//
//  Created by damilola on 6/22/25.
//


//
//  SearchServices.swift
//  Vela
//
//  Enhanced Search Services
//

import Foundation
import SwiftUI
import Combine

// MARK: - Query Classifier

class QueryClassifier {
    static let shared = QueryClassifier()
    
    private let mathOperators = ["+", "-", "*", "/", "^", "(", ")", "="]
    private let unitPatterns = [
        "miles? to k?m",
        "k?m to miles?",
        "fahrenheit to celsius",
        "celsius to fahrenheit",
        "pounds? to k?g",
        "k?g to pounds?",
        "feet to meters?",
        "meters? to feet"
    ]
    
    func classifyQuery(_ query: String) -> QueryType {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        
        // Check for commands first
        if trimmed.contains(" ") {
            let firstWord = String(trimmed.prefix(while: { $0 != " " }))
            if SearchCommand.allCases.contains(where: { $0.rawValue == firstWord }) {
                return .command
            }
        }
        
        // Check for URLs
        if isValidURL(trimmed) {
            return .url
        }
        
        // Check for calculations
        if containsMathExpression(trimmed) {
            return .calculation
        }
        
        // Check for unit conversions
        if containsUnitConversion(trimmed) {
            return .unitConversion
        }
        
        // Check for weather queries
        if matchesWeatherPattern(trimmed) {
            return .weatherQuery
        }
        
        // Check for time queries
        if matchesTimePattern(trimmed) {
            return .timeQuery
        }
        
        return .search
    }
    
    private func isValidURL(_ query: String) -> Bool {
        let urlRegex = "^(https?://)?([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}(/.*)?$"
        let urlPredicate = NSPredicate(format: "SELF MATCHES %@", urlRegex)
        return urlPredicate.evaluate(with: query)
    }
    
    private func containsMathExpression(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        
        // Must have at least one digit
        guard trimmed.rangeOfCharacter(from: .decimalDigits) != nil else { return false }
        
        // Must have at least one math operator
        let hasOperators = mathOperators.contains { trimmed.contains($0) }
        guard hasOperators else { return false }
        
        // Should not end with an operator (incomplete expression)
        let lastChar = String(trimmed.suffix(1))
        if ["+", "-", "*", "/", "^"].contains(lastChar) {
            return false
        }
        
        // Should not start with invalid operators
        let firstChar = String(trimmed.prefix(1))
        if ["+", "*", "/", "^"].contains(firstChar) {
            return false
        }
        
        // Should not contain comparison operators that would crash NSExpression
        let invalidPatterns = ["==", "!=", "<=", ">=", "<", ">", "&&", "||"]
        for pattern in invalidPatterns {
            if trimmed.contains(pattern) {
                return false
            }
        }
        
        // Additional validation - should look like a reasonable math expression
        // Must contain at least one number followed by operator followed by another number
        let mathPattern = "\\d+\\s*[+\\-*/^]\\s*\\d+"
        let regex = try? NSRegularExpression(pattern: mathPattern)
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        
        return regex?.firstMatch(in: trimmed, options: [], range: range) != nil
    }
    
    private func containsUnitConversion(_ query: String) -> Bool {
        return unitPatterns.contains { pattern in
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: query.utf16.count)
            return regex?.firstMatch(in: query, options: [], range: range) != nil
        }
    }
    
    private func matchesWeatherPattern(_ query: String) -> Bool {
        let weatherKeywords = ["weather", "temperature", "forecast", "rain", "sunny", "cloudy"]
        return weatherKeywords.contains { query.contains($0) }
    }
    
    private func matchesTimePattern(_ query: String) -> Bool {
        let timeKeywords = ["time", "date", "today", "tomorrow", "yesterday", "now"]
        return timeKeywords.contains { query.contains($0) }
    }
}

// MARK: - Calculator Service



class CalculatorService {
    static let shared = CalculatorService()
    
    private let validCharacters = CharacterSet(charactersIn: "0123456789.+-*/^() ")
    private let invalidOperatorPatterns = ["==", "!=", "<=", ">=", "<", ">", "&&", "||"]
    
    func evaluate(_ expression: String) -> SearchSuggestion? {
        do {
            let result = try evaluateMathExpression(expression)
            return SearchSuggestion(
                title: "\(expression) = \(formatNumber(result))",
                subtitle: "Calculator",
                type: .calculation,
                icon: "plus.forwardslash.minus",
                relevanceScore: 1.0
            )
        } catch {
            return nil
        }
    }
    
    private func evaluateMathExpression(_ expression: String) throws -> Double {
        // Clean and validate the expression
        let cleanExpression = expression.replacingOccurrences(of: " ", with: "")
        
        // Early validation checks
        guard !cleanExpression.isEmpty else {
            throw CalculatorError.invalidExpression
        }
        
        // Check for invalid characters
        let expressionCharacterSet = CharacterSet(charactersIn: cleanExpression)
        if !expressionCharacterSet.isSubset(of: validCharacters) {
            throw CalculatorError.invalidExpression
        }
        
        // Check for invalid operator sequences
        for pattern in invalidOperatorPatterns {
            if cleanExpression.contains(pattern) {
                throw CalculatorError.invalidExpression
            }
        }
        
        // Check for incomplete expressions that would crash NSExpression
        if !isCompleteExpression(cleanExpression) {
            throw CalculatorError.invalidExpression
        }
        
        // Basic syntax validation
        if cleanExpression.hasPrefix("+") ||
           cleanExpression.hasPrefix("*") ||
           cleanExpression.hasPrefix("/") ||
           cleanExpression.hasPrefix("^") ||
           cleanExpression.hasSuffix("+") ||
           cleanExpression.hasSuffix("-") ||
           cleanExpression.hasSuffix("*") ||
           cleanExpression.hasSuffix("/") ||
           cleanExpression.hasSuffix("^") {
            throw CalculatorError.invalidExpression
        }
        
        // Check for balanced parentheses
        if !isParenthesesBalanced(cleanExpression) {
            throw CalculatorError.invalidExpression
        }
        
        // Additional validation for common problematic patterns
        if hasConsecutiveOperators(cleanExpression) {
            throw CalculatorError.invalidExpression
        }
        
        // Safe NSExpression evaluation with exception handling
        return try safeEvaluateExpression(cleanExpression)
    }
    
    private func isCompleteExpression(_ expression: String) -> Bool {
        // Check if expression ends with an operator (incomplete)
        let operators = ["+", "-", "*", "/", "^"]
        for op in operators {
            if expression.hasSuffix(op) {
                return false
            }
        }
        
        // Check for empty parentheses or incomplete parentheses content
        if expression.contains("()") {
            return false
        }
        
        // Check for operators at the beginning (except minus for negative numbers)
        if expression.hasPrefix("+") || expression.hasPrefix("*") ||
           expression.hasPrefix("/") || expression.hasPrefix("^") {
            return false
        }
        
        // Check for double operators (except for negative numbers like "+-")
        let doubleOperatorPatterns = ["++", "**", "//", "^^", "+-+", "-+-"]
        for pattern in doubleOperatorPatterns {
            if expression.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    private func hasConsecutiveOperators(_ expression: String) -> Bool {
        let operators = ["++", "**", "//", "^^", "+-+", "-+-", "*+", "/+", "^+", "*-", "/-", "^-"]
        return operators.contains { expression.contains($0) }
    }
    
    private func safeEvaluateExpression(_ expression: String) throws -> Double {
        // Convert ^ to ** for NSExpression (power operator)
        let nsExpressionString = expression.replacingOccurrences(of: "^", with: "**")
        
        // Use exception handling for NSExpression
        var result: NSNumber?
        var thrownError: Error?
        
        // Wrap NSExpression in exception handling
        do {
            let mathExpression = NSExpression(format: nsExpressionString)
            
            // Additional safety check - ensure the expression can be evaluated
            guard let expressionValue = try? mathExpression.expressionValue(with: nil, context: nil) as? NSNumber else {
                throw CalculatorError.invalidExpression
            }
            
            result = expressionValue
        } catch {
            thrownError = error
        }
        
        // Handle any thrown exceptions
        if let error = thrownError {
            throw CalculatorError.invalidExpression
        }
        
        guard let result = result else {
            throw CalculatorError.invalidExpression
        }
        
        // Check for invalid results (e.g., division by zero)
        let doubleValue = result.doubleValue
        if doubleValue.isNaN || doubleValue.isInfinite {
            throw CalculatorError.invalidExpression
        }
        
        return doubleValue
    }
    
    private func isParenthesesBalanced(_ expression: String) -> Bool {
        var stack = 0
        for char in expression {
            if char == "(" {
                stack += 1
            } else if char == ")" {
                stack -= 1
                if stack < 0 {
                    return false
                }
            }
        }
        return stack == 0
    }
    
    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", number)
        } else {
            return String(format: "%.6g", number)
        }
    }
}

enum CalculatorError: Error {
    case invalidExpression
    case divisionByZero
    case unsupportedOperation
}

// MARK: - Unit Conversion Service

class UnitConversionService {
    static let shared = UnitConversionService()
    
    func convert(_ query: String) -> SearchSuggestion? {
        // Parse and convert units
        if let conversion = parseAndConvert(query) {
            return SearchSuggestion(
                title: conversion.result,
                subtitle: "Unit Conversion",
                type: .unitConversion,
                icon: "arrow.left.arrow.right",
                relevanceScore: 1.0
            )
        }
        return nil
    }
    
    private func parseAndConvert(_ query: String) -> (result: String, from: String, to: String)? {
        let components = query.lowercased().components(separatedBy: " to ")
        guard components.count == 2 else { return nil }
        
        let fromPart = components[0].trimmingCharacters(in: .whitespaces)
        let toPart = components[1].trimmingCharacters(in: .whitespaces)
        
        // Extract number and unit from first part
        let numberRegex = try? NSRegularExpression(pattern: "([0-9.]+)\\s*([a-zA-Z]+)", options: [])
        let range = NSRange(location: 0, length: fromPart.utf16.count)
        
        guard let match = numberRegex?.firstMatch(in: fromPart, options: [], range: range),
              let numberRange = Range(match.range(at: 1), in: fromPart),
              let unitRange = Range(match.range(at: 2), in: fromPart),
              let value = Double(String(fromPart[numberRange])) else {
            return nil
        }
        
        let fromUnit = String(fromPart[unitRange])
        let toUnit = toPart
        
        if let convertedValue = performConversion(value: value, from: fromUnit, to: toUnit) {
            let formattedValue = String(format: "%.2f", convertedValue)
            return (
                result: "\(value) \(fromUnit) = \(formattedValue) \(toUnit)",
                from: fromUnit,
                to: toUnit
            )
        }
        
        return nil
    }
    
    private func performConversion(value: Double, from: String, to: String) -> Double? {
        // Common unit conversions
        let conversions: [String: [String: Double]] = [
            "miles": ["km": 1.60934, "kilometers": 1.60934],
            "km": ["miles": 0.621371],
            "kilometers": ["miles": 0.621371],
            "fahrenheit": ["celsius": { (value - 32) * 5/9 }()],
            "celsius": ["fahrenheit": { value * 9/5 + 32 }()],
            "pounds": ["kg": 0.453592, "kilograms": 0.453592],
            "kg": ["pounds": 2.20462],
            "kilograms": ["pounds": 2.20462],
            "feet": ["meters": 0.3048, "m": 0.3048],
            "meters": ["feet": 3.28084],
            "m": ["feet": 3.28084]
        ]
        
        // Special case for temperature
        if from == "fahrenheit" && (to == "celsius" || to == "c") {
            return (value - 32) * 5/9
        }
        if from == "celsius" && (to == "fahrenheit" || to == "f") {
            return value * 9/5 + 32
        }
        
        guard let fromConversions = conversions[from],
              let multiplier = fromConversions[to] else {
            return nil
        }
        
        return value * multiplier
    }
}

// MARK: - Weather Service

class WeatherService {
    static let shared = WeatherService()
    
    func getWeatherSuggestion(for location: String) async -> SearchSuggestion? {
        // In a real implementation, you'd call a weather API
        // For demo purposes, we'll simulate weather data
        
        let mockWeatherData = [
            "new york": ("22°C", "Partly Cloudy", "cloud.sun"),
            "london": ("15°C", "Rainy", "cloud.rain"),
            "tokyo": ("28°C", "Sunny", "sun.max"),
            "paris": ("18°C", "Overcast", "cloud")
        ]
        
        let locationKey = location.lowercased()
        if let weather = mockWeatherData[locationKey] {
            return SearchSuggestion(
                title: "\(weather.0) \(weather.1)",
                subtitle: "Weather in \(location.capitalized)",
                type: .weatherQuery,
                icon: weather.2,
                relevanceScore: 0.9
            )
        }
        
        return SearchSuggestion(
            title: "Get weather for \(location)",
            subtitle: "Weather",
            url: "https://weather.com/search?query=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            type: .weatherQuery,
            icon: "cloud.sun",
            relevanceScore: 0.7
        )
    }
}

// MARK: - Smart Cache Service

class SmartCacheService {
    static let shared = SmartCacheService()
    
    private var cache = NSCache<NSString, CachedSuggestions>()
    private var popularityScores: [String: Double] = [:]
    private var recentQueries: [String] = []
    
    init() {
        cache.countLimit = 1000
        loadPopularityScores()
    }
    
    func store(_ suggestions: [SearchSuggestion], for query: String) {
        let popularity = calculatePopularity(for: query)
        let cached = CachedSuggestions(suggestions: suggestions, popularity: popularity)
        cache.setObject(cached, forKey: query as NSString)
        updateRecentQueries(query)
    }
    
    func retrieve(for query: String) -> [SearchSuggestion]? {
        guard let cached = cache.object(forKey: query as NSString),
              !cached.isExpired else {
            return nil
        }
        return cached.suggestions
    }
    
    func preloadPopularSuggestions() {
        Task {
            let popularQueries = getPopularQueries()
            for query in popularQueries {
                // Preload in background
                _ = await AddressBarViewModel.shared.fetchSuggestions(for: query)
            }
        }
    }
    
    private func calculatePopularity(for query: String) -> Double {
        let currentScore = popularityScores[query.lowercased()] ?? 0.0
        let newScore = currentScore + 0.1
        popularityScores[query.lowercased()] = min(newScore, 1.0)
        savePopularityScores()
        return newScore
    }
    
    private func updateRecentQueries(_ query: String) {
        recentQueries.removeAll { $0 == query }
        recentQueries.insert(query, at: 0)
        if recentQueries.count > 100 {
            recentQueries.removeLast()
        }
    }
    
    private func getPopularQueries() -> [String] {
        return popularityScores
            .sorted { $0.value > $1.value }
            .prefix(20)
            .map { $0.key }
    }
    
    private func loadPopularityScores() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "popularityScores"),
           let scores = try? JSONDecoder().decode([String: Double].self, from: data) {
            popularityScores = scores
        }
    }
    
    private func savePopularityScores() {
        if let data = try? JSONEncoder().encode(popularityScores) {
            UserDefaults.standard.set(data, forKey: "popularityScores")
        }
    }
}

// MARK: - Fuzzy Matching Service

class FuzzyMatchingService {
    static let shared = FuzzyMatchingService()
    
    func fuzzyMatchScore(text: String, query: String) -> Double {
        let textLower = text.lowercased()
        let queryLower = query.lowercased()
        
        // Exact match
        if textLower == queryLower {
            return 1.0
        }
        
        // Starts with
        if textLower.hasPrefix(queryLower) {
            return 0.9
        }
        
        // Contains
        if textLower.contains(queryLower) {
            return 0.7
        }
        
        // Levenshtein distance
        let distance = levenshteinDistance(textLower, queryLower)
        let maxLength = max(text.count, query.count)
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        
        return max(0.0, similarity)
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var matrix = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count {
            matrix[i][0] = i
        }
        
        for j in 0...b.count {
            matrix[0][j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = min(
                        matrix[i-1][j] + 1,
                        matrix[i][j-1] + 1,
                        matrix[i-1][j-1] + 1
                    )
                }
            }
        }
        
        return matrix[a.count][b.count]
    }
}
