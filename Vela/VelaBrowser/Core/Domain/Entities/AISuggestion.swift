//
//  AISuggestion.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//
import SwiftUI


struct AISuggestion: Identifiable, Equatable {
    let id: UUID
    var type: String         // e.g. "script_idea", "summarize"
    var label: String        // User-visible label: "Generate Script"
    var prompt: String       // Full prompt for LLM
    var result: String?      // Optional returned result from LLM
    var clicked: Bool        // Whether user accepted this suggestion
    var createdAt: Date
}
