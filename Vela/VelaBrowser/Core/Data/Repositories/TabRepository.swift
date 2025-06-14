import Foundation
import Combine
import SwiftData

class TabRepository: TabRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func create(tab: Tab) -> AnyPublisher<Tab, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                // Create TabEntity
                let tabEntity = TabEntity(from: tab)
                
                // Handle spaceId: use provided spaceId or fall back to default space
                let spaceId = tab.spaceId ?? {
                    let fetchDescriptor = FetchDescriptor<SpaceEntity>(
                        predicate: #Predicate { $0.isDefault == true }
                    )
                    if let defaultSpace = try? self.context.fetch(fetchDescriptor).first {
                        return defaultSpace.id
                    }
                    return nil
                }()
                
                // Set the space relationship if spaceId is available
                if let spaceId {
                    let fetchDescriptor = FetchDescriptor<SpaceEntity>(
                        predicate: #Predicate { $0.id == spaceId }
                    )
                    let spaceEntities = try self.context.fetch(fetchDescriptor)
                    guard let spaceEntity = spaceEntities.first else {
                        promise(.failure(RepositoryError.notFound))
                        return
                    }
                    
                    tabEntity.space = spaceEntity
                    var updatedTabs = spaceEntity.tabs ?? []
                    updatedTabs.append(tabEntity)
                    spaceEntity.tabs = updatedTabs
                }
                
                // Insert and save
                self.context.insert(tabEntity)
                try self.context.save()
                
                guard let createdTab = tabEntity.toTab() else {
                    promise(.failure(RepositoryError.invalidData))
                    return
                }
                
                promise(.success(createdTab))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAll() -> AnyPublisher<[Tab], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<TabEntity>(
                    sortBy: [SortDescriptor(\.lastAccessedAt, order: .reverse)]
                )
                let entities = try self.context.fetch(descriptor)
                let tabs = entities.compactMap { $0.toTab() }
                promise(.success(tabs))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getBySpace(spaceId: UUID) -> AnyPublisher<[Tab], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let predicate = #Predicate<TabEntity> { $0.spaceId == spaceId || $0.space?.id == spaceId }
                let descriptor = FetchDescriptor<TabEntity>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.lastAccessedAt, order: .reverse)]
                )
                let entities = try self.context.fetch(descriptor)
                let tabs = entities.compactMap { $0.toTab() }
                promise(.success(tabs))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func update(tab: Tab) -> AnyPublisher<Tab, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let tabId = tab.id
                let predicate = #Predicate<TabEntity> { $0.id == tabId }
                let descriptor = FetchDescriptor<TabEntity>(predicate: predicate)
                let entities = try self.context.fetch(descriptor)
                
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }
                
                entity.updateFrom(tab)
                try self.context.save()
                promise(.success(tab))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func delete(tabId: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let predicate = #Predicate<TabEntity> { $0.id == tabId }
                let descriptor = FetchDescriptor<TabEntity>(predicate: predicate)
                let entities = try self.context.fetch(descriptor)
                
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }
                
                if let space = entity.space {
                    space.tabs = space.tabs?.filter { $0.id != tabId }
                }
                
                self.context.delete(entity)
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

enum RepositoryError: Error {
    case notFound
    case unknown
    case invalidData
    case spaceNotFound
}
