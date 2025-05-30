import SwiftUI

struct SidebarHeader: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var showSpaceCreation = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Space Selector
            HStack {
                // Current space indicator
                Circle()
                    .fill(currentSpaceColor)
                    .frame(width: 12, height: 12)
                
                // Space name
                Text(viewModel.currentSpace?.name ?? "Personal")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Space options menu
                Menu {
                    ForEach(viewModel.spaces) { space in
                        Button(action: {
                          //  viewModel.switchToSpace(space)
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color.spaceColor(space.color))
                                    .frame(width: 8, height: 8)
                                Text(space.name)
                                if space.id == viewModel.currentSpace?.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button("New Space...") {
                        showSpaceCreation = true
                    }
                    
                    Button("Manage Spaces...") {
                        // TODO: Open space management
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Quick actions
            HStack(spacing: 12) {
                // Search tabs
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Tab count
                Text("\(viewModel.tabs.count) tabs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
        .sheet(isPresented: $showSpaceCreation) {
            SpaceCreationSheet(viewModel: viewModel)
        }
    }
    
    private var currentSpaceColor: Color {
        guard let space = viewModel.currentSpace else { return .blue }
        return Color.spaceColor(space.color)
    }
}
