
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
    
    var body: some Scene {
        WindowGroup {
            BrowserView(viewModel: container.makeBrowserViewModel())
                .withNotificationBanners()
                .frame(minWidth: 1200, minHeight: 700)
                
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(PersistenceController.shared.container)
    }
}
