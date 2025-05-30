import Foundation
import Combine
import SwiftData

class SpaceRepository: SpaceRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
        createDefaultSpaceIfNeeded()
    }
    
    private func createDefaultSpaceIfNeeded() {
        do {
            let descriptor = FetchDescriptor<SpaceEntity>()
            let spaces = try context.fetch(descriptor)
            if spaces.isEmpty {
                let defaultSpace = SpaceEntity(from: Space(name: "Personal", color: .blue, isDefault: true))
                context.insert(defaultSpace)
                try context.save()
            }
        } catch {
            print("Failed to create default space: \(error)")
        }
    }
    
    func createSpace(_ space: Space) -> AnyPublisher<Space, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let spaceEntity = SpaceEntity(from: space)
                self.context.insert(spaceEntity)
                try self.context.save()
                if let createdSpace = spaceEntity.toSpace() {
                    promise(.success(createdSpace))
                } else {
                    promise(.failure(RepositoryError.invalidData))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAllSpaces() -> AnyPublisher<[Space], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<SpaceEntity>(
                    sortBy: [SortDescriptor(\.position)]
                )
                let entities = try self.context.fetch(descriptor)
                let spaces = entities.compactMap { $0.toSpace() }
                promise(.success(spaces))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateSpace(_ space: Space) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])))
            }
            // Capture space.id outside the predicate to avoid type issues
            let spaceId = space.id
            let descriptor = FetchDescriptor<SpaceEntity>(predicate: #Predicate { $0.id == spaceId })
            do {
                if let entity = try context.fetch(descriptor).first {
                    entity.updateFrom(space)
                    try context.save()
                    promise(.success(()))
                } else {
                    promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Space not found"])))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteSpace(_ space: Space) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])))
            }
            // Capture space.id outside the predicate to avoid type issues
            let spaceId = space.id
            let descriptor = FetchDescriptor<SpaceEntity>(predicate: #Predicate { $0.id == spaceId })
            do {
                if let entity = try context.fetch(descriptor).first {
                    context.delete(entity)
                    try context.save()
                    promise(.success(()))
                } else {
                    promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Space not found"])))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
