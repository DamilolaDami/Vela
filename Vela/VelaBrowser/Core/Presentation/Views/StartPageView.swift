//
//  StartPageView.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//

import SwiftUI

struct StartPageView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var searchText = ""
    @State private var showingBookmarks = false
    @State private var searchFocused = false
    
    // Quick actions with clean, minimal design
    private var quickActions: [QuickAction] {
        [
            QuickAction(title: "New Tab", icon: "plus", color: .primary, action: {
                viewModel.createNewTab()
            }),
            QuickAction(title: "Bookmarks", icon: "heart", color: .primary, action: {
                showingBookmarks = true
            }),
            QuickAction(title: "History", icon: "clock", color: .primary, action: {
                print("Show history")
            }),
            QuickAction(title: "Downloads", icon: "arrow.down.circle", color: .primary, action: {
                print("Show downloads")
            })
        ]
    }
    
    private let frequentSites = [
        FrequentSite(title: "GitHub", url: "https://github.com", favicon: "", color: .primary),
        FrequentSite(title: "Stack Overflow", url: "https://stackoverflow.com", favicon: "", color: .primary),
        FrequentSite(title: "Apple Developer", url: "https://developer.apple.com", favicon: "", color: .primary),
        FrequentSite(title: "Swift.org", url: "https://swift.org", favicon: "", color: .primary),
        FrequentSite(title: "Hacker News", url: "https://news.ycombinator.com", favicon: "", color: .primary),
        FrequentSite(title: "Reddit", url: "https://reddit.com", favicon: "", color: .primary)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer for top padding
                    Spacer()
                        .frame(height: max(60, geometry.safeAreaInsets.top + 40))
                    
                    VStack(spacing: 48) {
                        // Search section - Arc-style centered search
                        VStack(spacing: 20) {
                            // Simple, elegant title
                            Text("Vela")
                                .font(.system(size: 36, weight: .light, design: .default))
                                .foregroundColor(.primary)
                                .opacity(0.8)
                            
                            // Clean search bar
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16, weight: .medium))
                                
                                TextField("Search or enter address", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 16, weight: .regular))
                                    .onSubmit {
                                        performSearch()
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                    )
                            )
                            .frame(maxWidth: 480)
                        }
                        
                        // Quick Actions - Arc-style minimal grid
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .opacity(0.8)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                                ForEach(quickActions, id: \.title) { action in
                                    QuickActionCard(action: action)
                                }
                            }
                        }
                        .frame(maxWidth: 600)
                        
                        // Frequent Sites - Clean grid layout
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Frequently Visited")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .opacity(0.8)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showingBookmarks = true
                                }
                                .buttonStyle(PlainButtonStyle())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 20) {
                                ForEach(Array(frequentSites.prefix(6).enumerated()), id: \.element.url) { index, site in
                                    FrequentSiteCard(site: site) {
                                        navigateToSite(site.url)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: 600)
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onTapGesture {
            searchFocused = false
        }
        .sheet(isPresented: $showingBookmarks) {
            // BookmarkListView()
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        let urlString: String
        if searchText.hasPrefix("http://") || searchText.hasPrefix("https://") {
            urlString = searchText
        } else if searchText.contains(".") && !searchText.contains(" ") {
            urlString = "https://\(searchText)"
        } else {
            urlString = "https://www.google.com/search?q=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        if let url = URL(string: urlString) {
            if viewModel.currentTab != nil {
                viewModel.currentTab?.url = url
            } else {
                viewModel.createNewTab(with: url)
            }
        }
        
        searchText = ""
        searchFocused = false
    }
    
    private func navigateToSite(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if viewModel.currentTab != nil {
            viewModel.currentTab?.url = url
        } else {
            viewModel.createNewTab(with: url)
        }
    }
}

// MARK: - Clean Quick Action Card (Arc-style)

struct QuickActionCard: View {
    let action: QuickAction
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Simple icon
            Image(systemName: action.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primary)
                .opacity(0.7)
            
            Text(action.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .opacity(0.8)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onTapGesture {
            action.action()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Clean Frequent Site Card with Favicon

struct FrequentSiteCard: View {
    let site: FrequentSite
    let onTap: () -> Void
    @State private var isHovered = false
    @StateObject private var faviconLoader = FaviconLoader()
    
    var body: some View {
        VStack(spacing: 12) {
            // Favicon container
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(width: 48, height: 48)
                .overlay(
                    Group {
                        if faviconLoader.isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                                .progressViewStyle(CircularProgressViewStyle())
                        } else if let favicon = faviconLoader.image {
                            Image(nsImage: favicon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            // Fallback to first letter
                            Text(String(site.title.prefix(1)))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .opacity(0.7)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
            
            VStack(spacing: 4) {
                Text(site.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(URL(string: site.url)?.host ?? site.url)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            faviconLoader.loadFavicon(for: site.url)
        }
    }
}

// MARK: - Favicon Loader (Simplified)

class FaviconLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false
    
    private var currentURL: String?
    
    func loadFavicon(for urlString: String) {
        guard currentURL != urlString else { return }
        currentURL = urlString
        
        guard let url = URL(string: urlString),
              let host = url.host else { return }
        
        isLoading = true
        
        // Use Google's favicon service for reliability
        let faviconURL = "https://www.google.com/s2/favicons?domain=\(host)&sz=32"
        
        guard let url = URL(string: faviconURL) else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let data = data, let image = NSImage(data: data) {
                    self?.image = image
                }
            }
        }.resume()
    }
}

// MARK: - Data Models (Simplified)

struct QuickAction {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct FrequentSite {
    let title: String
    let url: String
    let favicon: String
    let color: Color
}
