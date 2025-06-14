//
//  NoteBoardViewModel.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class NoteBoardViewModel: ObservableObject {
    @Published var boards: [NoteBoard] = []
    @Published var currentBoardEntity: NoteBoardEntity?
    @Published var notes: [NoteBoardNote] = []
    @Published var selectedBoard: NoteBoard?
    private let boardRepository: NoteBoardRepositoryProtocol
    private let noteRepository: NoteBoardNoteRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentSpace: Space?

    init(boardRepository: NoteBoardRepositoryProtocol, noteRepository: NoteBoardNoteRepositoryProtocol) {
        self.boardRepository = boardRepository
        self.noteRepository = noteRepository
    }

    // MARK: - Load
    func loadBoards(for space: Space) {
        print("loading boards for space:==\(space.id)")
        currentSpace = space
        boardRepository.getBoards(for: space)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to load boards: \(error)")
                }
            }, receiveValue: { [weak self] boards in
                
                self?.boards = boards
                print("boards: count:\(self?.boards.count)")
                self?.currentBoardEntity = nil
                self?.notes = []
                if let firstBoard = boards.first {
                    self?.currentBoardEntity = self?.boardEntity(for: firstBoard)
                    self?.loadNotes(for: firstBoard)
                }
            })
            .store(in: &cancellables)
    }

    func loadNotes(for board: NoteBoard) {
        noteRepository.getNotes(for: board)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to load notes: \(error)")
                }
            }, receiveValue: { [weak self] notes in
                self?.notes = notes
            })
            .store(in: &cancellables)
    }

    private func boardEntity(for board: NoteBoard) -> NoteBoardEntity? {
        // Normally this would be passed in or memoized
        // Implement a safe way to convert/retrieve matching entity as needed
        return nil
    }

    // MARK: - Create
    func createBoard(_ board: NoteBoard, in space: Space) {
        boardRepository.createBoard(board, in: space)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to create board: \(error)")
                }
            }, receiveValue: { [weak self] newBoard in
                self?.boards.append(newBoard)
                self?.currentBoardEntity = self?.boardEntity(for: newBoard)
                self?.loadNotes(for: newBoard)
            })
            .store(in: &cancellables)
    }

    // MARK: - Enhanced Note Creation Methods
    
    /// Creates a note, automatically creating a default board if none exists
    func createNote(_ note: NoteBoardNote) {
        // Check if any boards exist
        if !boards.isEmpty {
            // Use the first available board (or selectedBoard if set)
            let targetBoard = selectedBoard ?? boards.first!
            createNoteInExistingBoard(note, boardEntity: targetBoard)
        } else {
            // No boards exist, create default board first then create note
            createNoteWithDefaultBoard(note)
        }
    }
    
    /// Creates a note and board simultaneously
    func createNoteWithBoard(_ note: NoteBoardNote, boardName: String, boardDescription: String? = nil) {
        guard let space = currentSpace else {
            print("No current space available for board creation")
            return
        }
        print("space:=\(space.name)")
        
        let newBoard = NoteBoard(
            id: UUID(),
            title: boardName,
            createdAt: Date(),
            updatedAt: Date(),
            position: 0,
            notes: [note]
        )
        
        // Create board first, then create note in that board
        boardRepository.createBoard(newBoard, in: space)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to create board with note: \(error)")
                }
            }, receiveValue: { [weak self] createdBoard in
                // Update local state
                self?.boards.append(createdBoard)
                self?.currentBoardEntity = self?.boardEntity(for: createdBoard)
                self?.createNoteInExistingBoard(note, boardEntity: createdBoard)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Private Helper Methods
    
    private func createNoteWithDefaultBoard(_ note: NoteBoardNote) {
        guard let space = currentSpace else {
            print("No current space available for default board creation")
            return
        }
        
        // Check if a default board already exists
        if let defaultBoard = findDefaultBoard() {
            print("Found existing default board, adding note to it")
            createNoteInExistingBoard(note, boardEntity: defaultBoard)
            return
        }
        
        print("creating default board:\(note)")
        let defaultBoard = NoteBoard(
            id: UUID(),
            title: "Default Noteboard",
            createdAt: Date(),
            updatedAt: Date(),
            position: 0,
            colorLabel: space.color.rawValue,
            notes: [note]
        )
        
        // Create default board first
        boardRepository.createBoard(defaultBoard, in: space)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to create default board: \(error)")
                }
            }, receiveValue: { [weak self] createdBoard in
                // Update local state
                self?.boards.append(createdBoard)
                self?.createNoteInExistingBoard(note, boardEntity: createdBoard)
            })
            .store(in: &cancellables)
    }
    
    /// Find existing default board in the current boards
    private func findDefaultBoard() -> NoteBoard? {
        return boards.first { $0.title == "Default Noteboard" }
    }
    
    private func createNoteInExistingBoard(_ note: NoteBoardNote, boardEntity: NoteBoard) {
        print("adding:===\(note)")
        noteRepository.createNote(note, in: boardEntity)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to create note: \(error)")
                }
            }, receiveValue: { [weak self] newNote in
                self?.notes.insert(newNote, at: 0)
            })
            .store(in: &cancellables)
    }

    // MARK: - Update / Delete
    func updateBoard(_ board: NoteBoard) {
        boardRepository.updateBoard(board)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to update board: \(error)")
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    func deleteBoard(_ board: NoteBoard) {
        boardRepository.deleteBoard(board)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to delete board: \(error)")
                } else {
                    self?.boards.removeAll { $0.id == board.id }
                    if let newBoard = self?.boards.first {
                        self?.currentBoardEntity = self?.boardEntity(for: newBoard)
                        self?.loadNotes(for: newBoard)
                    } else {
                        self?.currentBoardEntity = nil
                        self?.notes = []
                    }
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    func updateNote(_ note: NoteBoardNote) {
        noteRepository.updateNote(note)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to update note: \(error)")
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    func deleteNote(_ note: NoteBoardNote) {
        noteRepository.deleteNote(note)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to delete note: \(error)")
                } else {
                    self?.notes.removeAll { $0.id == note.id }
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }
    
    // MARK: - Utility Methods
    
    /// Check if any boards exist in the current space
    var hasBoardsAvailable: Bool {
        return !boards.isEmpty
    }
    
    /// Get the current active board
   
}
