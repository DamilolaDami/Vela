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
    @StateObject private var container = DIContainer.shared
    @NSApplicationDelegateAdaptor(VelaAppDelegate.self) var appDelegate
    
    var body: some Scene {
        let bookMarkVM = container.makeBookMarkViewModel()
        let viewModel = container.makeBrowserViewModel()
        let suggestionVM = container.makeSuggestionViewModel()
        WindowGroup {
            
            BrowserView(viewModel: viewModel, bookMarkViewModel: bookMarkVM, suggestionViewModel: suggestionVM)
                .withNotificationBanners()
                .frame(minWidth: 1200, minHeight: 700)
                .onAppear {
                   
                    appDelegate.browserViewModel = viewModel
                    appDelegate.bookmarkViewModel = bookMarkVM
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(PersistenceController.shared.container)
        .commands {
            VelaCommands(appDelegate: appDelegate, bookMarkViewModel: bookMarkVM, browserViewModel: viewModel)
        }
    }
}
