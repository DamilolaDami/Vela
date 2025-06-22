//
//  VelaApp.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI
import SwiftData

@main
struct VelaApp: App {
    @StateObject private var appDependencies = AppDependencies.shared
    @NSApplicationDelegateAdaptor(VelaAppDelegate.self) var appDelegate
    @State var onboardingVM = OnboardingViewModel()
    @StateObject private var quitManager = QuitManager()
    
    var body: some Scene {
        WindowGroup {
            createMainView()
                .withNotificationBanners()
                .frame(minWidth: 400, minHeight: 400)
                .environment(\.appDependencies, appDependencies)
                .onAppear(perform: configureAppDelegate)
                .environmentObject(quitManager)
            
                .onAppear {
                    // Connect the app delegate to our quit manager
                    appDelegate.quitHandler = {
                        quitManager.showQuitDialog()
                    }
                    // Connect the quit manager to the app delegate
                    quitManager.quitConfirmHandler = {
                        appDelegate.confirmQuit()
                    }
                }
        }
        .defaultSize(width: 500, height: 400)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
        .windowToolbarStyle(.unified(showsTitle: false))
        .windowLevel(.normal)
        .windowResizability(.automatic)
        .modelContainer(appDependencies.persistenceController.container)
        .commands {
            createCommands()
        }
    }
    
    // MARK: - Private Methods
    @ViewBuilder
    private func createMainView() -> some View {
        let viewModels = createViewModels()
        
        if onboardingVM.hasSeenOnboarding == .completed {
            BrowserView(
                viewModel: viewModels.browser,
                bookMarkViewModel: viewModels.bookmark,
                suggestionViewModel: viewModels.browser.addressBarVM,
                velaPilotViewModel: viewModels.velaPilot,
                noteBoardVM: viewModels.noteboard,
                shchemaDetector: viewModels.browser.detectedSechema
            )
        } else {
            OnboardingView(viewModel: onboardingVM, broswerViewModel: viewModels.browser)
        }
    }
    
    private func createViewModels() -> (
        browser: BrowserViewModel,
        bookmark: BookmarkViewModel,
        suggestion: AddressBarViewModel,
        velaPilot: VelaPilotViewModel,
        noteboard: NoteBoardViewModel,
        onboarding: OnboardingViewModel
    ) {
        return (
            browser: appDependencies.makeBrowserViewModel(),
            bookmark: appDependencies.makeBookmarkViewModel(),
            suggestion: appDependencies.makeaddressBarViewModel(),
            velaPilot: appDependencies.makeVelaPilotViewModel(),
            noteboard: appDependencies.makeNoteBoardViewModel(),
            onboarding: OnboardingViewModel()
        )
    }
    
    private func configureAppDelegate() {
        let viewModels = createViewModels()
        appDelegate.browserViewModel = viewModels.browser
        appDelegate.bookmarkViewModel = viewModels.bookmark
    }
    
    private func createCommands() -> some Commands {
        let viewModels = createViewModels()
        return VelaCommands(
            appDelegate: appDelegate,
            bookMarkViewModel: viewModels.bookmark,
            browserViewModel: viewModels.browser
        )
    }
}
