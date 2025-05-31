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
