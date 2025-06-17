//
//  NoteBoardNoteRepositoryProtocol.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//


import Foundation
import Combine

protocol NoteBoardNoteRepositoryProtocol {
    func createNote(_ note: NoteBoardNote, in board: NoteBoard) -> AnyPublisher<NoteBoardNote, Error>
    func getNotes(for board: NoteBoard) -> AnyPublisher<[NoteBoardNote], Error>
    func updateNote(_ note: NoteBoardNote) -> AnyPublisher<Void, Error>
    func deleteNote(_ note: NoteBoardNote) -> AnyPublisher<Void, Error>
}
