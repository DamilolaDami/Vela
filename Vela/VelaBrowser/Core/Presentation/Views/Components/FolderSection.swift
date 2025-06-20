//
//  FolderSection.swift
//  Vela
//
//  Created by damilola on 6/19/25.
//

import SwiftUI

struct FolderSection: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @Binding var hoveredTab: UUID?
    
    @State private var isFolderHeaderHovered: Bool = false
    @State private var expandedFolders: Set<UUID> = []
    @State private var draggedTab: Tab?
    @State private var dropZoneHighlight: UUID?
    @State private var isDragging: Bool = false
    
    var body: some View {
        if !viewModel.folders.isEmpty {
            VStack(spacing: 0) {
                // Folders list
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.folders.sorted { $0.position < $1.position }, id: \.id) { folder in
                        FolderRow(
                            viewModel: viewModel,
                            previewManager: previewManager,
                            folder: folder,
                            isExpanded: expandedFolders.contains(folder.id),
                            hoveredTab: $hoveredTab,
                            draggedTab: $draggedTab,
                            dropZoneHighlight: $dropZoneHighlight,
                            isDragging: $isDragging,
                            onToggle: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if expandedFolders.contains(folder.id) {
                                        expandedFolders.remove(folder.id)
                                    } else {
                                        expandedFolders.insert(folder.id)
                                    }
                                }
                            }
                        )
                    }
                }
              
                
                // Subtle divider
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
           
        }
    }
}

struct FolderRow: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    let folder: Folder
    let isExpanded: Bool
    @Binding var hoveredTab: UUID?
    @Binding var draggedTab: Tab?
    @Binding var dropZoneHighlight: UUID?
    @Binding var isDragging: Bool
    
    @State private var isHovered: Bool = false
    @State private var isRenaming: Bool = false
    @State private var folderName: String
    @FocusState private var isTextFieldFocused: Bool
    
    let onToggle: () -> Void
    
    init(
        viewModel: BrowserViewModel,
        previewManager: TabPreviewManager,
        folder: Folder,
        isExpanded: Bool,
        hoveredTab: Binding<UUID?>,
        draggedTab: Binding<Tab?>,
        dropZoneHighlight: Binding<UUID?>,
        isDragging: Binding<Bool>,
        onToggle: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.previewManager = previewManager
        self.folder = folder
        self.isExpanded = isExpanded
        self._hoveredTab = hoveredTab
        self._draggedTab = draggedTab
        self._dropZoneHighlight = dropZoneHighlight
        self._isDragging = isDragging
        self.onToggle = onToggle
        self._folderName = State(initialValue: folder.name)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern folder header with Arc-like styling
            HStack(spacing: 8) {
                // Expansion indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 12, height: 12)

                // Folder icon
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .foregroundColor(dropZoneHighlight == folder.id ? .blue : viewModel.currentSpace?.displayColor ?? .secondary)
                    .frame(width: 20, height: 20)

                // Folder name or text field
                if isRenaming {
                    TextField("Folder name", text: $folderName)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.08))
                        )
                        .onAppear {
                            isTextFieldFocused = true
                        }
                        .onSubmit {
                            commitRename()
                        }
                        .onKeyPress(.escape) {
                            cancelRename()
                            return .handled
                        }
                } else {
                    Text(folder.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            startRename()
                        }
                }

                Spacer()

                // Tab count badge
                if !folder.tabs.isEmpty {
                    Text("\(folder.tabs.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                        )
                }

                // Action buttons on hover
                if isHovered && !isRenaming {
                    HStack(spacing: 2) {
                        Button(action: {
                            startRename()
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(0.7)

                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.deleteFolder(folder)
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(0.7)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        dropZoneHighlight == folder.id ?
                        Color.blue.opacity(0.1) :
                            (isHovered ? Color(NSColor.quaternaryLabelColor).opacity(1.0) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        dropZoneHighlight == folder.id ?
                        Color.blue.opacity(0.3) :
                            Color.clear,
                        lineWidth: 1
                    )
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            .onDrop(
                of: [.text],
                delegate: FolderDropDelegate(
                    folder: folder,
                    viewModel: viewModel,
                    dropZoneHighlight: $dropZoneHighlight,
                    draggedTab: $draggedTab,
                    isDragging: $isDragging
                )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onToggle() // Toggle expansion on tap
            }

            // Folder contents
            LazyVStack(spacing: 1) {
                ForEach(folder.tabs.sorted { $0.position < $1.position }, id: \.id) { tab in
                    let isActiveTab = tab.id == viewModel.currentTab?.id && !viewModel.isInBoardMode
                    let shouldShowTab = isExpanded || isActiveTab
                    
                    if shouldShowTab {
                        TabRow(
                            viewModel: viewModel,
                            previewManager: previewManager,
                            tab: tab,
                            isSelected: isActiveTab,
                            isHovered: hoveredTab == tab.id,
                            onSelect: { viewModel.selectTab(tab) },
                            onClose: { viewModel.closeAndDeleteTab(tab) },
                            onHover: { isHovering in
                                hoveredTab = isHovering ? tab.id : nil
                            }
                        )
                        .padding(.leading, 20)
                        .padding(.trailing, 10)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
    }
    
    private func startRename() {
        isRenaming = true
        folderName = folder.name
    }
    
    private func cancelRename() {
        isRenaming = false
        folderName = folder.name
        isTextFieldFocused = false
    }
    
    private func commitRename() {
        let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Input: \(folderName), Trimmed: \(trimmedName)")
        
        if !trimmedName.isEmpty {
            var updatedFolder = folder
            updatedFolder.name = folderName
            print("Saving name: \(folderName)")
            viewModel.updateFolder(updatedFolder)
        } else {
            print("Invalid name, reverting to: \(folder.name)")
            folderName = folder.name
        }
        
        isRenaming = false
        isTextFieldFocused = false
    }
}

struct FolderDropDelegate: DropDelegate {
    let folder: Folder
    let viewModel: BrowserViewModel
    @Binding var dropZoneHighlight: UUID?
    @Binding var draggedTab: Tab?
    @Binding var isDragging: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTab = draggedTab,
              let itemProvider = info.itemProviders(for: [.text]).first else {
            cleanup()
            return false
        }
        
        itemProvider.loadObject(ofClass: NSString.self) { (string, error) in
            guard let tabIdString = string as? String,
                  let tabId = UUID(uuidString: tabIdString),
                  draggedTab.id == tabId else {
                DispatchQueue.main.async { self.cleanup() }
                return
            }
            
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.viewModel.addTab(draggedTab, to: self.folder)
                }
                self.cleanup()
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard draggedTab != nil else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            dropZoneHighlight = folder.id
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.easeOut(duration: 0.15)) {
            if dropZoneHighlight == folder.id {
                dropZoneHighlight = nil
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard draggedTab != nil else {
            return DropProposal(operation: .forbidden)
        }
        
        return DropProposal(operation: .move)
    }
    
    private func cleanup() {
        withAnimation(.easeOut(duration: 0.2)) {
            draggedTab = nil
            dropZoneHighlight = nil
            isDragging = false
        }
    }
}
