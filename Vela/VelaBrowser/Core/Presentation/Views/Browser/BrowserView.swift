
import SwiftUI

struct BrowserView: View {
    @StateObject private var viewModel: BrowserViewModel
    
    init(viewModel: BrowserViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        HSplitView {
            // Sidebar
            if !viewModel.sidebarCollapsed {
                SidebarView(viewModel: viewModel)
                    .frame(minWidth: 280, maxWidth: 320)
            }
            
            // Main Content
            VStack(spacing: 0) {
                // Toolbar
                BrowserToolbar(viewModel: viewModel)
                
                // Web Content
                if let currentTab = viewModel.currentTab {
                    WebViewContainer(tab: currentTab)
                } else {
                    StartPageView()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: viewModel.toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }
