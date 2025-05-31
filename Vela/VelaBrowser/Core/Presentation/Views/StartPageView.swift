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
    @State private var showContent = false
    
    // Clean, simple quick actions
    private var quickActions: [QuickAction] {
        [
            QuickAction(
                title: "New Tab",
                icon: "plus",
                color: .blue,
                action: { viewModel.createNewTab() }
            ),
            QuickAction(
                title: "Bookmarks",
                icon: "heart",
                color: .red,
                action: { showingBookmarks = true }
            ),
            QuickAction(
                title: "History",
                icon: "clock",
                color: .orange,
                action: { print("Show history") }
            ),
            QuickAction(
                title: "Downloads",
                icon: "arrow.down.circle",
                color: .green,
                action: { print("Show downloads") }
            ),
            QuickAction(
                title: "Settings",
                icon: "gearshape",
                color: .gray,
                action: { print("Show settings") }
            ),
            QuickAction(
                title: "Extensions",
                icon: "puzzlepiece.extension",
                color: .purple,
                action: { print("Show extensions") }
            )
        ]
    }
    
    private let frequentSites = [
        FrequentSite(title: "GitHub", url: "https://github.com", color: .black),
        FrequentSite(title: "Stack Overflow", url: "https://stackoverflow.com", color: .orange),
        FrequentSite(title: "Apple Developer", url: "https://developer.apple.com", color: .blue),
        FrequentSite(title: "Swift.org", url: "https://swift.org", color: .orange),
        FrequentSite(title: "Hacker News", url: "https://news.ycombinator.com", color: .orange),
        FrequentSite(title: "Reddit", url: "https://reddit.com", color: .red)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea(.all)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: max(80, geometry.safeAreaInsets.top + 60))
                        
                        VStack(spacing: 48) {
                            // Clean title section
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    Text("Vela")
                                        .font(.system(size: 42, weight: .light, design: .default))
                                        .foregroundColor(.black)
                                        .opacity(showContent ? 1.0 : 0.0)
                                        .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                                    
                                    Text("Navigate the web")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.gray)
                                        .opacity(showContent ? 1.0 : 0.0)
                                        .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)
                                }
                                
                                // Clean search bar
                                HStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    TextField("Search or enter address", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.black)
                                        .onSubmit {
                                            performSearch()
                                        }
                                    
                                    if !searchText.isEmpty {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                searchText = ""
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 10)
                                .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
                            }
                            
                            // Quick Actions
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("Quick Actions")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(0.8), value: showContent)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                                    ForEach(Array(quickActions.enumerated()), id: \.element.title) { index, action in
                                        QuickActionCard(action: action)
                                            .opacity(showContent ? 1.0 : 0.0)
                                            .offset(y: showContent ? 0 : 20)
                                            .animation(.easeOut(duration: 0.5).delay(1.0 + Double(index) * 0.1), value: showContent)
                                    }
                                }
                            }
                            .frame(maxWidth: 600)
                            
                            // Frequent Sites
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("Frequently Visited")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Button("View All") {
                                        showingBookmarks = true
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(1.4), value: showContent)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                                    ForEach(Array(frequentSites.prefix(6).enumerated()), id: \.element.url) { index, site in
                                        FrequentSiteCard(site: site) {
                                            navigateToSite(site.url)
                                        }
                                        .opacity(showContent ? 1.0 : 0.0)
                                        .offset(y: showContent ? 0 : 20)
                                        .animation(.easeOut(duration: 0.5).delay(1.6 + Double(index) * 0.1), value: showContent)
                                    }
                                }
                            }
                            .frame(maxWidth: 600)
                            
                            Spacer()
                                .frame(height: 80)
                        }
                        .padding(.horizontal, 32)
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
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
        
        withAnimation(.easeInOut(duration: 0.3)) {
            searchText = ""
            searchFocused = false
        }
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

// MARK: - Clean Quick Action Card

struct QuickActionCard: View {
    let action: QuickAction
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action.action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(action.color)
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                
                Text(action.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(isHovered ? 0.25 : 0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Clean Frequent Site Card

struct FrequentSiteCard: View {
    let site: FrequentSite
    let onTap: () -> Void
    @State private var isHovered = false
    @StateObject private var faviconLoader = FaviconLoader()
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(site.color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    if let favicon = faviconLoader.image {
                        Image(nsImage: favicon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text(String(site.title.prefix(1)))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(site.color)
                    }
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                
                VStack(spacing: 4) {
                    Text(site.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(URL(string: site.url)?.host ?? site.url)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(isHovered ? 0.25 : 0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            faviconLoader.loadFavicon(for: site.url)
        }
    }
}

// MARK: - Favicon Loader

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

// MARK: - Data Models

struct QuickAction {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct FrequentSite {
    let title: String
    let url: String
    let color: Color
}
