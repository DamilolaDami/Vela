//
//  FailedToLoadView.swift
//  Vela
//
//  Created by damilola on 6/20/25.
//


import SwiftUI

struct FailedToLoadView: View {
    let tab: Tab
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
            
            Text("Failed to Load Page")
                .font(.title)
                .fontWeight(.bold)
            
            if let url = tab.url {
                Text("Unable to load \(url.absoluteString)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if let errorDescription = tab.lastLoadError?.localizedDescription {
                Text(errorDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: {
                retryAction()
            }) {
                Text("Retry")
                    .font(.headline)
                    .padding()
                    .frame(width: 120)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}


extension Tab {
    // Published property to track load failure state
   
    
    // Set load failure state and error
    func setLoadFailure(error: Error) {
        hasLoadFailed = true
        lastLoadError = error
        handleError(error as? TabError ?? TabError.navigationFailed(url: url, error: error), context: ["source": "setLoadFailure"])
    }
    
    // Clear load failure state on successful load or retry
    func clearLoadFailure() {
        hasLoadFailed = false
        lastLoadError = nil
    }
}
