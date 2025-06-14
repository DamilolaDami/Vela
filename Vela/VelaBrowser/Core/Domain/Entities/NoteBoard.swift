//
//  NoteBoard.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//
import SwiftUI

struct NoteBoard: Identifiable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var position: Int
    var colorLabel: String?
    var notes: [NoteBoardNote] = []
    
    init(id: UUID, title: String, createdAt: Date, updatedAt: Date, position: Int, colorLabel: String? = nil, notes: [NoteBoardNote]) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.position = position
        self.colorLabel = colorLabel
        self.notes = notes
    }
}
