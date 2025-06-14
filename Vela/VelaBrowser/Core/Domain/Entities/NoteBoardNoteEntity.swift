//
//  NoteBoardNoteEntity.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//


import SwiftData
import Foundation

@Model
class NoteBoardNoteEntity {
    @Attribute(.unique) var id: UUID?
    var content: String?
    var createdAt: Date?
    var updatedAt: Date?

    // Contextual metadata
    var sourceUrl: String?
    var tabTitle: String?
    var faviconUrl: String?
    var sessionId: String?
    var colorLabel: String?
    var pinned: Bool
    var archived: Bool
    var tagsRaw: String?

    // ✅ Correct relationship
    @Relationship(inverse: \NoteBoardEntity.notes) var board: NoteBoardEntity?

    // Suggestion cascade
    @Relationship(deleteRule: .cascade) var suggestions: [AISuggestionEntity]?

    init(from note: NoteBoardNote, board: NoteBoardEntity?) {
        self.id = note.id
        self.content = note.content
        self.createdAt = note.createdAt
        self.updatedAt = note.updatedAt
        self.sourceUrl = note.sourceUrl
        self.tabTitle = note.tabTitle
        self.faviconUrl = note.faviconUrl
        self.sessionId = note.sessionId
        self.colorLabel = note.colorLabel
        self.pinned = note.pinned
        self.archived = note.archived
        self.tagsRaw = note.tags.joined(separator: ",")
        self.board = board
        self.suggestions = note.suggestions?.map { AISuggestionEntity(from: $0) }
    }

    func toNoteBoardNote() -> NoteBoardNote? {
        guard let id, let content, let createdAt, let updatedAt else { return nil }
        return NoteBoardNote(
            id: id,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceUrl: sourceUrl,
            tabTitle: tabTitle,
            faviconUrl: faviconUrl,
            sessionId: sessionId,
            tags: tagsRaw?.components(separatedBy: ",") ?? [],
            aiSummary: nil,
            suggestions: suggestions?.compactMap { $0.toAISuggestion() },
            pinned: pinned,
            archived: archived,
            colorLabel: colorLabel
        )
    }
}
