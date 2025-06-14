import Foundation
import WebKit
import SwiftUI
import Combine

// MARK: - AppDependencies Protocol
protocol AppDependenciesProtocol {
    var diContainer: DIContainer { get }
    var viewModelFactory: ViewModelFactory { get }
    
    // Core Services
    var persistenceController: PersistenceController { get }
 //   var downloadManager: DownloadManagerProtocol { get }
    var windowManager: WindowManager { get }
    
    // Repository Dependencies
    func makeTabRepository() -> TabRepositoryProtocol
    func makeSpaceRepository() -> SpaceRepositoryProtocol
    func makeBookmarkRepository() -> BookmarkRepositoryProtocol
   // func makeDownloadRepository() -> DownloadRepositoryProtocol
    
//    // Use Case Dependencies
//    func makeCreateTabUseCase() -> CreateTabUseCaseProtocol
//    func makeCreateDownloadUseCase() -> CreateDownloadUseCaseProtocol
//    func makeUpdateDownloadProgressUseCase() -> UpdateDownloadProgressUseCaseProtocol
//    func makeCompleteDownloadUseCase() -> CompleteDownloadUseCaseProtocol
//    func makeDeleteDownloadUseCase() -> DeleteDownloadUseCaseProtocol
//    func makeGetAllDownloadsUseCase() -> GetAllDownloadsUseCaseProtocol
    
    // ViewModel Dependencies
    func makeBrowserViewModel() -> BrowserViewModel
    func makeBookmarkViewModel() -> BookmarkViewModel
  //  func makeDownloadViewModel() -> DownloadViewModel
    func makeVelaPilotViewModel() -> VelaPilotViewModel
    func makeSuggestionViewModel() -> SuggestionViewModel
}

// MARK: - AppDependencies Implementation
@MainActor
class AppDependencies: ObservableObject, @preconcurrency AppDependenciesProtocol {
    
    // MARK: - Singleton Instance
    static let shared = AppDependencies()
    
    // MARK: - Core Dependencies
    let diContainer: DIContainer
    let viewModelFactory: ViewModelFactory
    let persistenceController: PersistenceController
   // let downloadManager: DownloadManagerProtocol
    let windowManager: WindowManager
    
    // MARK: - Initialization
    private init() {
        // Initialize core services
        self.persistenceController = PersistenceController.shared
     //   self.downloadManager = DownloadManager()
        self.windowManager = WindowManager.shared
        
        // Initialize DI container and factory
        self.diContainer = DIContainer.shared
        self.viewModelFactory = ViewModelFactory(container: diContainer)
        
        // Setup any additional configuration
        setupAppDependencies()
    }
    
    // MARK: - Setup Methods
    private func setupAppDependencies() {
        // Configure download manager
        configureDownloadManager()
        
        // Setup window manager
        configureWindowManager()
        
        // Any other app-wide configuration
        setupLogging()
    }
    
    private func configureDownloadManager() {
        // Configure download manager with any needed settings
        // This could include setting up download directories, preferences, etc.
    }
    
    private func configureWindowManager() {
        // Configure window manager with any needed settings
        // This could include window placement preferences, etc.
    }
    
    private func setupLogging() {
        // Setup logging configuration
        print("AppDependencies initialized successfully")
    }
    
    // MARK: - Repository Factory Methods
    func makeTabRepository() -> TabRepositoryProtocol {
        return diContainer.makeTabRepository()
    }
    
    func makeSpaceRepository() -> SpaceRepositoryProtocol {
        return diContainer.makeSpaceRepository()
    }
    
    func makeBookmarkRepository() -> BookmarkRepositoryProtocol {
        return diContainer.makeBookmarkRepository()
    }
    
//    func makeDownloadRepository() -> DownloadRepositoryProtocol {
//        return diContainer.makeDownloadRepository()
//    }
//    
//    // MARK: - Use Case Factory Methods
//    func makeCreateTabUseCase() -> CreateTabUseCaseProtocol {
//        return diContainer.makeCreateTabUseCase()
//    }
//    
//    func makeCreateDownloadUseCase() -> CreateDownloadUseCaseProtocol {
//        return diContainer.makeCreateDownloadUseCase()
//    }
//    
//    func makeUpdateDownloadProgressUseCase() -> UpdateDownloadProgressUseCaseProtocol {
//        return diContainer.makeUpdateDownloadProgressUseCase()
//    }
//    
//    func makeCompleteDownloadUseCase() -> CompleteDownloadUseCaseProtocol {
//        return diContainer.makeCompleteDownloadUseCase()
//    }
//    
//    func makeDeleteDownloadUseCase() -> DeleteDownloadUseCaseProtocol {
//        return diContainer.makeDeleteDownloadUseCase()
//    }
//    
//    func makeGetAllDownloadsUseCase() -> GetAllDownloadsUseCaseProtocol {
//        return diContainer.makeGetAllDownloadsUseCase()
//    }
    
    // MARK: - ViewModel Factory Methods
    func makeBrowserViewModel() -> BrowserViewModel {
        return viewModelFactory.browserViewModel
    }
    
    func makeBookmarkViewModel() -> BookmarkViewModel {
        return viewModelFactory.bookmarkViewModel
    }
    
//    func makeDownloadViewModel() -> DownloadViewModel {
//        return viewModelFactory.downloadViewModel
//    }
//    
    func makeVelaPilotViewModel() -> VelaPilotViewModel {
        return viewModelFactory.velaPilotViewModel
    }
    
    func makeNoteBoardViewModel() -> NoteBoardViewModel {
        return viewModelFactory.makeNoteBoardViewMode()
    }
    func makeSuggestionViewModel() -> SuggestionViewModel {
        return viewModelFactory.makeSuggestionViewModel()
    }
    
    // MARK: - Shared ViewModels Access
    var browserViewModel: BrowserViewModel {
        return viewModelFactory.browserViewModel
    }
    
    var bookmarkViewModel: BookmarkViewModel {
        return viewModelFactory.bookmarkViewModel
    }
    
//    var downloadViewModel: DownloadViewModel {
//        return viewModelFactory.downloadViewModel
//    }
    
    var velaPilotViewModel: VelaPilotViewModel {
        return viewModelFactory.velaPilotViewModel
    }
    
    // MARK: - Lifecycle Methods
    func reset() {
        viewModelFactory.resetAllViewModels()
        print("AppDependencies reset")
    }
    
    func resetViewModels() {
        viewModelFactory.resetAllViewModels()
        print("ViewModels reset")
    }
    
    // MARK: - Environment Setup
    func setupEnvironment() -> AppEnvironment {
        return AppEnvironment(dependencies: self)
    }
}

// MARK: - App Environment for SwiftUI
struct AppEnvironment {
    let dependencies: AppDependenciesProtocol
    
    var browserViewModel: BrowserViewModel {
        return dependencies.makeBrowserViewModel()
    }
    
    var bookmarkViewModel: BookmarkViewModel {
        return dependencies.makeBookmarkViewModel()
    }
    
//    var downloadViewModel: DownloadViewModel {
//        return dependencies.makeDownloadViewModel()
//    }
//    
    var velaPilotViewModel: VelaPilotViewModel {
        return dependencies.makeVelaPilotViewModel()
    }
}

// MARK: - Environment Key for SwiftUI
struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependenciesProtocol = AppDependencies.shared
}

extension EnvironmentValues {
    var appDependencies: AppDependenciesProtocol {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}

// MARK: - Convenience Extensions
extension AppDependencies {
    
    // MARK: - WebView Integration
    func configureWebViewCoordinator(_ coordinator: WebViewCoordinator) {
        coordinator.browserViewModel = browserViewModel
    }
    
    // MARK: - Download Integration
    func handleDownloadCreation(filename: String, url: URL, wkDownload: WKDownload?) async {
//        do {
//            let downloadItem = try await makeCreateDownloadUseCase().execute(
//                filename: filename,
//                url: url,
//                wkDownload: wkDownload
//            )
//            
//            // Add to browser view model
//            await MainActor.run {
//                browserViewModel.addDownload(downloadItem)
//            }
//        } catch {
//            print("❌ Failed to create download: \(error)")
//        }
    }
    
    // MARK: - Window Management
    func createNewWindow(with url: URL? = nil) {
        browserViewModel.createNewWindow(with: url)
    }
    
    // MARK: - Debug Helpers
    func printDependencyTree() {
        print("🏗️ AppDependencies Tree:")
        print("  ├── DIContainer: \(diContainer)")
        print("  ├── ViewModelFactory: \(viewModelFactory)")
        print("  ├── PersistenceController: \(persistenceController)")
        print("  ├── WindowManager: \(windowManager)")
        print("  └── Environment: Ready")
    }
}

// MARK: - Testing Support
#if DEBUG
extension AppDependencies {
    static func makeMock() -> AppDependencies {
        //TODO: - Actually make mocks for testing
        return AppDependencies.shared
    }
}
#endif
