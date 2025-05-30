
import Foundation

class Space: Identifiable, Equatable {
    let id: UUID
    var name: String
    var color: SpaceColor
    var tabs: [Tab] = []
    let createdAt: Date
    var position: Int?
    var isDefault: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        color: SpaceColor,
        tabs: [Tab] = [],
        createdAt: Date = Date(),
        position: Int? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.tabs = tabs
        self.createdAt = createdAt
        self.position = position
        self.isDefault = isDefault
    }
    
    enum SpaceColor: String, CaseIterable {
        case blue, purple, pink, red, orange, yellow, green, gray
    }
    
    static func == (lhs: Space, rhs: Space) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.color == rhs.color &&
               lhs.tabs == rhs.tabs &&
               lhs.createdAt == rhs.createdAt &&
               lhs.position == rhs.position &&
               lhs.isDefault == rhs.isDefault
    }
}
