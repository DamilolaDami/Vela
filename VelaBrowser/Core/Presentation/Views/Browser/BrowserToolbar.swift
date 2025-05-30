import SwiftUI

/// Toolbar with basic browser navigation controls.
struct BrowserToolbar: View {
    var onBack: () -> Void
    var onForward: () -> Void
    var onReload: () -> Void
    var onHome: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onBack) {
                Image(systemName: "chevron.left").imageScale(.large)
            }
            Button(action: onForward) {
                Image(systemName: "chevron.right").imageScale(.large)
            }
            Button(action: onReload) {
                Image(systemName: "arrow.clockwise").imageScale(.large)
            }
            Button(action: onHome) {
                Image(systemName: "house").imageScale(.large)
            }
        }
        .padding(8)
        .background(Color(.windowBackgroundColor))
    }
}

struct BrowserToolbar_Previews: PreviewProvider {
    static var previews: some View {
        BrowserToolbar(onBack: {}, onForward: {}, onReload: {}, onHome: {})
            .previewLayout(.sizeThatFits)
    }
}
