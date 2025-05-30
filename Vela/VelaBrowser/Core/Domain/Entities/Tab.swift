
import Foundation
import Combine

struct Tab: Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: URL?
    var favicon: Data?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var spaceId: UUID?
    let createdAt: Date
    var lastAccessedAt: Date
    var isPinned: Bool = false
    var position: Int = 0
    var scrollPosition: Double = 0
    
    init(
        id: UUID = UUID(),
        title: String = "New Tab",
        url: URL? = nil,
        favicon: Data? = nil,
        isLoading: Bool = false,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        spaceId: UUID? = nil,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        isPinned: Bool = false,
        position: Int = 0
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.favicon = favicon
        self.isLoading = isLoading
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.spaceId = spaceId
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.isPinned = isPinned
        self.position = position
    }
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        lhs.id == rhs.id
    }
}
