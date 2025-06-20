//
//  DownloadsView.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//
import SwiftUI

struct DownloadsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                    
                    Text("Downloads")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !viewModel.downloads.isEmpty {
                    Button(action: {
                        viewModel.clearAllDownloads()
                    }) {
                        Text("Clear All")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hovering in
                        // Add subtle hover effect
                    }
                }
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
            
            // Content Area
            if viewModel.downloads.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(.tertiary)
                    
                    VStack(spacing: 4) {
                        Text("No Downloads")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Downloaded files will appear here")
                            .font(.system(size: 11))
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                // Downloads List
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.downloads) { download in
                            ModernDownloadRowView(download: download, viewModel: viewModel)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.never)
            }
        }
        .frame(width: 320, height: 280)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Modern Download Row View
struct ModernDownloadRowView: View {
    let download: DownloadItem
    @ObservedObject var viewModel: BrowserViewModel
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Modern File Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconBackgroundColor(for: download.filename))
                    .frame(width: 32, height: 32)
                
                Image(systemName: modernFileIcon(for: download.filename))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // File Info
            VStack(alignment: .leading, spacing: 3) {
                Text(download.filename)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if download.isDownloading {
                    HStack(spacing: 6) {
                        ProgressView(value: download.progress)
                            .progressViewStyle(ModernProgressViewStyle())
                            .frame(height: 3)
                        
                        Text("\(Int(download.progress * 100))%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                            .monospacedDigit()
                    }
                } else {
                    HStack(spacing: 4) {
                        if download.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                        }
                        
                        Text(download.status)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 6) {
                if download.isCompleted {
                    Button(action: {
                        viewModel.showDownloadInFinder(download)
                    }) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(.blue.opacity(0.1))
                                    .opacity(isHovered ? 1 : 0)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    viewModel.removeDownload(download)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(.secondary.opacity(0.1))
                                .opacity(isHovered ? 1 : 0)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func modernFileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext.fill"
        case "zip", "rar", "7z": return "archivebox.fill"
        case "jpg", "jpeg", "png", "gif", "webp": return "photo.fill"
        case "mp4", "mov", "avi", "mkv": return "play.rectangle.fill"
        case "mp3", "wav", "m4a", "flac": return "music.note"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "ppt", "pptx": return "chart.bar.doc.horizontal.fill"
        case "txt": return "text.alignleft"
        case "html", "htm": return "globe"
        case "dmg": return "externaldrive.fill"
        default: return "doc.fill"
        }
    }
    
    private func iconBackgroundColor(for filename: String) -> Color {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return .red
        case "zip", "rar", "7z": return Color(red: 0.9, green: 0.6, blue: 0.2)
        case "jpg", "jpeg", "png", "gif", "webp": return .green
        case "mp4", "mov", "avi", "mkv": return .purple
        case "mp3", "wav", "m4a", "flac": return .pink
        case "doc", "docx": return .blue
        case "xls", "xlsx": return Color(red: 0.2, green: 0.7, blue: 0.3)
        case "ppt", "pptx": return Color(red: 0.9, green: 0.4, blue: 0.2)
        case "txt": return .gray
        case "html", "htm": return Color(red: 0.2, green: 0.5, blue: 0.9)
        case "dmg": return Color(red: 0.5, green: 0.5, blue: 0.5)
        default: return .gray
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
