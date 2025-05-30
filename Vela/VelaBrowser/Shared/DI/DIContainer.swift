import Foundation
import Combine

class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    // Repositories
    lazy var tabRepository: TabRepositoryProtocol = TabRepository()
    
    // Use Cases
    lazy var createTabUseCase: CreateTabUseCaseProtocol = CreateTabUseCase(
        tabRepository: tabRepository
    )
    
    // ViewModels
    func makeBrowserViewModel() -> BrowserViewModel {
        BrowserViewModel(
            createTabUseCase: createTabUseCase,
            tabRepository: tabRepository
        )
    }
    
    private init() {}
}
