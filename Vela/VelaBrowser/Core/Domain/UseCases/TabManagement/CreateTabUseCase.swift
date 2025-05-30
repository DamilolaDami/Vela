
import Foundation
import Combine

protocol CreateTabUseCaseProtocol {
    func execute(url: URL?, in spaceId: UUID?) -> AnyPublisher<Tab, Error>
}

class CreateTabUseCase: CreateTabUseCaseProtocol {
    private let tabRepository: TabRepositoryProtocol
    
    init(tabRepository: TabRepositoryProtocol) {
        self.tabRepository = tabRepository
    }
    
    func execute(url: URL?, in spaceId: UUID?) -> AnyPublisher<Tab, Error> {
        let newTab = Tab(
            title: url?.host ?? "New Tab",
            url: url,
            spaceId: spaceId
        )
        
        return tabRepository.create(tab: newTab)
    }
}
