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
    func makeSpaceRepository() -> FolderRepositoryProtocol{
        return FolderRepository(context: PersistenceController.shared.context.mainContext)
    }
    @MainActor
    func makeNoteBoardRepository() -> NoteBoardRepositoryProtocol {
        return NoteBoardRepository(context:PersistenceController.shared.context.mainContext)
    }
    @MainActor
    func makeNoteNoardNotesRepository() -> NoteBoardNoteRepositoryProtocol {
        return NoteBoardNoteRepository(context:PersistenceController.shared.context.mainContext)
    }
    
    @MainActor
    func makeCreateTabUseCase() -> CreateTabUseCaseProtocol {
        return CreateTabUseCase(tabRepository: makeTabRepository(), spaceRepository: makeSpaceRepository())
    }
    
    @MainActor
    func makeBookmarkRepository() -> BookmarkRepositoryProtocol {
        return BookmarkRepository(context:PersistenceController.shared.context.mainContext)
    }
    //NoteBoardViewModel
    @MainActor
    func makeNoteBoardViewModel() -> NoteBoardViewModel {
        return NoteBoardViewModel(
            boardRepository: makeNoteBoardRepository(), noteRepository: makeNoteNoardNotesRepository()
        )
    }
  
    
    @MainActor
    func makeBrowserViewModel(with noteBoardViewModel: NoteBoardViewModel, with suggestionViewModel: AddressBarViewModel, with schemeDetection: SchemaDetectionService) -> BrowserViewModel {
        return BrowserViewModel(
            createTabUseCase: makeCreateTabUseCase(),
            tabRepository: makeTabRepository(),
            spaceRepository: makeSpaceRepository(),
            folderRepository: makeSpaceRepository(),
            noteboardVM: noteBoardViewModel,
            addressBarVM: suggestionViewModel,
            detectedSechema: schemeDetection
            
        )
    }
    @MainActor
    func makeBookMarkViewModel() -> BookmarkViewModel {
        return BookmarkViewModel(
            bookmarkRepository: makeBookmarkRepository()
        )
    }
    @MainActor
    func makeVelaPilotViewModel(with browserViewModel: BrowserViewModel, with bookMarkViewModel: BookmarkViewModel) -> VelaPilotViewModel {
        return VelaPilotViewModel(broswerViewModel: browserViewModel, bookmarkViewModel: bookMarkViewModel)
    }
    
    @MainActor
    func makeAddressBarViewModel() -> AddressBarViewModel {
        return AddressBarViewModel.shared
    }
    
    @MainActor
    func makeSchemaDetector() -> SchemaDetectionService {
        return SchemaDetectionService()
    }
    
    
    private init() {}
}
