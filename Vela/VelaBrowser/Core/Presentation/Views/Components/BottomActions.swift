// MARK: - Bottom Actions
struct BottomActions: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)
            
            HStack(spacing: 16) {
                ActionButton(icon: "gear", action: {
                    // Settings action
                })
                
                ActionButton(icon: "plus", action: {
                    viewModel.createNewTab()
                })
                
                Spacer()
                
                ActionButton(icon: "sidebar.right", action: {
                    // Toggle sidebar
                })
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground).opacity(0.8))
    }
}

struct ActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(isHovered ? 0.1 : 0))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}