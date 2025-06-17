//
//  AISuggestionEntity.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//

import Foundation
import SwiftData

@Model
class AISuggestionEntity {
    var id: UUID?
    var type: String
    var label: String
    var prompt: String
    var result: String?
    var clicked: Bool
    var createdAt: Date?

    init(from suggestion: AISuggestion) {
        self.id = suggestion.id
        self.type = suggestion.type
        self.label = suggestion.label
        self.prompt = suggestion.prompt
        self.result = suggestion.result
        self.clicked = suggestion.clicked
        self.createdAt = suggestion.createdAt
    }

    func toAISuggestion() -> AISuggestion {
        AISuggestion(
            id: id ?? UUID(),
            type: type,
            label: label,
            prompt: prompt,
            result: result,
            clicked: clicked,
            createdAt: createdAt ?? Date()
        )
    }
}
