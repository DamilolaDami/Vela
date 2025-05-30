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
    
    let quickAccessItems = [
        QuickAccessItem(title: "YouTube", iconURL: "https://www.google.com/s2/favicons?domain=youtube.com&sz=64", color: .red, url: "https://youtube.com"),
        
        QuickAccessItem(title: "Figma", iconURL: "https://www.google.com/s2/favicons?domain=figma.com&sz=64", color: .orange, url: "https://figma.com"),
        QuickAccessItem(title: "Spotify", iconURL: "https://www.google.com/s2/favicons?domain=open.spotify.com&sz=64", color: .green, url: "https://spotify.com"),
        QuickAccessItem(title: "Notion", iconURL: "https://www.google.com/s2/favicons?domain=notion.so&sz=64", color: Color(NSColor.labelColor), url: "https://notion.so"),
        QuickAccessItem(title: "Twitter", iconURL: "https://www.google.com/s2/favicons?domain=twitter.com&sz=64", color: .blue, url: "https://twitter.com")
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
                ForEach(quickAccessItems) { item in
                    QuickAccessButton(item: item) {
                        viewModel.openURL(item.url)
                    }
                }
            }
        }
    }
}

struct QuickAccessItem: Identifiable {
    let id = UUID()
    let title: String
    let iconURL: String?
    let systemIcon: String?
    let color: Color
    let url: String
    
    // Convenience initializers
    init(title: String, iconURL: String, color: Color, url: String) {
        self.title = title
        self.iconURL = iconURL
        self.systemIcon = nil
        self.color = color
        self.url = url
    }
    
    init(title: String, systemIcon: String, color: Color, url: String) {
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
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isHovered ?
                                    Color(NSColor.controlAccentColor).opacity(0.3) :
                                    item.color.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    
                    Group {
                        if let iconURL = item.iconURL {
                            KFImage(URL(string: iconURL))
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                                .onProgress { receivedSize, totalSize in
                                    // Optional: handle progress if needed
                                }
                                .onSuccess { result in
                                    // Optional: handle success if needed
                                }
                                .onFailure { error in
                                    // Optional: handle failure if needed
                                    print("Failed to load favicon: \(error)")
                                }
                                .placeholder {
                                    // Fallback to system icon or loading indicator
                                    if let systemIcon = item.systemIcon {
                                        Image(systemName: systemIcon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(item.color)
                                    } else {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                    }
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        } else if let systemIcon = item.systemIcon {
                            Image(systemName: systemIcon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(item.color)
                        }
                    }
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
    }
}
