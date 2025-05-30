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
                if viewModel.currentTab != nil {
                    WebViewContainer(viewModel: viewModel)
                } else {
                    // Pass viewModel to StartPageView
                    StartPageView(viewModel: viewModel)
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
}
