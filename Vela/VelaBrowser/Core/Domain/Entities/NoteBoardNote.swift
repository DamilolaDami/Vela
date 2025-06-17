//
//  NoteBoardNote.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//

import Foundation


struct NoteBoardNote: Identifiable, Equatable {
    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var sourceUrl: String?
    var tabTitle: String?
    var faviconUrl: String?
    var sessionId: String?
    var tags: [String]
    var aiSummary: String?
    var suggestions: [AISuggestion]?
    var pinned: Bool
    var archived: Bool
    var colorLabel: String?
}
