//
//  FolderRepository.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

class FolderRepository: FolderRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func create(folder: Folder) -> AnyPublisher<Folder, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let folderEntity = FolderEntity(from: folder)
                
                // Set space relationship if spaceId is available
                if let spaceId = folder.spaceId {
                    let fetchDescriptor = FetchDescriptor<SpaceEntity>(
                        predicate: #Predicate { $0.id == spaceId }
                    )
                    guard let spaceEntity = try self.context.fetch(fetchDescriptor).first else {
                        promise(.failure(RepositoryError.spaceNotFound))
                        return
                    }
                    folderEntity.space = spaceEntity
                    var updatedFolders = spaceEntity.folders ?? []
                    updatedFolders.append(folderEntity)
                    spaceEntity.folders = updatedFolders
                }
                
                self.context.insert(folderEntity)
                try self.context.save()
                
                guard let createdFolder = folderEntity.toFolder() else {
                    promise(.failure(RepositoryError.invalidData))
                    return
                }
                
                promise(.success(createdFolder))
            } catch {
                promise(.failure(error))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func getAll() -> AnyPublisher<[Folder], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<FolderEntity>(
                    sortBy: [SortDescriptor(\.position)]
                )
                let entities = try self.context.fetch(descriptor)
                let folders = entities.compactMap { $0.toFolder() }
                promise(.success(folders))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getBySpace(spaceId: UUID) -> AnyPublisher<[Folder], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<FolderEntity>(
                    predicate: #Predicate { folderEntity in
                        folderEntity.spaceId == spaceId || folderEntity.space?.id == spaceId
                    },
                    sortBy: [SortDescriptor(\.position)]
                )
                let entities = try self.context.fetch(descriptor)
                let folders = entities.compactMap { $0.toFolder() }
                promise(.success(folders))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func update(folder: Folder) -> AnyPublisher<Folder, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let folderId = folder.id
                let descriptor = FetchDescriptor<FolderEntity>(
                    predicate: #Predicate { folderEntity in
                        folderEntity.id == folderId
                    }
                )
                guard let entity = try self.context.fetch(descriptor).first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }
                
                entity.updateFrom(folder)
                try self.context.save()
                promise(.success(folder))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func delete(folderId: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(RepositoryError.unknown))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<FolderEntity>(
                    predicate: #Predicate { folderEntity in
                        folderEntity.id == folderId
                    }
                )
                guard let entity = try self.context.fetch(descriptor).first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }
                
                // Remove folder from space's folders
                if let space = entity.space {
                    space.folders = space.folders?.filter { $0.id != folderId }
                }
                
                // Delete associated tabs
                if let tabs = entity.tabs {
                    for tab in tabs {
                        self.context.delete(tab)
                    }
                }
                
                self.context.delete(entity)
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
