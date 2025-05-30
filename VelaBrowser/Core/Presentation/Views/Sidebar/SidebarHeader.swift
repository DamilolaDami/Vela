import SwiftUI

/// Header displayed at the top of the sidebar.
struct SidebarHeader: View {
    var title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}

struct SidebarHeader_Previews: PreviewProvider {
    static var previews: some View {
        SidebarHeader(title: "Tabs")
            .previewLayout(.sizeThatFits)
    }
}
