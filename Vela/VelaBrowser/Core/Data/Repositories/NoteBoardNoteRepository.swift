//
//  NoteBoardNoteRepository.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//

import Foundation
import Combine
import SwiftData

class NoteBoardNoteRepository: NoteBoardNoteRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createNote(_ note: NoteBoardNote, in board: NoteBoard) -> AnyPublisher<NoteBoardNote, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                // Fetch the NoteBoardEntity using board.id
                let boardId = board.id
                let boardDescriptor = FetchDescriptor<NoteBoardEntity>(
                    predicate: #Predicate { $0.id == boardId }
                )
                
                guard let boardEntity = try self.context.fetch(boardDescriptor).first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }

                // Create note entity using the initializer
                let noteEntity = NoteBoardNoteEntity(from: note, board: boardEntity)
                self.context.insert(noteEntity)

                // Save the context
                try self.context.save()
                
                // Convert back to domain model
                guard let createdNote = noteEntity.toNoteBoardNote() else {
                    promise(.failure(RepositoryError.invalidData))
                    return
                }
                
                promise(.success(createdNote))
            } catch {
                promise(.failure(error))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func getNotes(for board: NoteBoard) -> AnyPublisher<[NoteBoardNote], Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(RepositoryError.unknown))
            }

            let boardId = board.id
            let predicate = #Predicate<NoteBoardNoteEntity> { noteEntity in
                noteEntity.board?.id == boardId
            }

            let descriptor = FetchDescriptor<NoteBoardNoteEntity>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )

            do {
                let entities = try self.context.fetch(descriptor)
                let notes = entities.compactMap { $0.toNoteBoardNote() }
                promise(.success(notes))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func updateNote(_ note: NoteBoardNote) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(RepositoryError.unknown))
            }

            let noteId = note.id
            let descriptor = FetchDescriptor<NoteBoardNoteEntity>(
                predicate: #Predicate { $0.id == noteId }
            )

            do {
                if let entity = try self.context.fetch(descriptor).first {
                    entity.content = note.content
                    entity.updatedAt = Date()
                    entity.pinned = note.pinned
                    entity.archived = note.archived
                    entity.colorLabel = note.colorLabel
                    entity.tagsRaw = note.tags.joined(separator: ",")
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

    func deleteNote(_ note: NoteBoardNote) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                return promise(.failure(RepositoryError.unknown))
            }

            let noteId = note.id
            let descriptor = FetchDescriptor<NoteBoardNoteEntity>(
                predicate: #Predicate { $0.id == noteId }
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
