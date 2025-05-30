import Foundation
import Combine

class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    @MainActor
    func makeTabRepository() -> TabRepositoryProtocol {
        return TabRepository(context: PersistenceController.shared.context.mainContext)
    }
    @MainActor
    func makeSpaceRepository() -> SpaceRepositoryProtocol {
        return SpaceRepository(context:PersistenceController.shared.context.mainContext)
    }
    
    @MainActor
    func makeCreateTabUseCase() -> CreateTabUseCaseProtocol {
        return CreateTabUseCase(tabRepository: makeTabRepository(), spaceRepository: makeSpaceRepository())
    }
    
    @MainActor
    func makeBrowserViewModel() -> BrowserViewModel {
        return BrowserViewModel(
            createTabUseCase: makeCreateTabUseCase(),
            tabRepository: makeTabRepository(),
            spaceRepository: makeSpaceRepository()
        )
    }
    
    private init() {}
}
