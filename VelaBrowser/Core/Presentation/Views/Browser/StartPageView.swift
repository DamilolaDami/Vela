import SwiftUI

/// Simple start page shown when no web page is loaded.
struct StartPageView: View {
    var openURL: (URL) -> Void
    @State private var urlString: String = ""

    var body: some View {
        VStack(spacing: 16) {
            TextField("Enter URL", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Button("Open") {
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            }
        }
        .padding()
    }
}

struct StartPageView_Previews: PreviewProvider {
    static var previews: some View {
        StartPageView { _ in }
    }
}
