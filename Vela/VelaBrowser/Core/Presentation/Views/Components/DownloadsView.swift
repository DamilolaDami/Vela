//
//  DownloadsView.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//
import SwiftUI
import WebKit

// MARK: - Unified Download Item Protocol
protocol UnifiedDownloadItem: Identifiable, ObservableObject {
    var id: UUID { get }
    var filename: String { get }
    var dateCreated: Date { get }
    var isDownloading: Bool { get }
    var isCompleted: Bool { get }
    var hasError: Bool { get }
    var downloadType: DownloadType { get }
}

enum DownloadType {
    case browser
    case system
}

// MARK: - Extensions to conform to protocol
extension SystemDownloadItem: UnifiedDownloadItem {
    var isDownloading: Bool { false }
    var isCompleted: Bool { true }
    var hasError: Bool { false }
    var downloadType: DownloadType { .system }
}

extension DownloadItem: UnifiedDownloadItem {
    var dateCreated: Date { Date() }
    var downloadType: DownloadType { .browser }
}

struct DownloadsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var downloadsManager: DownloadsManager
    @State private var searchText = ""
    @State private var selectedFilter = DownloadFilter.all
    
    enum DownloadFilter: CaseIterable {
        case all, browser, system, recent
        
        var title: String {
            switch self {
            case .all: return "All"
            case .browser: return "Browser"
            case .system: return "System"
            case .recent: return "Recent"
            }
        }
    }
    
    var unifiedDownloads: [any UnifiedDownloadItem] {
        var combined: [any UnifiedDownloadItem] = []
        var seenFilenames: Set<String> = []
        
        // First, add browser downloads (prioritize active/recent browser downloads)
        for download in viewModel.downloads {
            combined.append(download)
            seenFilenames.insert(download.filename.lowercased())
        }
        
        // Then add system downloads, but skip duplicates
        for download in downloadsManager.allDownloads {
            let lowercaseFilename = download.filename.lowercased()
            
            // Skip if we already have this filename from browser downloads
            // Check for any browser download with the same filename (active or completed)
            let hasBrowserVersion = viewModel.downloads.contains { browserDownload in
                return browserDownload.filename.lowercased() == lowercaseFilename
            }
            
            if !hasBrowserVersion {
                combined.append(download)
            }
        }
        
        // Sort by date created (most recent first), with active downloads at the top
        return combined.sorted { first, second in
            // Active downloads always come first
            if first.isDownloading && !second.isDownloading {
                return true
            } else if !first.isDownloading && second.isDownloading {
                return false
            }
            // Then sort by date
            return first.dateCreated > second.dateCreated
        }
    }
    
    var filteredDownloads: [any UnifiedDownloadItem] {
        let downloads = unifiedDownloads
        
        // Apply filter
        var filtered: [any UnifiedDownloadItem]
        switch selectedFilter {
        case .all:
            filtered = downloads
        case .browser:
            filtered = downloads.filter { $0.downloadType == .browser }
        case .system:
            filtered = downloads.filter { $0.downloadType == .system }
        case .recent:
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // Last 24 hours
            filtered = downloads.filter { $0.dateCreated >= cutoffDate }
        }
        
        // Apply search
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.filename.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                        
                        Text("Downloads")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Total count badge
                        Text("\(unifiedDownloads.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.blue)
                            )
                    }
                    
                    Spacer()
                    
                    // Actions
                    HStack(spacing: 8) {
                        // Clear browser downloads
                        if !viewModel.downloads.isEmpty {
                            Button(action: {
                                viewModel.clearAllDownloads()
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Clear browser downloads")
                        }
                        
                        // Open Downloads folder
                        Button(action: {
                            NSWorkspace.shared.open(downloadsManager.downloadsURL)
                        }) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Open Downloads folder")
                    }
                }
                
                // Filter Pills
                HStack(spacing: 8) {
                    ForEach(DownloadFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.title,
                            count: countForFilter(filter),
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                    
                    Spacer()
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    
                    TextField("Search downloads...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 11))
                        .onSubmit {
                            // Optional: Handle search submit
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color(NSColor.separatorColor))
                            .opacity(0.5),
                        alignment: .bottom
                    )
            )
            
            // Content
            if filteredDownloads.isEmpty {
                emptyState
            } else {
                downloadsList
            }
        }
        .frame(width: 480, height: 400)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "arrow.down.circle" : "magnifyingglass")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 4) {
                Text(searchText.isEmpty ? "No Downloads" : "No Results")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(searchText.isEmpty ? "Downloaded files will appear here" : "Try adjusting your search or filter")
                    .font(.system(size: 11))
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
    
    @ViewBuilder
    private var downloadsList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredDownloads.indices, id: \.self) { index in
                    let download = filteredDownloads[index]
                    
                    if download.downloadType == .browser {
                        if let browserDownload = download as? DownloadItem {
                            UnifiedDownloadRowView(
                                download: browserDownload,
                                viewModel: viewModel,
                                downloadsManager: downloadsManager
                            )
                        }
                    } else {
                        if let systemDownload = download as? SystemDownloadItem {
                            UnifiedDownloadRowView(
                                download: systemDownload,
                                viewModel: viewModel,
                                downloadsManager: downloadsManager
                            )
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.never)
    }
    
    private func countForFilter(_ filter: DownloadFilter) -> Int {
        switch filter {
        case .all:
            return unifiedDownloads.count
        case .browser:
            return unifiedDownloads.filter { $0.downloadType == .browser }.count
        case .system:
            return unifiedDownloads.filter { $0.downloadType == .system }.count
        case .recent:
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60)
            return unifiedDownloads.filter { $0.dateCreated >= cutoffDate }.count
        }
    }
}

// MARK: - Filter Pill View
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? .blue : Color.secondary.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(count == 0)
        .opacity(count == 0 ? 0.5 : 1.0)
    }
}

// MARK: - Unified Download Row View
struct UnifiedDownloadRowView<Download: UnifiedDownloadItem & ObservableObject>: View {
    @ObservedObject var download: Download
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var downloadsManager: DownloadsManager
    @State private var isHovered = false
    @State private var isPressed = false

    init(download: Download, viewModel: BrowserViewModel, downloadsManager: DownloadsManager) {
        self.download = download
        self.viewModel = viewModel
        self.downloadsManager = downloadsManager
    }

    var body: some View {
        HStack(spacing: 16) {
            // Modern File Icon with glassmorphism effect
            ZStack {
                // Background with subtle gradient and blur
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                iconBackgroundColor(for: download.filename).opacity(0.8),
                                iconBackgroundColor(for: download.filename).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: iconBackgroundColor(for: download.filename).opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: fileIcon(for: download.filename))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)

                // Modern download type indicator
                if download.downloadType == .browser {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(.blue)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 1.5)
                                )
                                .shadow(color: .blue.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                    }
                    .frame(width: 40, height: 40)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)

            // File Info with improved typography
            VStack(alignment: .leading, spacing: 4) {
                Text(download.filename)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if download.downloadType == .browser, let browserDownload = download as? DownloadItem {
                    browserDownloadInfo(browserDownload)
                } else if let systemDownload = download as? SystemDownloadItem {
                    systemDownloadInfo(systemDownload)
                }
            }

            Spacer()

            // Modern action buttons
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isHovered ?
                    Material.ultraThin.opacity(0.8) :
                    Material.ultraThin.opacity(0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isHovered ?
                            Color.primary.opacity(0.08) :
                            Color.clear,
                            lineWidth: 1
                        )
                )
                .padding(.horizontal)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    @ViewBuilder
    private func browserDownloadInfo(_ browserDownload: DownloadItem) -> some View {
        if browserDownload.isDownloading {
            // Modern progress bar with gradient
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: browserDownload.progress)
                    .progressViewStyle(ModernGlassProgressViewStyle())
                    .frame(height: 4)
                
                HStack(spacing: 8) {
                    Text(browserDownload.status)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text("Browser")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.blue.opacity(0.1))
                        )
                }
            }
        } else {
            HStack(spacing: 8) {
                // Status indicator with modern styling
                Group {
                    if browserDownload.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if browserDownload.hasError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
                .font(.system(size: 10, weight: .medium))
                
                Text(browserDownload.status)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(browserDownload.hasError ? .red : .secondary)
                
                Spacer()
                
                // Modern badge
                Text("Browser")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.1))
                    )
            }
        }
    }
    
    @ViewBuilder
    private func systemDownloadInfo(_ systemDownload: SystemDownloadItem) -> some View {
        HStack(spacing: 8) {
            Text(systemDownload.formattedFileSize)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            Circle()
                .fill(.secondary.opacity(0.4))
                .frame(width: 2, height: 2)
            
            Text(relativeDateString(from: systemDownload.dateModified))
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
            
            if systemDownload.isRecentlyDownloaded {
                Text("Recent")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if download.downloadType == .browser {
                browserActionButtons
            } else {
                systemActionButtons
            }
        }
    }
    
    @ViewBuilder
    private var browserActionButtons: some View {
        let browserDownload = download as? DownloadItem
        if let browserDownload = browserDownload {
            if browserDownload.isCompleted {
                ModernActionButton(
                    icon: "folder.fill",
                    color: .blue,
                    isHovered: isHovered
                ) {
                    viewModel.showDownloadInFinder(browserDownload)
                }
            }
            
            ModernActionButton(
                icon: browserDownload.isDownloading ? "stop.fill" : "xmark",
                color: browserDownload.isDownloading ? .red : .secondary,
                isHovered: isHovered
            ) {
                if browserDownload.isDownloading {
                    browserDownload.download?.cancel { _ in }
                }
                viewModel.removeDownload(browserDownload)
            }
        }
    }
    
    @ViewBuilder
    private var systemActionButtons: some View {
        let systemDownload = download as? SystemDownloadItem
        
        ModernActionButton(
            icon: "folder.fill",
            color: .blue,
            isHovered: isHovered
        ) {
            if let systemDownload = systemDownload {
                downloadsManager.showInFinder(systemDownload)
            }
        }
        
        ModernActionButton(
            icon: "arrow.up.right.square.fill",
            color: .green,
            isHovered: isHovered
        ) {
            if let systemDownload = systemDownload {
                downloadsManager.openFile(systemDownload)
            }
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        if download.downloadType == .browser, let browserDownload = download as? DownloadItem {
            if browserDownload.isCompleted {
                Button("Show in Finder") {
                    viewModel.showDownloadInFinder(browserDownload)
                }
                Divider()
            }
            
            Button(browserDownload.isDownloading ? "Cancel Download" : "Remove from List") {
                if browserDownload.isDownloading {
                    browserDownload.download?.cancel { _ in }
                }
                viewModel.removeDownload(browserDownload)
            }
        } else if let systemDownload = download as? SystemDownloadItem {
            Button("Open") {
                downloadsManager.openFile(systemDownload)
            }
            Button("Show in Finder") {
                downloadsManager.showInFinder(systemDownload)
            }
            Divider()
            Button("Move to Trash") {
                downloadsManager.deleteFileFromSystem(systemDownload)
            }
        }
    }
    
    // Helper functions
    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext.fill"
        case "zip", "rar", "7z": return "archivebox.fill"
        case "jpg", "jpeg", "png", "gif", "webp", "heic": return "photo.fill"
        case "mp4", "mov", "avi", "mkv", "webm": return "play.rectangle.fill"
        case "mp3", "wav", "m4a", "flac", "aac": return "music.note"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "ppt", "pptx": return "chart.bar.doc.horizontal.fill"
        case "txt", "rtf": return "text.alignleft"
        case "html", "htm": return "globe"
        case "dmg", "pkg": return "externaldrive.fill"
        case "app": return "app.fill"
        default: return "doc.fill"
        }
    }
    
    private func iconBackgroundColor(for filename: String) -> Color {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return Color(red: 0.94, green: 0.35, blue: 0.35)
        case "zip", "rar", "7z": return Color(red: 0.95, green: 0.65, blue: 0.25)
        case "jpg", "jpeg", "png", "gif", "webp", "heic": return Color(red: 0.34, green: 0.79, blue: 0.41)
        case "mp4", "mov", "avi", "mkv", "webm": return Color(red: 0.67, green: 0.32, blue: 0.95)
        case "mp3", "wav", "m4a", "flac", "aac": return Color(red: 0.94, green: 0.51, blue: 0.76)
        case "doc", "docx": return Color(red: 0.33, green: 0.63, blue: 0.95)
        case "xls", "xlsx": return Color(red: 0.25, green: 0.75, blue: 0.35)
        case "ppt", "pptx": return Color(red: 0.95, green: 0.45, blue: 0.25)
        case "txt", "rtf": return Color(red: 0.55, green: 0.55, blue: 0.55)
        case "html", "htm": return Color(red: 0.25, green: 0.55, blue: 0.95)
        case "dmg", "pkg": return Color(red: 0.65, green: 0.65, blue: 0.65)
        case "app": return Color(red: 0.35, green: 0.65, blue: 0.95)
        default: return Color(red: 0.75, green: 0.75, blue: 0.75)
        }
    }
}

// Modern Action Button Component
struct ModernActionButton: View {
    let icon: String
    let color: Color
    let isHovered: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.12))
                        .opacity(isHovered ? 1 : 0)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.2), lineWidth: 0.5)
                                .opacity(isHovered ? 1 : 0)
                        )
                )
                .scaleEffect(isPressed ? 0.85 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// Modern Glass Progress View Style
struct ModernGlassProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5)
                    )
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.blue
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
}

// MARK: - Modern Progress View Style
struct ModernProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.blue, Color(red: 0.3, green: 0.7, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0))
                    .animation(.easeInOut(duration: 0.2), value: configuration.fractionCompleted)
            }
        }
    }
}

// MARK: - Extensions (keep existing ones)
extension BrowserViewModel {
    func addDownload(_ downloadItem: DownloadItem) {
        downloads.append(downloadItem)
        print("📥 Added download: \(downloadItem.filename)")
    }
    
    var activeDownloadsCount: Int {
        return downloads.filter { $0.isDownloading }.count
    }
    
    func removeDownload(_ download: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            if download.isDownloading {
                download.download?.cancel { _ in }
            }
            downloads.remove(at: index)
        }
    }
    
    func clearAllDownloads() {
        for download in downloads where download.isDownloading {
            download.download?.cancel { _ in }
        }
        downloads.removeAll()
    }
    
    func showDownloadInFinder(_ download: DownloadItem) {
        NSWorkspace.shared.selectFile(download.url.path, inFileViewerRootedAtPath: "")
    }
}

extension BrowserViewModel {
    
    /// Creates a new browser window with the specified URL
    func createNewWindow(with url: URL? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("🪟 Creating new window...")
            
            // Create configuration for the new web view
            let configuration = WKWebViewConfiguration()
            configuration.allowsAirPlayForMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = []
            
            // Create a new AudioObservingWebView for the new window
            let webView = CustomWKWebView(frame: .zero, configuration: configuration)
            webView.allowsBackForwardNavigationGestures = true
            webView.allowsMagnification = true
            webView.translatesAutoresizingMaskIntoConstraints = true // Disable Auto Layout
            
            // Create a new NSWindow
            let window = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 650, height: 650),
                styleMask: [.titled, .closable, .miniaturizable, .resizable], 
                backing: .buffered,
                defer: false
            )
            
            // Configure window properties
            window.title = url?.host ?? "New Browser Window"
            window.center()
            window.setFrameAutosaveName("") // Disable autosaving to prevent size restoration
            window.isReleasedWhenClosed = false
           
            
            // Set web view frame to match content area
            webView.frame = window.contentRect(forFrameRect: NSRect(x: 0, y: 0, width: 650, height: 650))
            
            // Create a new tab for this window's web view
            let newTab = Tab(url: url ?? URL(string: "about:blank")!, folderId: nil)
            
            // Create coordinator for the web view
            let coordinator = WebViewCoordinator(
                WebViewRepresentable(
                    tab: newTab,
                    isLoading: .constant(false),
                    estimatedProgress: .constant(0.0),
                    browserViewModel: self,
                    suggestionViewModel: self.addressBarVM,
                    noteViewModel: self.noteboardVM
                ),
                tab: newTab
            )
            
            // Set up coordinator reference
            coordinator.browserViewModel = self
            
            // Set up web view delegates BEFORE adding observers
            webView.navigationDelegate = coordinator
            webView.uiDelegate = coordinator
            
            // Add observers
            coordinator.addObservers(to: webView)
            
            // Start audio observation AFTER everything is set up
            webView.startObservingAudio()
            
            // Set up the web view as the window's content view
            window.contentView = webView
            
            // Add to window manager BEFORE making visible
            WindowManager.shared.addWindow(window, with: coordinator)
            
            // Enforce window size
            window.setFrame(NSRect(x: 100, y: 100, width: 650, height: 650), display: true)
            
            // Make the window visible
            window.makeKeyAndOrderFront(nil)
            
            // Load the URL if provided
            if let url = url {
                coordinator.loadURL(url, in: webView)
                print("🪟 Created new window for URL: \(url.absoluteString)")
            } else {
                // Load a default page or about:blank
                if let defaultURL = URL(string: "about:blank") {
                    coordinator.loadURL(defaultURL, in: webView)
                }
                print("🪟 Created new blank window")
            }
        }
    }
}
