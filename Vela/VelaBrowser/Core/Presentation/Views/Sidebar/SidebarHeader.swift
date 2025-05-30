import SwiftUI

struct SidebarHeader: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var showProfileMenu = false
    @State private var showDownloads = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick action bar
            HStack(spacing: 16) {
                // Search button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12))
                        Text("Search")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Browser mode toggle
                Button(action: {}) {
                    Image(systemName: viewModel.isIncognitoMode ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.isIncognitoMode ? .orange : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Downloads
                Button(action: {
                    showDownloads.toggle()
                }) {
                    ZStack {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        // Badge for active downloads
                        if viewModel.activeDownloadsCount > 0 {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showDownloads, arrowEdge: .bottom) {
                    DownloadsView(viewModel: viewModel)
                        .frame(width: 300, height: 200)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Separator
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 0.5)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Downloads View
struct DownloadsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Downloads")
                    .font(.headline)
                    .padding(.leading, 16)
                    .padding(.top, 12)
                
                Spacer()
                
                Button("Clear All") {
                    viewModel.clearAllDownloads()
                }
                .font(.caption)
                .padding(.trailing, 16)
                .padding(.top, 12)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Downloads list
            if viewModel.downloads.isEmpty {
                VStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No downloads yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.downloads) { download in
                            DownloadRowView(download: download, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}

// MARK: - Download Row View
struct DownloadRowView: View {
    let download: DownloadItem
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            // File icon
            Image(systemName: fileIcon(for: download.filename))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(download.filename)
                    .font(.caption)
                    .lineLimit(1)
                
                if download.isDownloading {
                    ProgressView(value: download.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 4)
                } else {
                    Text(download.status)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            if download.isCompleted {
                Button(action: {
                    viewModel.showDownloadInFinder(download)
                }) {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                viewModel.removeDownload(download)
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
    
    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "zip", "rar", "7z": return "doc.zipper"
        case "jpg", "jpeg", "png", "gif": return "photo"
        case "mp4", "mov", "avi": return "play.rectangle"
        case "mp3", "wav", "m4a": return "music.note"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        case "ppt", "pptx": return "presentation"
        default: return "doc"
        }
    }
}

// MARK: - Extensions
extension BrowserViewModel {
    var isIncognitoMode: Bool {
        // Return actual incognito state
        return false // Placeholder
    }
}
