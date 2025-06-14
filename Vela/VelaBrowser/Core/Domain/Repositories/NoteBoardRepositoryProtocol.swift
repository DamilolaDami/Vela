//
//  NoteBoardRepositoryProtocol.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//


import Foundation
import Combine

protocol NoteBoardRepositoryProtocol {
    func createBoard(_ board: NoteBoard, in space: Space) -> AnyPublisher<NoteBoard, Error>
    func getBoards(for space: Space) -> AnyPublisher<[NoteBoard], Error>
    func updateBoard(_ board: NoteBoard) -> AnyPublisher<Void, Error>
    func deleteBoard(_ board: NoteBoard) -> AnyPublisher<Void, Error>
}
