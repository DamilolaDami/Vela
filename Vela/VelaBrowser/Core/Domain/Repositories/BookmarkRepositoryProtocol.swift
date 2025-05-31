import Combine
import Foundation

protocol BookmarkRepositoryProtocol {
    func create(bookmark: Bookmark) -> AnyPublisher<Bookmark, Error>
    func getAll() -> AnyPublisher<[Bookmark], Error>
    func getBySpace(spaceId: UUID) -> AnyPublisher<[Bookmark], Error>
    func getByFolder(folderId: UUID?) -> AnyPublisher<[Bookmark], Error>
    func getByTags(tags: [String]) -> AnyPublisher<[Bookmark], Error>
    func search(query: String) -> AnyPublisher<[Bookmark], Error>
    func update(bookmark: Bookmark) -> AnyPublisher<Bookmark, Error>
    func delete(bookmarkId: UUID) -> AnyPublisher<Void, Error>
    func reorderBookmarks(bookmarks: [Bookmark]) -> AnyPublisher<Void, Error>
}
