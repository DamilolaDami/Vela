
import Foundation

struct Space: Identifiable, Equatable {
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
}
