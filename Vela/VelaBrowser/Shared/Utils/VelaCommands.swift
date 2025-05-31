//
//  VelaCommands.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI

struct VelaCommands: Commands {
    let appDelegate: VelaAppDelegate
    
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
              //  appDelegate.browserViewModel?.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
             //   appDelegate.browserViewModel?.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Button("Reset Zoom") {
               // appDelegate.browserViewModel?.resetZoom()
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
            Button("Add Bookmark...") {
                // TODO: Implement add bookmark
            }
            .keyboardShortcut("d", modifiers: .command)
            
            Button("Show All Bookmarks") {
                // TODO: Implement show all bookmarks
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Bookmark All Tabs...") {
                // TODO: Implement bookmark all tabs
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            
            Button("Import Bookmarks...") {
                // TODO: Implement import bookmarks
            }
            
            Button("Export Bookmarks...") {
                // TODO: Implement export bookmarks
            }
            
            Divider()
            
            Button("Organize Bookmarks...") {
                // TODO: Implement organize bookmarks
            }
            
            Button("Add Bookmark Folder...") {
                // TODO: Implement add bookmark folder
            }
        }
        
        // Spaces Menu
        CommandMenu("Spaces") {
            Button("New Space") {
                // TODO: Implement new space
            }
            .keyboardShortcut("n", modifiers: [.command, .control])
            
            Button("Switch to Next Space") {
                // TODO: Implement switch to next space
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .control])
            
            Button("Switch to Previous Space") {
                // TODO: Implement switch to previous space
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
                // TODO: Implement rename current space
            }
            
            Button("Delete Current Space") {
                // TODO: Implement delete current space
            }
            
            Divider()
            
            Button("Show All Spaces") {
                // TODO: Implement show all spaces
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
        
        // Downloads Menu
        CommandMenu("Downloads") {
            Button("Show Downloads") {
                // TODO: Implement show downloads
            }
            .keyboardShortcut("j", modifiers: .command)
            
            Button("Clear Completed Downloads") {
                // TODO: Implement clear completed downloads
            }
            
            Divider()
            
            Button("Pause All Downloads") {
                // TODO: Implement pause all downloads
            }
            
            Button("Resume All Downloads") {
                // TODO: Implement resume all downloads
            }
        }
        
        // Tools Menu
        CommandMenu("Tools") {
            Button("Open Developer Tools") {
               // appDelegate.browserViewModel?.openDeveloperTools()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            
            Button("Toggle Responsive Design Mode") {
              //  appDelegate.browserViewModel?.toggleResponsiveDesignMode()
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
            
            Divider()
            
            Button("View Source") {
            //    appDelegate.browserViewModel?.viewPageSource()
            }
            .keyboardShortcut("u", modifiers: .command)
            
            Button("Inspect Element") {
              //  appDelegate.browserViewModel?.inspectElement()
            }
            .keyboardShortcut("c", modifiers: [.command, .option])
            
            Divider()
            
            Button("Clear Cache") {
              //  appDelegate.browserViewModel?.clearCache()
            }
            
            Button("Clear Cookies") {
            //    appDelegate.browserViewModel?.clearCookies()
            }
        }
        
        // Window Menu
        CommandMenu("Window") {
            Button("Minimize") {
              //  appDelegate.minimizeWindow(nil)
            }
            .keyboardShortcut("m", modifiers: .command)
            
            Button("Zoom") {
            //    appDelegate.zoomWindow(nil)
            }
            
            Divider()
            
            Button("Show All Windows") {
                // TODO: Implement show all windows
            }
            
            Button("Cycle Through Windows") {
                // TODO: Implement cycle through windows
            }
            .keyboardShortcut("`", modifiers: .command)
            
            Divider()
            
            Button("Bring All to Front") {
                // TODO: Implement bring all to front
            }
        }
    }
}
