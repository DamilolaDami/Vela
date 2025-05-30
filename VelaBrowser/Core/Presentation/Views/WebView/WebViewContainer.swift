import SwiftUI

/// Container view that hosts the web content.
struct WebViewContainer: View {
    @ObservedObject var viewModel: WebViewModel

    var body: some View {
        ZStack {
            WebViewRepresentable(viewModel: viewModel)
            if viewModel.isShowingStartPage {
                StartPageView { url in
                    viewModel.load(url: url)
                }
            }
        }
    }
}

struct WebViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        WebViewContainer(viewModel: WebViewModel())
    }
}
