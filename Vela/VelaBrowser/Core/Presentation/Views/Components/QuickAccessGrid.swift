import SwiftUI
import Kingfisher

// MARK: - Color Extraction Extension for macOS
extension NSImage {
    func dominantColor() -> NSColor? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        var colorCounts: [UInt32: Int] = [:]
        let sampleSize = max(1, (width * height) / 1000) // Sample every nth pixel for performance
        
        for i in stride(from: 0, to: width * height, by: sampleSize) {
            let pixelIndex = i * bytesPerPixel
            let r = pixels[pixelIndex]
            let g = pixels[pixelIndex + 1]
            let b = pixels[pixelIndex + 2]
            let a = pixels[pixelIndex + 3]
            
            // Skip transparent pixels
            if a < 128 { continue }
            
            // Quantize colors to reduce noise
            let quantizedR = (r / 32) * 32
            let quantizedG = (g / 32) * 32
            let quantizedB = (b / 32) * 32
            
            let color = (UInt32(quantizedR) << 16) | (UInt32(quantizedG) << 8) | UInt32(quantizedB)
            colorCounts[color, default: 0] += 1
        }
        
        // Find the most common color
        guard let dominantColor = colorCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        let r = CGFloat((dominantColor >> 16) & 0xFF) / 255.0
        let g = CGFloat((dominantColor >> 8) & 0xFF) / 255.0
        let b = CGFloat(dominantColor & 0xFF) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    func averageColor() -> NSColor? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        var totalR: UInt64 = 0
        var totalG: UInt64 = 0
        var totalB: UInt64 = 0
        var pixelCount: UInt64 = 0
        
        for i in 0..<(width * height) {
            let pixelIndex = i * bytesPerPixel
            let r = pixels[pixelIndex]
            let g = pixels[pixelIndex + 1]
            let b = pixels[pixelIndex + 2]
            let a = pixels[pixelIndex + 3]
            
            // Skip transparent pixels
            if a < 128 { continue }
            
            totalR += UInt64(r)
            totalG += UInt64(g)
            totalB += UInt64(b)
            pixelCount += 1
        }
        
        guard pixelCount > 0 else { return nil }
        
        let avgR = CGFloat(totalR / pixelCount) / 255.0
        let avgG = CGFloat(totalG / pixelCount) / 255.0
        let avgB = CGFloat(totalB / pixelCount) / 255.0
        
        return NSColor(red: avgR, green: avgG, blue: avgB, alpha: 1.0)
    }
}

// MARK: - Quick Access Components
struct QuickAccessGrid: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var showingAddSheet = false
    
    static let quickAccessItems = [
        QuickAccessItem(id: "youtube", title: "YouTube", iconURL: "https://www.google.com/s2/favicons?domain=youtube.com&sz=64", color: Color(NSColor.labelColor), url: "https://youtube.com"),
        QuickAccessItem(id: "figma", title: "Figma", iconURL: "https://www.google.com/s2/favicons?domain=figma.com&sz=64", color: Color(NSColor.labelColor), url: "https://figma.com"),
        QuickAccessItem(id: "spotify", title: "Spotify", iconURL: "https://www.google.com/s2/favicons?domain=open.spotify.com&sz=64", color: Color(NSColor.labelColor), url: "https://spotify.com"),
        QuickAccessItem(id: "notion", title: "Notion", iconURL: "https://www.google.com/s2/favicons?domain=notion.so&sz=64", color: Color(NSColor.labelColor), url: "https://notion.so"),
        QuickAccessItem(id: "twitter", title: "X", iconURL: "https://www.google.com/s2/favicons?domain=twitter.com&sz=64", color: Color(NSColor.labelColor), url: "https://x.com"),
        QuickAccessItem(id: "chatgpt", title: "ChatGPT", iconURL: "https://www.google.com/s2/favicons?domain=chat.openai.com&sz=64", color: Color(NSColor.labelColor), url: "https://chatgpt.com/"),
        QuickAccessItem(id: "gmail", title: "Gmail", iconURL: "https://ssl.gstatic.com/ui/v1/icons/mail/images/favicon2.ico", color: Color(NSColor.labelColor), url: "https://mail.google.com/mail/")
    ]
    
    var body: some View {
        let currentUrl = viewModel.currentTab?.url
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(Self.quickAccessItems, id: \.id) { item in
                    QuickAccessButton(
                        item: item,
                        isSelected: isItemSelected(item: item, currentUrl: currentUrl?.absoluteString)
                    ) {
                        viewModel.openQuickAccessURL(item.url)
                    }
                }
                
                // Add Button
                AddQuickAccessButton {
                    showingAddSheet = true
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddQuickAccessSheet()
        }
    }
    
    private func isItemSelected(item: QuickAccessItem, currentUrl: String?) -> Bool {
        guard let currentUrl = currentUrl,
              let currentHost = URL(string: currentUrl)?.host,
              let itemHost = URL(string: item.url)?.host else {
            return false
        }
        
        let normalizedCurrentHost = currentHost.hasPrefix("www.") ? String(currentHost.dropFirst(4)) : currentHost
        let normalizedItemHost = itemHost.hasPrefix("www.") ? String(itemHost.dropFirst(4)) : itemHost
        
        return normalizedCurrentHost == normalizedItemHost
    }
}

struct AddQuickAccessButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundFill)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderStroke, lineWidth: 1)
                                .overlay(
                                    // Dashed border effect
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        .foregroundColor(.secondary.opacity(0.5))
                                )
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                
                Text("Add")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundFill: some ShapeStyle {
        if isHovered {
            return AnyShapeStyle(Color.secondary.opacity(0.1))
        } else {
            return AnyShapeStyle(Color.secondary.opacity(0.05))
        }
    }
    
    private var borderStroke: Color {
        if isHovered {
            return .secondary.opacity(0.3)
        } else {
            return .secondary.opacity(0.15)
        }
    }
}

struct AddQuickAccessSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var url = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Add Quick Access")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("URL")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter URL", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Add") {
                    // TODO: Add logic to save the new quick access item
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || url.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400, height: 250)
    }
}

struct QuickAccessItem: Identifiable {
    let id: String
    let title: String
    let iconURL: String?
    let systemIcon: String?
    let color: Color
    let url: String
    
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
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    @State private var imageLoaded = false
    @State private var extractedColor: Color?
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Base background with gradient when selected
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundFill)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderStroke, lineWidth: isSelected ? 2 : 1)
                        )
                    
                    // Additional gradient overlay for selected state
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectionOverlay)
                            .frame(width: 50, height: 50)
                    }
                    
                    imageView
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                
                Text(item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? (extractedColor ?? Color(NSColor.controlAccentColor)) : .primary)
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
                    .onSuccess { result in
                        imageLoaded = true
                        extractColorFromImage(result.image)
                    }
                    .onFailure { error in
                        imageLoaded = false
                    }
                    .placeholder {
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
                    .id("\(item.id)-image")
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
    
    // Computed properties for styling
    private var backgroundFill: LinearGradient {
        let baseColor = extractedColor ?? Color(NSColor.controlAccentColor)
        
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.25),
                    baseColor.opacity(0.15),
                    baseColor.opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.15),
                    baseColor.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    item.color.opacity(0.1),
                    item.color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderStroke: LinearGradient {
        let baseColor = extractedColor ?? Color(NSColor.controlAccentColor)
        
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.8),
                    baseColor.opacity(0.6),
                    baseColor.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.3),
                    baseColor.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    item.color.opacity(0.1),
                    item.color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var selectionOverlay: some ShapeStyle {
        let baseColor = extractedColor ?? Color(NSColor.controlAccentColor)
        return LinearGradient(
            gradient: Gradient(colors: [
                baseColor.opacity(0.2),
                baseColor.opacity(0.05),
                baseColor.opacity(0.15)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func extractColorFromImage(_ image: NSImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Try dominant color first, fallback to average color
            let color = image.dominantColor() ?? image.averageColor()
            
            DispatchQueue.main.async {
                if let color = color {
                    self.extractedColor = Color(color)
                }
            }
        }
    }
}
