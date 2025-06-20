//
//  BottomActions.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

// MARK: - Bottom Actions
struct BottomActions: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var showNewMenu = false
    @State private var showDownloads = false
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)

            HStack(spacing: 16) {
                DownloadsButton(viewModel: viewModel, showDownloads: $showDownloads)
              
             
               // Spacer()
                // Enhanced Space Navigation
                SpaceNavigationView(viewModel: viewModel)
               
              //  Spacer()
                ActionButton(icon: "plus", tooltip: "New Tab or Space",  action: {
                    showNewMenu = true
                })
                .popover(isPresented: $showNewMenu, arrowEdge: .top) {
                    NewItemMenu(viewModel: viewModel, showMenu: $showNewMenu)
                }

               
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
      
    }
}

// MARK: - Extensions
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}


