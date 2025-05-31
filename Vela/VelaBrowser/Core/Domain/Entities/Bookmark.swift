
import Foundation
import Combine
import SwiftData
import SwiftUI

// MARK: - Bookmark Model
struct Bookmark: Identifiable, Hashable {
    let id: UUID
    var title: String
    var url: URL?
    var favicon: String? // Base64 encoded favicon or URL
    var tags: [String]
    var spaceId: UUID?
    var folderId: UUID? // For organizing bookmarks in folders
    var position: Int
    var dateCreated: Date
    var dateModified: Date
    var isFolder: Bool
    var parentFolderId: UUID? // For nested folders
    var notes: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        url: URL? = nil,
        favicon: String? = nil,
        tags: [String] = [],
        spaceId: UUID? = nil,
        folderId: UUID? = nil,
        position: Int = 0,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        isFolder: Bool = false,
        parentFolderId: UUID? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.favicon = favicon
        self.tags = tags
        self.spaceId = spaceId
        self.folderId = folderId
        self.position = position
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isFolder = isFolder
        self.parentFolderId = parentFolderId
        self.notes = notes
    }
}

// MARK: - SwiftData Entity
@Model
class BookmarkEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var urlString: String?
    var favicon: String?
    var tags: [String]
    var spaceId: UUID?
    var folderId: UUID?
    var position: Int
    var dateCreated: Date
    var dateModified: Date
    var isFolder: Bool
    var parentFolderId: UUID?
    var notes: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        urlString: String? = nil,
        favicon: String? = nil,
        tags: [String] = [],
        spaceId: UUID? = nil,
        folderId: UUID? = nil,
        position: Int = 0,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        isFolder: Bool = false,
        parentFolderId: UUID? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.favicon = favicon
        self.tags = tags
        self.spaceId = spaceId
        self.folderId = folderId
        self.position = position
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isFolder = isFolder
        self.parentFolderId = parentFolderId
        self.notes = notes
    }
    
    convenience init(from bookmark: Bookmark) {
        self.init(
            id: bookmark.id,
            title: bookmark.title,
            urlString: bookmark.url?.absoluteString,
            favicon: bookmark.favicon,
            tags: bookmark.tags,
            spaceId: bookmark.spaceId,
            folderId: bookmark.folderId,
            position: bookmark.position,
            dateCreated: bookmark.dateCreated,
            dateModified: bookmark.dateModified,
            isFolder: bookmark.isFolder,
            parentFolderId: bookmark.parentFolderId,
            notes: bookmark.notes
        )
    }
    
    func toBookmark() -> Bookmark? {
        let url = urlString != nil ? URL(string: urlString!) : nil
        return Bookmark(
            id: id,
            title: title,
            url: url,
            favicon: favicon,
            tags: tags,
            spaceId: spaceId,
            folderId: folderId,
            position: position,
            dateCreated: dateCreated,
            dateModified: dateModified,
            isFolder: isFolder,
            parentFolderId: parentFolderId,
            notes: notes
        )
    }
    
    func updateFrom(_ bookmark: Bookmark) {
        self.title = bookmark.title
        self.urlString = bookmark.url?.absoluteString
        self.favicon = bookmark.favicon
        self.tags = bookmark.tags
        self.spaceId = bookmark.spaceId
        self.folderId = bookmark.folderId
        self.position = bookmark.position
        self.dateModified = bookmark.dateModified
        self.isFolder = bookmark.isFolder
        self.parentFolderId = bookmark.parentFolderId
        self.notes = notes
    }
}
