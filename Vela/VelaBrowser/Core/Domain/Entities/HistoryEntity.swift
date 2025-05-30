import SwiftData
import Foundation

@Model
class HistoryEntity {
    @Attribute(.unique) var id: UUID?
    var urlString: String?
    var title: String?
    var visitedAt: Date?
    var favicon: Data?
    
    // Relationships
    @Relationship(inverse: \TabEntity.historyEntries) var tab: TabEntity?
    
    // Computed property for URL
    var url: URL? {
        guard let urlString else { return nil }
        return URL(string: urlString)
    }
    
    init(url: URL, title: String, visitedAt: Date = Date()) {
        self.id = UUID()
        self.urlString = url.absoluteString
        self.title = title
        self.visitedAt = visitedAt
        self.favicon = nil
        self.tab = nil
    }
}
