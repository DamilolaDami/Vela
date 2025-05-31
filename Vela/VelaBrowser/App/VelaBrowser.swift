
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
        WindowGroup {
            let container = container.makeBrowserViewModel()
            BrowserView(viewModel: container)
                .withNotificationBanners()
                .frame(minWidth: 1200, minHeight: 700)
                .onAppear {
                    // Inject the view model into the app delegate
                    appDelegate.browserViewModel = container
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(PersistenceController.shared.container)
        .commands {
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appDelegate.newTab(nil)
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button("New Tab in Background") {
                    appDelegate.newTabInBackground(nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Close Tab") {
                    appDelegate.closeTab(nil)
                }
                .keyboardShortcut("w", modifiers: .command)
                
                Button("Close Other Tabs") {
                    appDelegate.browserViewModel?.closeOtherTabs()
                }
                .keyboardShortcut("w", modifiers: [.command, .option])
            }
            
            // Edit Menu Additions
            CommandGroup(after: .undoRedo) {
                Button("Duplicate Tab") {
                    appDelegate.duplicateTab(nil)
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                
                Button("Duplicate Tab in Background") {
                    appDelegate.browserViewModel?.duplicateCurrentTab(inBackground: true)
                }
                .keyboardShortcut("k", modifiers: [.command, .shift, .option])
                
                Divider()
                
                Button("Focus Address Bar") {
                    appDelegate.focusAddressBar(nil)
                }
                .keyboardShortcut("l", modifiers: .command)
            }
            
            // View Menu
            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    appDelegate.toggleSidebar(nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Select Next Tab") {
                    appDelegate.browserViewModel?.selectNextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])
                
                Button("Select Previous Tab") {
                    appDelegate.browserViewModel?.selectPreviousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])
            }
            
            // Navigation Menu
            CommandGroup(after: .toolbar) {
                Menu("Navigation") {
                    Button("Back") {
                        appDelegate.goBack(nil)
                    }
                    .keyboardShortcut("[", modifiers: .command)
                    
                    Button("Forward") {
                        appDelegate.goForward(nil)
                    }
                    .keyboardShortcut("]", modifiers: .command)
                    
                    Divider()
                    
                    Button("Reload") {
                        appDelegate.reload(nil)
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    
                    Button("Reload Ignoring Cache") {
                        appDelegate.browserViewModel?.reloadIgnoringCache()
                    }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    
                    Button("Stop Loading") {
                        appDelegate.browserViewModel?.stopLoading()
                    }
                    .keyboardShortcut(".", modifiers: .command)
                }
            }
        }
    }
}
