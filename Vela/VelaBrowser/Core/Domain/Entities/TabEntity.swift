//
//  TabEntity.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//


import SwiftData
import Foundation

@Model
class TabEntity {
    // Basic Properties
    @Attribute(.unique) var id: UUID?
    var title: String?
    var urlString: String?
    var favicon: Data?
    
    //broswer view state
    var zoomLevel: CGFloat = 1.0 
    // Navigation State
    var isLoading: Bool
    var canGoBack: Bool
    var canGoForward: Bool
    
    // Organization
    var spaceId: UUID?
    var isPinned: Bool
    var position: Int32
    
    // Timestamps
    var createdAt: Date?
    var lastAccessedAt: Date?
    
    // Optional: History and Session Data
    var sessionData: Data?
    var scrollPosition: Double
    var folderId: UUID?
    
    
    // Relationships
    @Relationship var space: SpaceEntity?
    @Relationship var historyEntries: [HistoryEntity]?
    @Relationship var folders: [FolderEntity]?
    
    // MARK: - Convenience Initializers
    init(from tab: Tab) {
        self.id = tab.id
        self.title = tab.title
        self.urlString = tab.url?.absoluteString
        self.favicon = tab.favicon
        self.isLoading = tab.isLoading
        self.canGoBack = tab.canGoBack
        self.canGoForward = tab.canGoForward
        self.spaceId = tab.spaceId
        self.createdAt = tab.createdAt
        self.lastAccessedAt = tab.lastAccessedAt
        self.isPinned = false
        self.position = 0
        self.sessionData = nil
        self.scrollPosition = 0.0
        self.space = nil
        self.historyEntries = nil
        self.folderId = tab.folderId
    }
    
    // MARK: - Domain Model Conversion
    func toTab() -> Tab? {
        guard let id = self.id else { return nil }
        
        return Tab(
            id: id,
            title: self.title ?? "",
            url: self.urlString.flatMap(URL.init),
            favicon: self.favicon,
            isLoading: self.isLoading,
            canGoBack: self.canGoBack,
            canGoForward: self.canGoForward,
            spaceId: self.spaceId,
            createdAt: self.createdAt ?? Date(),
            lastAccessedAt: self.lastAccessedAt ?? Date(),
            isPinned: self.isPinned,
            position: Int(self.position),
            folderId: self.folderId
        )
    }
    
    func updateFrom(_ tab: Tab) {
        self.title = tab.title
        self.urlString = tab.url?.absoluteString
        self.favicon = tab.favicon
        self.isLoading = tab.isLoading
        self.canGoBack = tab.canGoBack
        self.canGoForward = tab.canGoForward
        self.lastAccessedAt = Date()
        self.isPinned = tab.isPinned
        self.position = Int32(tab.position)
        self.folderId = tab.folderId
    }
}
