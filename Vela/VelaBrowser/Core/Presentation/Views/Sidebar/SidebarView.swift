
import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with space selector
            SidebarHeader(viewModel: viewModel)
            
            // Tab list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.tabs) { tab in
                        TabRow(
                            viewModel: viewModel,
                            tab: tab,
                            isSelected: tab.id == viewModel.currentTab?.id,
                            onSelect: { viewModel.selectTab(tab) },
                            onClose: { viewModel.closeTab(tab) }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // Add tab button
            Button(action: { viewModel.createNewTab() }) {
                HStack {
                    Image(systemName: "plus")
                    Text("New Tab")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(.regularMaterial)
    }
}
