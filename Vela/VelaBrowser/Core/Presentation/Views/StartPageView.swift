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
    @State private var animateOnAppear = false
    @State private var viewAllHovered = false
    @State private var viewAllPressed = false
    
    // Quick actions with actual functionality
    private var quickActions: [QuickAction] {
        [
            QuickAction(title: "New Tab", icon: "plus.circle.fill", color: .blue, action: {
                viewModel.createNewTab()
            }),
            QuickAction(title: "Bookmarks", icon: "heart.fill", color: .pink, action: {
                showingBookmarks = true
            }),
            QuickAction(title: "History", icon: "clock.fill", color: .orange, action: {
                print("Show history")
            }),
            QuickAction(title: "Downloads", icon: "arrow.down.circle.fill", color: .green, action: {
                print("Show downloads")
            })
        ]
    }
    
    private let frequentSites = [
        FrequentSite(title: "GitHub", url: "https://github.com", favicon: "", color: .purple),
        FrequentSite(title: "Stack Overflow", url: "https://stackoverflow.com", favicon: "", color: .orange),
        FrequentSite(title: "Apple Developer", url: "https://developer.apple.com", favicon: "", color: .blue),
        FrequentSite(title: "Swift.org", url: "https://swift.org", favicon: "", color: .red)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section with animated gradient
                    VStack(spacing: 28) {
                        Spacer(minLength: max(80, geometry.safeAreaInsets.top + 40))
                        
                        // Animated welcome section
                        VStack(spacing: 20) {
                            // Logo/Icon with glow effect
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color.accentColor.opacity(0.3),
                                                Color.accentColor.opacity(0.1),
                                                Color.clear
                                            ]),
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(animateOnAppear ? 1.0 : 0.8)
                                    .opacity(animateOnAppear ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 1.2).delay(0.3), value: animateOnAppear)
                                
                                Image(systemName: "safari")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.accentColor, .blue]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(animateOnAppear ? 1.0 : 0.5)
                                    .rotationEffect(.degrees(animateOnAppear ? 0 : -180))
                                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5), value: animateOnAppear)
                            }
                            
                            VStack(spacing: 12) {
                                Text("Welcome to Vela")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.primary, .primary.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(animateOnAppear ? 1.0 : 0.8)
                                    .opacity(animateOnAppear ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.8).delay(0.7), value: animateOnAppear)
                                
                                Text("Your modern browsing companion")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .opacity(animateOnAppear ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.8).delay(0.9), value: animateOnAppear)
                            }
                        }
                        
                        // Enhanced search bar
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.accentColor, .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .font(.system(size: 18, weight: .medium))
                                    .scaleEffect(searchFocused ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3), value: searchFocused)
                                
                                TextField("Search the web or enter URL", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 17, weight: .medium))
                                    .onSubmit {
                                        performSearch()
                                    }
                                    .onTapGesture {
                                        searchFocused = true
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 16))
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.accentColor.opacity(searchFocused ? 0.5 : 0.2),
                                                    Color.blue.opacity(searchFocused ? 0.3 : 0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: searchFocused ? 2 : 1
                                        )
                                }
                            )
                            .scaleEffect(searchFocused ? 1.02 : 1.0)
                            .animation(.spring(response: 0.3), value: searchFocused)
                            .frame(maxWidth: 650)
                            .offset(y: animateOnAppear ? 0 : 50)
                            .opacity(animateOnAppear ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.8).delay(1.1), value: animateOnAppear)
                        }
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 32)
                    .background(
                        ZStack {
                            // Animated gradient background
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.05),
                                    Color.blue.opacity(0.03),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Floating orbs
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color.accentColor.opacity(0.1),
                                                Color.clear
                                            ]),
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 100
                                        )
                                    )
                                    .frame(width: 200, height: 200)
                                    .offset(
                                        x: CGFloat.random(in: -100...100),
                                        y: CGFloat.random(in: -100...100)
                                    )
                                    .opacity(animateOnAppear ? 0.6 : 0.0)
                                    .animation(
                                        .easeInOut(duration: 3.0 + Double(i))
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.5),
                                        value: animateOnAppear
                                    )
                            }
                        }
                    )
                    
                    // Content section with glass morphism
                    VStack(spacing: 48) {
                        // Quick Actions with enhanced design
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.primary, .primary.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: min(4, quickActions.count)), spacing: 20) {
                                ForEach(Array(quickActions.enumerated()), id: \.element.title) { index, action in
                                    QuickActionCard(action: action)
                                        .offset(y: animateOnAppear ? 0 : 30)
                                        .opacity(animateOnAppear ? 1.0 : 0.0)
                                        .animation(.easeOut(duration: 0.6).delay(1.3 + Double(index) * 0.1), value: animateOnAppear)
                                }
                            }
                        }
                        .frame(maxWidth: 800)
                        
                        // Frequent Sites with enhanced design
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text("Frequently Visited")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.primary, .primary.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Spacer()
                                
                                // Custom "View All" button with onTapGesture
                                Text("View All")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.accentColor, .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.accentColor.opacity(viewAllHovered ? 0.6 : 0.3), lineWidth: viewAllHovered ? 2 : 1)
                                            )
                                            .shadow(color: .accentColor.opacity(viewAllHovered ? 0.3 : 0.1), radius: viewAllHovered ? 8 : 4, x: 0, y: 2)
                                    )
                                    .scaleEffect(viewAllPressed ? 0.95 : (viewAllHovered ? 1.05 : 1.0))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewAllHovered)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: viewAllPressed)
                                    .onTapGesture {
                                        showingBookmarks = true
                                    }
                                    .onHover { hovering in
                                        viewAllHovered = hovering
                                    }
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in viewAllPressed = true }
                                            .onEnded { _ in viewAllPressed = false }
                                    )
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: min(4, frequentSites.count)), spacing: 20) {
                                ForEach(Array(frequentSites.enumerated()), id: \.element.url) { index, site in
                                    FrequentSiteCard(site: site) {
                                        navigateToSite(site.url)
                                    }
                                    .offset(y: animateOnAppear ? 0 : 30)
                                    .opacity(animateOnAppear ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.6).delay(1.7 + Double(index) * 0.1), value: animateOnAppear)
                                }
                            }
                        }
                        .frame(maxWidth: 800)
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -10)
                    )
                    .padding(.horizontal, 16)
                }
            }
            .background(
                // Dynamic background
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.95, green: 0.97, blue: 1.0),
                            Color(red: 0.98, green: 0.95, blue: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Mesh gradient effect
                    MeshGradientView()
                        .opacity(0.3)
                        .ignoresSafeArea()
                }
            )
        }
        .onAppear {
            withAnimation {
                animateOnAppear = true
            }
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
        
        // Try multiple favicon sources
        let faviconURLs = [
            "https://www.google.com/s2/favicons?domain=\(host)&sz=32",
            "https://\(host)/favicon.ico",
            "https://\(host)/apple-touch-icon.png",
            "https://\(host)/favicon.png"
        ]
        
        loadFaviconFromURLs(faviconURLs, index: 0)
    }
    
    private func loadFaviconFromURLs(_ urls: [String], index: Int) {
        guard index < urls.count else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.image = nil
            }
            return
        }
        
        guard let url = URL(string: urls[index]) else {
            loadFaviconFromURLs(urls, index: index + 1)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let image = NSImage(data: data),
                   image.size.width > 0 && image.size.height > 0 {
                    self?.image = image
                    self?.isLoading = false
                } else {
                    // Try next URL
                    self?.loadFaviconFromURLs(urls, index: index + 1)
                }
            }
        }.resume()
    }
}

// MARK: - Mesh Gradient Background

struct MeshGradientView: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let colors = [Color.accentColor, .blue, .purple, .pink, .orange, .green]
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colors[i].opacity(0.15),
                                colors[i].opacity(0.05),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: animateGradient ? CGFloat.random(in: -150...150) : CGFloat.random(in: -100...100),
                        y: animateGradient ? CGFloat.random(in: -150...150) : CGFloat.random(in: -100...100)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 8...12))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.5),
                        value: animateGradient
                    )
            }
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Enhanced Quick Action Card

struct QuickActionCard: View {
    let action: QuickAction
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                action.color.opacity(0.3),
                                action.color.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
                    .opacity(isHovered ? 1.0 : 0.0)
                
                // Icon background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(action.color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: action.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [action.color, action.color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(action.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.primary.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            action.action()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Enhanced Frequent Site Card with Favicon Loading

struct FrequentSiteCard: View {
    let site: FrequentSite
    let onTap: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false
    @StateObject private var faviconLoader = FaviconLoader()
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                site.color.opacity(0.3),
                                site.color.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 56, height: 56)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .opacity(isHovered ? 1.0 : 0.0)
                
                // Favicon container
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(site.color.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if faviconLoader.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: site.color))
                            } else if let favicon = faviconLoader.image {
                                Image(nsImage: favicon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                // Fallback to first letter
                                Text(String(site.title.prefix(1)))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [site.color, site.color.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                    )
            }
            
            VStack(spacing: 6) {
                Text(site.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(URL(string: site.url)?.host ?? site.url)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.primary.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            faviconLoader.loadFavicon(for: site.url)
        }
    }
}

// MARK: - Enhanced Data Models

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
