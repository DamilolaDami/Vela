import SwiftUI

/// Row showing a single tab in the sidebar.
struct TabRow: View {
    var tab: Tab
    var onClose: (Tab) -> Void

    var body: some View {
        HStack {
            Text(tab.title)
                .lineLimit(1)
            Spacer()
            Button(action: { onClose(tab) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
}

struct TabRow_Previews: PreviewProvider {
    static var previews: some View {
        TabRow(tab: Tab(id: UUID(), title: "Example", url: URL(string: "https://example.com")!), onClose: { _ in })
            .previewLayout(.sizeThatFits)
    }
}
