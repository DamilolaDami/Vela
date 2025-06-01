//
//  BookmarkViewModel.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI
import Combine

class BookmarkViewModel: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    @Published var folders: [Bookmark] = []
    @Published var currentFolder: Bookmark?
    @Published var searchQuery: String = ""
    @Published var searchResults: [Bookmark] = []
    @Published var selectedTags: [String] = []
    @Published var availableTags: [String] = []
    @Published var isLoading: Bool = false
    @Published var isShowingAddBookmarkSheet: Bool = false
    @Published var isShowingCreateFolderSheet: Bool = false
    @Published var bookmarkToEdit: Bookmark?
    @Published var isEditing: Bool = false
    @Published var currentSelectedBookMark: Bookmark? = nil
    
    private let bookmarkRepository: BookmarkRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(bookmarkRepository: BookmarkRepositoryProtocol) {
        self.bookmarkRepository = bookmarkRepository
        setupBindings()
        loadBookmarks()
    }
    
    private func setupBindings() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.searchResults = []
                } else {
                    self?.searchBookmarksWithQuery(query)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadBookmarks(for spaceId: UUID? = nil) {
        isLoading = true
        
        let publisher: AnyPublisher<[Bookmark], Error>
        if let spaceId = spaceId {
            publisher = bookmarkRepository.getBySpace(spaceId: spaceId)
        } else {
            publisher = bookmarkRepository.getAll()
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("Failed to load bookmarks: \(error)")
                    }
                },
                receiveValue: { [weak self] bookmarks in
                    self?.bookmarks = bookmarks.filter { !$0.isFolder }
                    self?.folders = bookmarks.filter { $0.isFolder }
                    self?.updateAvailableTags()
                }
            )
            .store(in: &cancellables)
    }
    
    func loadBookmarksInFolder(_ folderId: UUID?) {
        isLoading = true
        
        bookmarkRepository.getByFolder(folderId: folderId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("Failed to load bookmarks in folder: \(error)")
                    }
                },
                receiveValue: { [weak self] bookmarks in
                    self?.bookmarks = bookmarks.filter { !$0.isFolder }
                    self?.folders = bookmarks.filter { $0.isFolder }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Bookmark Management
    
    func addBookmark(title: String, url: URL?, tags: [String] = [], spaceId: UUID? = nil, folderId: UUID? = nil) {
        let bookmark = Bookmark(
            title: title,
            url: url,
            tags: tags,
            spaceId: spaceId,
            folderId: folderId,
            position: bookmarks.count
        )
        
        bookmarkRepository.create(bookmark: bookmark)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to create bookmark: \(error)")
                    }
                },
                receiveValue: { [weak self] newBookmark in
                    self?.bookmarks.append(newBookmark)
                    self?.updateAvailableTags()
                }
            )
            .store(in: &cancellables)
    }
    
    func createFolder(name: String, spaceId: UUID? = nil, parentFolderId: UUID? = nil) {
        let folder = Bookmark(
            title: name,
            spaceId: spaceId,
            folderId: parentFolderId,
            position: folders.count,
            isFolder: true
        )
        
        bookmarkRepository.create(bookmark: folder)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to create folder: \(error)")
                    }
                },
                receiveValue: { [weak self] newFolder in
                    self?.folders.append(newFolder)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateBookmark(_ bookmark: Bookmark) {
        var updatedBookmark = bookmark
        updatedBookmark.dateModified = Date()
        
        bookmarkRepository.update(bookmark: updatedBookmark)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to update bookmark: \(error)")
                    }
                },
                receiveValue: { [weak self] updated in
                    if let index = self?.bookmarks.firstIndex(where: { $0.id == updated.id }) {
                        self?.bookmarks[index] = updated
                    }
                    self?.updateAvailableTags()
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteBookmark(_ bookmark: Bookmark) {
        bookmarkRepository.delete(bookmarkId: bookmark.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to delete bookmark: \(error)")
                    }
                },
                receiveValue: { [weak self] in
                    if bookmark.isFolder {
                        self?.folders.removeAll { $0.id == bookmark.id }
                    } else {
                        self?.bookmarks.removeAll { $0.id == bookmark.id }
                    }
                    self?.updateAvailableTags()
                }
            )
            .store(in: &cancellables)
    }
    
    func moveBookmark(_ bookmark: Bookmark, to folderId: UUID?) {
        var updatedBookmark = bookmark
        updatedBookmark.folderId = folderId
        updatedBookmark.dateModified = Date()
        updateBookmark(updatedBookmark)
    }
    
    func reorderBookmarks(_ bookmarks: [Bookmark]) {
        let reorderedBookmarks = bookmarks.enumerated().map { index, bookmark in
            var updated = bookmark
            updated.position = index
            return updated
        }
        
        bookmarkRepository.reorderBookmarks(bookmarks: reorderedBookmarks)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to reorder bookmarks: \(error)")
                    }
                },
                receiveValue: { [weak self] in
                    self?.bookmarks = reorderedBookmarks.filter { !$0.isFolder }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Search and Filtering
    
    private func searchBookmarksWithQuery(_ query: String) {
        bookmarkRepository.search(query: query)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to search bookmarks: \(error)")
                    }
                },
                receiveValue: { [weak self] results in
                    self?.searchResults = results
                }
            )
            .store(in: &cancellables)
    }
    
    func filterByTags(_ tags: [String]) {
        selectedTags = tags
        if tags.isEmpty {
            loadBookmarks()
        } else {
            bookmarkRepository.getByTags(tags: tags)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to filter by tags: \(error)")
                        }
                    },
                    receiveValue: { [weak self] filtered in
                        self?.bookmarks = filtered.filter { !$0.isFolder }
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func updateAvailableTags() {
        let allTags = bookmarks.flatMap { $0.tags }
        availableTags = Array(Set(allTags)).sorted()
    }
    
    // MARK: - UI Actions
    
    func showAddBookmarkSheet() {
        bookmarkToEdit = nil
        isShowingAddBookmarkSheet = true
    }
    
    func showEditBookmark(_ bookmark: Bookmark) {
        bookmarkToEdit = bookmark
        isShowingAddBookmarkSheet = true
    }
    
    func showCreateFolderSheet() {
        isShowingCreateFolderSheet = true
    }
    
    func enterFolder(_ folder: Bookmark) {
        guard folder.isFolder else { return }
        currentFolder = folder
        loadBookmarksInFolder(folder.id)
    }
    
    func goBackToParentFolder() {
        if let current = currentFolder, let parentId = current.parentFolderId {
            if let parent = folders.first(where: { $0.id == parentId }) {
                enterFolder(parent)
            } else {
                currentFolder = nil
                loadBookmarks()
            }
        } else {
            currentFolder = nil
            loadBookmarks()
        }
    }
    
    func toggleEditing() {
        isEditing.toggle()
    }
}
