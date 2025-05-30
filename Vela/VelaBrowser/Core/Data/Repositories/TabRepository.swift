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
            
            let tabEntity = TabEntity(from: tab)
            self.context.insert(tabEntity)
            
            do {
                try self.context.save()
                promise(.success(tab))
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
                let predicate = #Predicate<TabEntity> { $0.spaceId == spaceId }
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
                // Store the tab.id in a local variable to avoid capture issues
                let tabId = tab.id
                let predicate = #Predicate<TabEntity> { entity in
                    entity.id == tabId
                }
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
}
