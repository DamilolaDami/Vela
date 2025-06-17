//
//  QuickAccessGrid.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//
import SwiftUI
import Kingfisher

struct QuickAccessGrid: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    // Make this static to prevent recreation on every view update
    static let quickAccessItems = [
        QuickAccessItem(id: "youtube", title: "YouTube", iconURL: "https://www.google.com/s2/favicons?domain=youtube.com&sz=64", color: Color(NSColor.labelColor), url: "https://youtube.com"),
        QuickAccessItem(id: "figma", title: "Figma", iconURL: "https://www.google.com/s2/favicons?domain=figma.com&sz=64", color: Color(NSColor.labelColor), url: "https://figma.com"),
        QuickAccessItem(id: "spotify", title: "Spotify", iconURL: "https://www.google.com/s2/favicons?domain=open.spotify.com&sz=64", color: Color(NSColor.labelColor), url: "https://spotify.com"),
        QuickAccessItem(id: "notion", title: "Notion", iconURL: "https://www.google.com/s2/favicons?domain=notion.so&sz=64", color: Color(NSColor.labelColor), url: "https://notion.so"),
        QuickAccessItem(id: "twitter", title: "Twitter", iconURL: "https://www.google.com/s2/favicons?domain=twitter.com&sz=64", color: Color(NSColor.labelColor), url: "https://twitter.com")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Access")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                ForEach(Self.quickAccessItems, id: \.id) { item in
                    QuickAccessButton(item: item) {
                        viewModel.openURL(item.url)
                    }
                }
            }
        }
       
    }
}

struct QuickAccessItem: Identifiable {
    let id: String // Use String instead of UUID() for stable identity
    let title: String
    let iconURL: String?
    let systemIcon: String?
    let color: Color
    let url: String
    
    // Convenience initializers with stable ID
    init(id: String, title: String, iconURL: String, color: Color, url: String) {
        self.id = id
        self.title = title
        self.iconURL = iconURL
        self.systemIcon = nil
        self.color = color
        self.url = url
    }
    
    init(id: String, title: String, systemIcon: String, color: Color, url: String) {
        self.id = id
        self.title = title
        self.iconURL = nil
        self.systemIcon = systemIcon
        self.color = color
        self.url = url
    }
}

struct QuickAccessButton: View {
    let item: QuickAccessItem
    let action: () -> Void
    @State private var isHovered = false
    @State private var imageLoaded = false
    
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
                        .frame(width: 55, height: 55)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isHovered ?
                                    Color(NSColor.controlAccentColor).opacity(0.3) :
                                    item.color.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    
                    // Image view with stable identity
                    imageView
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

        .id(item.id)
    }
    
    private var imageView: some View {
        Group {
            if let iconURL = item.iconURL {
                KFImage(URL(string: iconURL))
                    .loadDiskFileSynchronously()
                    .cacheMemoryOnly(false)
                    .fade(duration: 0.1)
                    .onSuccess { _ in
                        imageLoaded = true
                        
                    }
                    .onFailure { error in
                        imageLoaded = false
                      
                    }
                    .placeholder {
                        // Use a consistent placeholder that matches the final image size
                        Rectangle()
                            .fill(item.color.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .cornerRadius(4)
                            .overlay(
                                Image(systemName: "globe")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(item.color)
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .id("\(item.id)-image") // Stable image identity
            } else if let systemIcon = item.systemIcon {
                Image(systemName: systemIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.color)
                    .onAppear {
                        imageLoaded = true
                    }
            }
        }
    }
}
