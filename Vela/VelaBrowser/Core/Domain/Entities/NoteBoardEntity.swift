//
//  NoteBoardEntity.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//


import SwiftData
import Foundation

@Model
class NoteBoardEntity {
    @Attribute(.unique) var id: UUID?
    var title: String?
    var createdAt: Date?
    var updatedAt: Date?
    var position: Int32
    var colorLabel: String?

    // Relationships
    @Relationship var space: SpaceEntity?
    @Relationship var notes: [NoteBoardNoteEntity]?

    init(
        id: UUID? = UUID(),
        title: String?,
        createdAt: Date? = Date(),
        updatedAt: Date? = Date(),
        position: Int32 = 0,
        colorLabel: String? = nil,
        space: SpaceEntity?
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.position = position
        self.colorLabel = colorLabel
        self.space = space
        self.notes = []
    }
    
        func toNoteBoard() -> NoteBoard {
            NoteBoard(
                id: self.id ?? UUID(),
                title: self.title ?? "",
                createdAt: self.createdAt ?? Date(),
                updatedAt: self.updatedAt ?? Date(),
                position: Int(self.position),
                colorLabel: self.colorLabel,
                notes: self.notes?.compactMap { $0.toNoteBoardNote() } ?? []
            )
        }

}
