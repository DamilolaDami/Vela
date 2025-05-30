struct QuickAccessGrid: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    let quickAccessItems = [
        QuickAccessItem(title: "YouTube", icon: "play.rectangle.fill", color: .red, url: "https://youtube.com"),
        QuickAccessItem(title: "Notion", icon: "doc.text.fill", color: Color(NSColor.labelColor), url: "https://notion.so"),
        QuickAccessItem(title: "Figma", icon: "paintbrush.fill", color: .orange, url: "https://figma.com"),
        QuickAccessItem(title: "Spotify", icon: "music.note", color: .green, url: "https://spotify.com"),
        QuickAccessItem(title: "Calendar", icon: "calendar", color: .blue, url: "https://calendar.google.com"),
        QuickAccessItem(title: "Gmail", icon: "envelope.fill", color: .red, url: "https://gmail.com"),
        QuickAccessItem(title: "Twitter", icon: "at", color: .blue, url: "https://twitter.com")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pinned")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                ForEach(quickAccessItems) { item in
                    QuickAccessButton(item: item) {
                        viewModel.openURL(item.url)
                    }
                }
            }
        }
    }
}

struct QuickAccessItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let url: String
}

struct QuickAccessButton: View {
    let item: QuickAccessItem
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isHovered ?
                            Color(NSColor.controlAccentColor).opacity(0.15) :
                            item.color.opacity(0.1)
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isHovered ?
                                    Color(NSColor.controlAccentColor).opacity(0.3) :
                                    item.color.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(item.color)
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                
                Text(item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}