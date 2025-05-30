import Foundation
import Combine

class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    // Factory methods that handle MainActor access
    @MainActor
    func makeTabRepository() -> TabRepositoryProtocol {
        return TabRepository(context: PersistenceController.shared.context.mainContext)
    }
    
    @MainActor
    func makeCreateTabUseCase() -> CreateTabUseCaseProtocol {
        return CreateTabUseCase(tabRepository: makeTabRepository())
    }
    
    @MainActor
    func makeBrowserViewModel() -> BrowserViewModel {
        return BrowserViewModel(
            createTabUseCase: makeCreateTabUseCase(),
            tabRepository: makeTabRepository()
        )
    }
    
    private init() {}
}
