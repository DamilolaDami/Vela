
import Foundation
import Combine

struct Tab: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var url: URL?
    var favicon: Data?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var spaceId: UUID?
    let createdAt: Date = Date()
    var lastAccessedAt: Date = Date()
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        lhs.id == rhs.id
    }
}
