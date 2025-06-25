//
//  Folder.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//


import Foundation
import Combine
import SwiftData
import SwiftUI

// MARK: - Domain Model
struct Folder: Identifiable, Equatable {
    let id: UUID
    var name: String
    var spaceId: UUID?
    var tabs: [Tab] = []
    var createdAt: Date
    var updatedAt: Date
    var position: Int
    
    init(id: UUID = UUID(), name: String, spaceId: UUID?, tabs: [Tab] = [], createdAt: Date = Date(), updatedAt: Date = Date(), position: Int = 0) {
        self.id = id
        self.name = name
        self.spaceId = spaceId
        self.tabs = tabs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.position = position
    }
}

// MARK: - SwiftData Entity
@Model
class FolderEntity {
    @Attribute(.unique) var id: UUID?
    var name: String
    var spaceId: UUID?
    var createdAt: Date
    var updatedAt: Date
    var position: Int32
    
    @Relationship var tabs: [TabEntity]?
    @Relationship var space: SpaceEntity?
    
    init(id: UUID = UUID(), name: String, spaceId: UUID?, createdAt: Date = Date(), updatedAt: Date = Date(), position: Int = 0) {
        self.id = id
        self.name = name
        self.spaceId = spaceId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.position = Int32(position)
        self.tabs = []
        self.space = nil
    }
    
    init(from folder: Folder) {
        self.id = folder.id
        self.name = folder.name
        self.spaceId = folder.spaceId
        self.createdAt = folder.createdAt
        self.updatedAt = folder.updatedAt
        self.position = Int32(folder.position)
        self.tabs = folder.tabs.compactMap { TabEntity(from: $0) }
    }
    
    func toFolder() -> Folder? {
        guard let id = self.id else { return nil }
        return Folder(
            id: id,
            name: name,
            spaceId: spaceId,
            tabs: tabs?.compactMap { $0.toTab() } ?? [],
            createdAt: createdAt,
            updatedAt: updatedAt,
            position: Int(position)
        )
    }
    
    func updateFrom(_ folder: Folder) {
        self.name = folder.name
        self.spaceId = folder.spaceId
        self.updatedAt = Date()
        self.position = Int32(folder.position)
        // Update tabs relationship if needed
        let newTabs = folder.tabs.compactMap({ TabEntity(from: $0) })
        self.tabs = newTabs
    }
}
