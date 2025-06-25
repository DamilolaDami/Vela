import SwiftData
import Foundation


@Model
class SpaceEntity {
    @Attribute(.unique) var id: UUID?
    var name: String?
    var colorRaw: String?
    var customHexColor: String?
    var createdAt: Date?
    var position: Int32
    var isDefault: Bool
    var iconType: IconType = IconType.emoji // Fully qualified
    var iconValue: String = "🌟"
    
    // Relationships
    @Relationship(inverse: \TabEntity.space) var tabs: [TabEntity]?
    @Relationship var boards: [NoteBoardEntity]?
    @Relationship var folders: [FolderEntity]?
    
    init(from space: Space) {
        self.id = space.id
        self.name = space.name
        self.colorRaw = space.color.rawValue
        self.customHexColor = space.customHexColor
        self.createdAt = space.createdAt
        self.position = Int32(space.position ?? 0)
        self.isDefault = space.isDefault
        self.iconType = space.iconType
        self.iconValue = space.iconValue
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
            customHexColor: customHexColor,
            tabs: tabsArray,
            createdAt: createdAt ?? Date(),
            position: Int(position),
            isDefault: isDefault,
            iconType: iconType,
            iconValue: iconValue
        )
    }
    
    func updateFrom(_ space: Space) {
        self.name = space.name
        self.colorRaw = space.color.rawValue
        self.customHexColor = space.customHexColor
        self.position = Int32(space.position ?? 0)
        self.isDefault = space.isDefault
        self.iconType = space.iconType
        self.iconValue = space.iconValue
    }
}
