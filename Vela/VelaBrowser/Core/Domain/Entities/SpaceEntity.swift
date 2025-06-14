import SwiftData
import Foundation

@Model
class SpaceEntity {
    @Attribute(.unique) var id: UUID?
    var name: String?
    var colorRaw: String?
    var createdAt: Date?
    var position: Int32
    var isDefault: Bool
    
    // Relationships
    @Relationship(inverse: \TabEntity.space) var tabs: [TabEntity]?
    @Relationship var boards: [NoteBoardEntity]? 
    init(from space: Space) {
        self.id = space.id
        self.name = space.name
        self.colorRaw = space.color.rawValue
        self.createdAt = space.createdAt
        self.position = Int32(space.position ?? 0)
        self.isDefault = space.isDefault
        self.tabs = nil
    }
    
    func toSpace() -> Space? {
        guard let id, let name, let colorRaw, let color = Space.SpaceColor(rawValue: colorRaw) else {
            return nil
        }
        
        let tabsArray = tabs?.compactMap { $0.toTab() } ?? []
        
        return Space(
            id: id,
            name: name,
            color: color,
            tabs: tabsArray,
            createdAt: createdAt ?? Date(),
            position: Int(position),
            isDefault: isDefault
        )
    }
    
    func updateFrom(_ space: Space) {
        self.name = space.name
        self.colorRaw = space.color.rawValue
        self.position = Int32(space.position ?? 0)
        self.isDefault = space.isDefault
    }
}


