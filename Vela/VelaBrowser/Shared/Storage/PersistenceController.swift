import SwiftData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                TabEntity.self,
                HistoryEntity.self,
                SpaceEntity.self,
                BookmarkEntity.self,
                NoteBoardEntity.self,
                NoteBoardNoteEntity.self,
                FolderEntity.self
            ])

            var configuration: ModelConfiguration

            if inMemory {
                configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            } else {
                // Get the app's Documents directory
                let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let storeURL = documentsURL.appendingPathComponent("CustomVelaModelV2.store")
                configuration = ModelConfiguration(schema: schema, url: storeURL)
            }

            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var context: ModelContainer {
        container
    }
}
