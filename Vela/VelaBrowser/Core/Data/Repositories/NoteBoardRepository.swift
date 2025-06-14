import Foundation
import Combine
import SwiftData

class NoteBoardRepository: NoteBoardRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createBoard(_ board: NoteBoard, in space: Space) -> AnyPublisher<NoteBoard, Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(RepositoryError.unknown))
            }

            do {
                // Fetch the corresponding SpaceEntity using the Space's id
                let spaceId = space.id
                let descriptor = FetchDescriptor<SpaceEntity>(
                    predicate: #Predicate<SpaceEntity> { entity in
                        entity.id == spaceId
                    }
                )
                guard let spaceEntity = try self.context.fetch(descriptor).first else {
                    return promise(.failure(RepositoryError.spaceNotFound))
                }

                let boardEntity = NoteBoardEntity(
                    id: board.id,
                    title: board.title,
                    createdAt: board.createdAt,
                    updatedAt: board.updatedAt,
                    position: Int32(board.position),
                    colorLabel: board.colorLabel,
                    space: spaceEntity
                )

                self.context.insert(boardEntity)

                try self.context.save()
                promise(.success(boardEntity.toNoteBoard()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }



    func getBoards(for space: Space) -> AnyPublisher<[NoteBoard], Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(RepositoryError.unknown))
            }

            do {
                let spaceId = space.id
                let predicate = #Predicate<NoteBoardEntity> {
                    $0.space?.id == spaceId
                }

                let descriptor = FetchDescriptor<NoteBoardEntity>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.position)]
                )

                let entities = try self.context.fetch(descriptor)
                let boards = entities.compactMap { $0.toNoteBoard() }
                promise(.success(boards))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func updateBoard(_ board: NoteBoard) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(RepositoryError.unknown))
            }

            let boardId = board.id
            let descriptor = FetchDescriptor<NoteBoardEntity>(
                predicate: #Predicate { $0.id == boardId }
            )

            do {
                if let entity = try self.context.fetch(descriptor).first {
                    entity.title = board.title
                    entity.updatedAt = Date()
                    entity.position = Int32(board.position)
                    entity.colorLabel = board.colorLabel
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

    func deleteBoard(_ board: NoteBoard) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(RepositoryError.unknown))
            }

            let boardId = board.id
            let descriptor = FetchDescriptor<NoteBoardEntity>(
                predicate: #Predicate { $0.id == boardId }
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
}
