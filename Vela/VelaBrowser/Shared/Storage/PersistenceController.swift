import SwiftData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        do {
            let schema = Schema([TabEntity.self, HistoryEntity.self, SpaceEntity.self, BookmarkEntity.self, NoteBoardEntity.self, NoteBoardNoteEntity.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            container = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }
    
    var context: ModelContainer {
        container
    }
}
