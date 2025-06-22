import Foundation
import Combine

@MainActor
class ViewModelFactory: ObservableObject {
    private let container: DIContainer
    
    // Singleton instances for shared ViewModels
    private var _browserViewModel: BrowserViewModel?
    private var _bookmarkViewModel: BookmarkViewModel?
    private var _velaPilotViewModel: VelaPilotViewModel?
    private var _noteboardVM: NoteBoardViewModel?
    private var _suggestionViewModel: AddressBarViewModel?
    private var _schemaDetection: SchemaDetectionService?
   // private var _downloadViewModel: DownloadViewModel?
    
    init(container: DIContainer = .shared) {
        self.container = container
    }
    
    // MARK: - Shared ViewModels (Singletons)
    var browserViewModel: BrowserViewModel {
        if let existing = _browserViewModel {
            return existing
        }
        
        let viewModel = container.makeBrowserViewModel(with: noteBoardViewModel, with: suggestionViewModel, with: schemaDector)
        _browserViewModel = viewModel
        return viewModel
    }
    
    var bookmarkViewModel: BookmarkViewModel {
        if let existing = _bookmarkViewModel {
            return existing
        }
        
        let viewModel = container.makeBookMarkViewModel()
        _bookmarkViewModel = viewModel
        return viewModel
    }
    
    var noteBoardViewModel: NoteBoardViewModel {
        if let existing = _noteboardVM {
            return existing
        }
        
        let viewModel = container.makeNoteBoardViewModel()
        _noteboardVM = viewModel
        return viewModel
    }
    var suggestionViewModel: AddressBarViewModel{
        if let existing = _suggestionViewModel {
            return existing
        }
        
        let viewModel = container.makeAddressBarViewModel()
        _suggestionViewModel = viewModel
        return viewModel
    }
    var schemaDector: SchemaDetectionService{
        if let existing = _schemaDetection {
            return existing
        }
        
        let viewModel = container.makeSchemaDetector()
        _schemaDetection = viewModel
        return viewModel
    }
    
    var velaPilotViewModel: VelaPilotViewModel {
        if let existing = _velaPilotViewModel {
            return existing
        }
        
        let viewModel = container.makeVelaPilotViewModel(
            with: browserViewModel,
            with: bookmarkViewModel
        )
        _velaPilotViewModel = viewModel
        return viewModel
    }
    
//    var downloadViewModel: DownloadViewModel {
//        if let existing = _downloadViewModel {
//            return existing
//        }
//        
//        let viewModel = container.makeDownloadViewModel()
//        _downloadViewModel = viewModel
//        return viewModel
//    }
    
    // MARK: - New Instance ViewModels
    func makeaddressBarViewModel() -> AddressBarViewModel {
        return container.makeAddressBarViewModel()
    }
    func makeNoteBoardViewMode()-> NoteBoardViewModel{
        return container.makeNoteBoardViewModel()
    }
    // MARK: - Reset Methods (for testing or app restart)
    func resetBrowserViewModel() {
        _browserViewModel = nil
    }
    
    func resetBookmarkViewModel() {
        _bookmarkViewModel = nil
    }
    
    func resetVelaPilotViewModel() {
        _velaPilotViewModel = nil
    }
    
    func resetDownloadViewModel() {
        //_downloadViewModel = nil
    }
    
    func resetAllViewModels() {
        _browserViewModel = nil
        _bookmarkViewModel = nil
        _velaPilotViewModel = nil
       // _downloadViewModel = nil
    }
}
