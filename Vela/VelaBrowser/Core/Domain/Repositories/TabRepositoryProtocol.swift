
import Foundation
import Combine

protocol TabRepositoryProtocol {
    func create(tab: Tab) -> AnyPublisher<Tab, Error>
    func getAll() -> AnyPublisher<[Tab], Error>
    func getBySpace(spaceId: UUID) -> AnyPublisher<[Tab], Error>
    func update(tab: Tab) -> AnyPublisher<Tab, Error>
    func delete(tabId: UUID) -> AnyPublisher<Void, Error>
}
