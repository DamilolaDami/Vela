//
//  VelaCommands.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI

struct VelaCommands: Commands {
    let appDelegate: VelaAppDelegate
    @ObservedObject var bookMarkViewModel: BookmarkViewModel
    @ObservedObject var browserViewModel: BrowserViewModel
    
    var body: some Commands {
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
            
            Button("New Window") {
              //  appDelegate.newWindow(nil)
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("New Incognito Window") {
              //  appDelegate.newIncognitoWindow(nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Close Tab") {
                appDelegate.closeTab(nil)
            }
            .keyboardShortcut("w", modifiers: .command)
            
            Button("Close Other Tabs") {
                appDelegate.browserViewModel?.closeOtherTabs()
            }
            .keyboardShortcut("w", modifiers: [.command, .option])
            
            Button("Close Window") {
               // appDelegate.closeWindow(nil)
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
        }
        
        // Edit Menu
        CommandGroup(replacing: .undoRedo) {
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
            
            Button("Find in Page...") {
               // appDelegate.browserViewModel?.startFindInPage()
            }
            .keyboardShortcut("f", modifiers: .command)
            
            Button("Find Next") {
               // appDelegate.browserViewModel?.findNext()
            }
            .keyboardShortcut("g", modifiers: .command)
            
            Button("Find Previous") {
              //  appDelegate.browserViewModel?.findPrevious()
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
        }
        
        // View Menu
        CommandGroup(after: .appInfo) {
            Button("Settings...") {
                appDelegate.openSettingsWindow(nil)
            }
            .keyboardShortcut(",", modifiers: [.command])
            Button("Import from Another Browser...") {
                appDelegate.openSettingsWindow(nil)
            }
           

        }
        CommandGroup(replacing: .appSettings) {
            Button("Toggle Sidebar") {
                appDelegate.toggleSidebar(nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            
            Button("Toggle Full Screen") {
              //  appDelegate.toggleFullScreen(nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .control])
            
            Divider()
            
            Button("Select Next Tab") {
                appDelegate.browserViewModel?.selectNextTab()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])
            
            Button("Select Previous Tab") {
                appDelegate.browserViewModel?.selectPreviousTab()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
            
            Button("Zoom In") {
                appDelegate.browserViewModel?.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
               appDelegate.browserViewModel?.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Button("Reset Zoom") {
             appDelegate.browserViewModel?.resetZoom()
            }
            .keyboardShortcut("0", modifiers: .command)
        }
        
        // Navigation Menu
        CommandGroup(before: .appInfo) {
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
                
                Divider()
                
                Button("Home") {
                  //  appDelegate.goToHomePage(nil)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                
                Button("Open Location...") {
                //    appDelegate.openLocation(nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }
        CommandMenu("Pilot") {
            Button((appDelegate.browserViewModel?.showCommandPalette ?? false) ? "Hide Pilot" : "Show Pilot") {
                appDelegate.browserViewModel?.showCommandPalette.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
           
        }
        
        
        // History Menu
        CommandMenu("History") {
            Button("Show All History") {
                // TODO: Implement show all history
            }
            .keyboardShortcut("y", modifiers: .command)
            
            Button("Clear History...") {
                // TODO: Implement clear history
            }
            
            Divider()
            
            Button("Reopen Last Closed Tab") {
                // TODO: Implement reopen last closed tab
            }
            .keyboardShortcut("t", modifiers: [.command, .shift, .option])
            
            Button("Reopen Last Closed Window") {
                // TODO: Implement reopen last closed window
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Recently Visited") {
                // TODO: Implement show recently visited sites
            }
            
            Button("Clear Recent History...") {
                // TODO: Implement clear recent history
            }
        }
        
        // Bookmarks Menu
        CommandMenu("Bookmarks") {
            // Add Bookmark
            Button("Add Bookmark...") {
                appDelegate.addBookmark(nil)
            }
            .keyboardShortcut("d", modifiers: .command)
            
            // Show All Bookmarks
            Button("Show All Bookmarks") {
                appDelegate.showAllBookmarks(nil)
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
            
            Divider()
            
            // Bookmarks and Folders
            ForEach(bookMarkViewModel.folders.filter { $0.parentFolderId == nil }) { folder in
                Menu(folder.title) {
                    // Recursively build submenu for nested folders and bookmarks
                    BookmarkSubMenu(
                        folderId: folder.id,
                        bookmarks: bookMarkViewModel.bookmarks,
                        folders: bookMarkViewModel.folders,
                        action: { bookmark in
                        appDelegate.bookmarkViewModel?.currentSelectedBookMark = bookmark
                        appDelegate.openBookmark(bookmark)
                        }
                    )
                }
            }
            
            // Bookmarks not in any folder
            Section {
                ForEach(bookMarkViewModel.bookmarks.filter { $0.folderId == nil && !$0.isFolder }) { bookmark in
                    Button(bookmark.title) {
                        appDelegate.bookmarkViewModel?.currentSelectedBookMark = bookmark
                        appDelegate.openBookmark(bookmark)
                    }
                    .disabled(bookmark.url == nil)
                }
            }
            
            Divider()
            
            // Bookmark All Tabs
            Button("Bookmark All Tabs...") {
                appDelegate.bookmarkAllTabs(nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            
            // Import Bookmarks
            Button("Import Bookmarks...") {
                appDelegate.importBookmarks(nil)
            }
            
            // Export Bookmarks
            Button("Export Bookmarks...") {
                appDelegate.exportBookmarks(nil)
            }
            
            Divider()
            
            // Organize Bookmarks
            Button("Organize Bookmarks...") {
                appDelegate.organizeBookmarks(nil)
            }
            
            // Add Bookmark Folder
            Button("Add Bookmark Folder...") {
                appDelegate.addBookmarkFolder(nil)
            }
        }
        
        // Spaces Menu
        CommandMenu("Spaces") {
            // Picker for selecting a space
            Picker("Select Space", selection: Binding(
                get: { browserViewModel.currentSpace?.id ?? UUID() },
                set: { newValue in
                    if let selectedSpace = browserViewModel.spaces.first(where: { $0.id == newValue }) {
                        browserViewModel.selectSpace(selectedSpace)
                    }
                }
            )) {
                ForEach(browserViewModel.spaces) { space in
                    // Combine emoji and name for emoji case, keep HStack for others
                    Group {
                        if space.iconType == .emoji {
                            Text("\(space.iconValue) \(space.name)")
                        } else {
                            HStack {
                                space.displayIcon
                                Text(space.name)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .tag(space.id)
                }
            }
            .pickerStyle(.inline)

            Divider()

            Button("New Space") {
                browserViewModel.isShowingCreateSpaceSheet = true
            }
            .keyboardShortcut("n", modifiers: [.command, .control])
            
            Button("Switch to Next Space") {
                if let current = browserViewModel.currentSpace,
                   let currentIndex = browserViewModel.spaces.firstIndex(where: { $0.id == current.id }),
                   currentIndex + 1 < browserViewModel.spaces.count {
                    browserViewModel.selectSpace(browserViewModel.spaces[currentIndex + 1])
                }
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .control])
            
            Button("Switch to Previous Space") {
                if let current = browserViewModel.currentSpace,
                   let currentIndex = browserViewModel.spaces.firstIndex(where: { $0.id == current.id }),
                   currentIndex > 0 {
                    browserViewModel.selectSpace(browserViewModel.spaces[currentIndex - 1])
                }
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .control])
            
            Divider()
            
            Button("Move Tab to New Space") {
                // TODO: Implement move tab to new space
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            
            Button("Merge Spaces...") {
                // TODO: Implement merge spaces
            }
            
            Divider()
            
            Button("Rename Current Space...") {
                if let currentSpace = browserViewModel.currentSpace {
                    browserViewModel.spaceForInfoPopover = currentSpace
                    browserViewModel.isShowingSpaceInfoPopover = true
                }
            }
            
            Button("Delete Current Space") {
                if let currentSpace = browserViewModel.currentSpace, !currentSpace.isDefault {
                    browserViewModel.deleteSpace(currentSpace)
                }
            }
            .disabled(browserViewModel.currentSpace?.isDefault ?? true)
            
            Divider()
            
            Button("Show All Spaces") {
                // TODO: Implement show all spaces
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
        CommandGroup(replacing: .help) {
            // Onboarding & Docs
            Button("🧭 Getting Started Guide") {
                appDelegate.openHelpPage(url: URL(string: "https://vela.app/docs/getting-started")!)
            }
            Button("📘 Vela User Manual") {
                appDelegate.openHelpPage(url: URL(string: "https://vela.app/docs")!)
            }
            Button("⌨️ Keyboard Shortcuts") {
                appDelegate.openHelpPage(url: URL(string: "https://vela.app/docs/shortcuts")!)
            }
            
            Divider()
            
            // Learning & Updates
            Button("🎥 Watch Video Tutorials") {
                appDelegate.openHelpPage(url: URL(string: "https://youtube.com/playlist?list=VELATUTS")!)
            }
            Button("🆕 What's New in Vela") {
                appDelegate.openHelpPage(url: URL(string: "https://vela.app/releases")!)
            }

            Divider()
            
            // Feedback & Support
            Button("📩 Contact Support") {
                appDelegate.openHelpPage(url: URL(string: "mailto:support@vela.app?subject=Support%20Request")!)
            }
            Button("🐞 Report a Bug") {
                appDelegate.openHelpPage(url: URL(string: "https://vela.app/feedback/bug-report")!)
            }
            Button("💡 Suggest a Feature") {
                appDelegate.openHelpPage(url: URL(string: "https://vela.app/feedback/feature-request")!)
            }
            
          
        }
    }
}


struct BookmarkSubMenu: View {
    let folderId: UUID?
    let bookmarks: [Bookmark]
    let folders: [Bookmark]
    let action: (Bookmark) -> Void
    
    var body: some View {
        // Subfolders
        ForEach(folders.filter { $0.parentFolderId == folderId }) { folder in
            Menu(folder.title) {
                BookmarkSubMenu(
                    folderId: folder.id,
                    bookmarks: bookmarks,
                    folders: folders,
                    action: action
                )
            }
        }
        
        // Bookmarks in this folder
        ForEach(bookmarks.filter { $0.folderId == folderId && !$0.isFolder }) { bookmark in
            Button(bookmark.title) {
                action(bookmark)
            }
            .disabled(bookmark.url == nil)
        }
    }
}
