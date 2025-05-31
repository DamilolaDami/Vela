import SwiftData
import Foundation
import Combine

class BookmarkRepository: BookmarkRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func create(bookmark: Bookmark) -> AnyPublisher<Bookmark, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let bookmarkEntity = BookmarkEntity(from: bookmark)
                self.context.insert(bookmarkEntity)
                try self.context.save()
                if let createdBookmark = bookmarkEntity.toBookmark() {
                    promise(.success(createdBookmark))
                } else {
                    promise(.failure(RepositoryError.invalidData))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAll() -> AnyPublisher<[Bookmark], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<BookmarkEntity>(
                    sortBy: [
                        SortDescriptor(\.position),
                        SortDescriptor(\.dateCreated)
                    ]
                )
                let entities = try self.context.fetch(descriptor)
                let bookmarks = entities.compactMap { $0.toBookmark() }
                promise(.success(bookmarks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getBySpace(spaceId: UUID) -> AnyPublisher<[Bookmark], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<BookmarkEntity>(
                    predicate: #Predicate { $0.spaceId == spaceId },
                    sortBy: [
                        SortDescriptor(\.position),
                        SortDescriptor(\.dateCreated)
                    ]
                )
                let entities = try self.context.fetch(descriptor)
                let bookmarks = entities.compactMap { $0.toBookmark() }
                promise(.success(bookmarks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getByFolder(folderId: UUID?) -> AnyPublisher<[Bookmark], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<BookmarkEntity>(
                    predicate: #Predicate { $0.folderId == folderId },
                    sortBy: [
                        SortDescriptor(\.position),
                        SortDescriptor(\.dateCreated)
                    ]
                )
                let entities = try self.context.fetch(descriptor)
                let bookmarks = entities.compactMap { $0.toBookmark() }
                promise(.success(bookmarks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getByTags(tags: [String]) -> AnyPublisher<[Bookmark], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<BookmarkEntity>(
                    sortBy: [
                        SortDescriptor(\.position),
                        SortDescriptor(\.dateCreated)
                    ]
                )
                let entities = try self.context.fetch(descriptor)
                let filteredEntities = entities.filter { entity in
                    tags.allSatisfy { tag in entity.tags.contains(tag) }
                }
                let bookmarks = filteredEntities.compactMap { $0.toBookmark() }
                promise(.success(bookmarks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func search(query: String) -> AnyPublisher<[Bookmark], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let lowercaseQuery = query.lowercased()
                let descriptor = FetchDescriptor<BookmarkEntity>(
                    sortBy: [
                        SortDescriptor(\.position),
                        SortDescriptor(\.dateCreated)
                    ]
                )
                let entities = try self.context.fetch(descriptor)
                let filteredEntities = entities.filter { entity in
                    entity.title.lowercased().contains(lowercaseQuery) ||
                    entity.urlString?.lowercased().contains(lowercaseQuery) == true ||
                    entity.tags.contains { $0.lowercased().contains(lowercaseQuery) }
                }
                let bookmarks = filteredEntities.compactMap { $0.toBookmark() }
                promise(.success(bookmarks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func update(bookmark: Bookmark) -> AnyPublisher<Bookmark, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            let bookmarkId = bookmark.id
            let descriptor = FetchDescriptor<BookmarkEntity>(
                predicate: #Predicate { $0.id == bookmarkId }
            )
            
            do {
                if let entity = try self.context.fetch(descriptor).first {
                    entity.updateFrom(bookmark)
                    try self.context.save()
                    if let updatedBookmark = entity.toBookmark() {
                        promise(.success(updatedBookmark))
                    } else {
                        promise(.failure(RepositoryError.invalidData))
                    }
                } else {
                    promise(.failure(RepositoryError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func delete(bookmarkId: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            let descriptor = FetchDescriptor<BookmarkEntity>(
                predicate: #Predicate { $0.id == bookmarkId }
            )
            
            do {
                if let entity = try self.context.fetch(descriptor).first {
                    self.context.delete(entity)
                    try self.context.save()
                    promise(.success(()))
                } else {
                    promise(.failure(RepositoryError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func reorderBookmarks(bookmarks: [Bookmark]) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                for (index, bookmark) in bookmarks.enumerated() {
                    let bookmarkId = bookmark.id
                    let descriptor = FetchDescriptor<BookmarkEntity>(
                        predicate: #Predicate { $0.id == bookmarkId }
                    )
                    
                    if let entity = try self.context.fetch(descriptor).first {
                        entity.position = index
                    }
                }
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

