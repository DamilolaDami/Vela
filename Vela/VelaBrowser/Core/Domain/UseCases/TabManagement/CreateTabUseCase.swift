import Foundation
import Combine

protocol CreateTabUseCaseProtocol {
    func execute(url: URL?, in spaceId: UUID?) -> AnyPublisher<Tab, Error>
}

class CreateTabUseCase: CreateTabUseCaseProtocol {
    private let tabRepository: TabRepositoryProtocol
    private let spaceRepository: SpaceRepositoryProtocol 
    
    init(tabRepository: TabRepositoryProtocol, spaceRepository: SpaceRepositoryProtocol) {
        self.tabRepository = tabRepository
        self.spaceRepository = spaceRepository
    }
    
    func execute(url: URL?, in spaceId: UUID?) -> AnyPublisher<Tab, Error> {
        // If no spaceId is provided, fetch the default space's ID
        let spaceIdPublisher: AnyPublisher<UUID?, Error> = spaceId != nil ?
            Just(spaceId).setFailureType(to: Error.self).eraseToAnyPublisher() :
            spaceRepository.getAllSpaces()
                .map { spaces in
                    spaces.first(where: { $0.isDefault })?.id
                }
                .eraseToAnyPublisher()
        
        return spaceIdPublisher
            .flatMap { [weak self] resolvedSpaceId -> AnyPublisher<Tab, Error> in
                guard let self else {
                    return Fail(error: RepositoryError.unknown).eraseToAnyPublisher()
                }
                
                let newTab = Tab(
                    title: url?.host ?? "New Tab",
                    url: url,
                    spaceId: resolvedSpaceId,
                    createdAt: Date(),
                    lastAccessedAt: Date()
                )
                
                return self.tabRepository.create(tab: newTab)
            }
            .eraseToAnyPublisher()
    }
}
