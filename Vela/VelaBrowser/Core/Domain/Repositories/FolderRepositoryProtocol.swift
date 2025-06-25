//
//  FolderRepositoryProtocol.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//

import Combine
import Foundation


protocol FolderRepositoryProtocol {
    func create(folder: Folder) -> AnyPublisher<Folder, Error>
    func getAll() -> AnyPublisher<[Folder], Error>
    func getBySpace(spaceId: UUID) -> AnyPublisher<[Folder], Error>
    func update(folder: Folder) -> AnyPublisher<Folder, Error>
    func delete(folderId: UUID) -> AnyPublisher<Void, Error>
}
