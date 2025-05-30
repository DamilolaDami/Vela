
import Foundation
import Combine

protocol SpaceRepositoryProtocol {
    func createSpace(_ space: Space) -> AnyPublisher<Space, Error>
    func getAllSpaces() -> AnyPublisher<[Space], Error>
    func updateSpace(_ space: Space) -> AnyPublisher<Void, Error>
    func deleteSpace(_ space: Space) -> AnyPublisher<Void, Error>
}
