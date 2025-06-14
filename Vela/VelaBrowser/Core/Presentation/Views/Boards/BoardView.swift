//
//  BoardView.swift
//  Vela
//
//  Enhanced Notes Interface with Card Design and Context Menus
//

import SwiftUI

struct BoardView: View {
    @ObservedObject var boardVM: NoteBoardViewModel
    @State private var selectedNote: NoteBoardNote?
    @State private var searchText = ""
    @State private var showingAIPrompt = false
    @State private var aiPromptText = ""
    @State private var editingContent = ""
    @State private var isEditing = false
    @State private var contextMenuNote: NoteBoardNote?
    
    var body: some View {
        HStack(spacing: 16) {
            // Main Content Area
            mainContentView
                .frame(maxWidth: .infinity)
            
            // Right Sidebar - Notes List
            rightSidebarView
                .frame(width: 320)
        }
        .padding(16)
        .overlay(alignment: .bottom) {
            if showingAIPrompt {
                aiPromptBar
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Main Content Area
    private var mainContentView: some View {
        VStack(spacing: 0) {
            if let note = selectedNote {
                noteDetailView(note)
            } else {
                emptyStateView
            }
        }
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    private func noteDetailView(_ note: NoteBoardNote) -> some View {
        VStack(spacing: 0) {
            // Note Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Note")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Text("Created \(note.createdAt, style: .relative)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if note.updatedAt != note.createdAt {
                            Text("• Updated \(note.updatedAt, style: .relative)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { togglePinNote(note) }) {
                        Image(systemName: note.pinned ? "pin.fill" : "pin")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(note.pinned ? .orange : .secondary)
                            .frame(width: 32, height: 32)
                            .background(.quaternary, in: Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { showingAIPrompt = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .medium))
                            Text("AI")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { isEditing ? saveEditing() : startEditing(note) }) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isEditing ? .green : .primary)
                            .frame(width: 32, height: 32)
                            .background(isEditing ? .green.opacity(0.1) : Color(NSColor.windowBackgroundColor), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            
            Divider()
                .background(Color.primary.opacity(0.06))
            
            // Note Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Main Content Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Content")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if !note.content.isEmpty {
                                Text("\(note.content.count) characters")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.1), in: Capsule())
                            }
                        }
                        
                        if isEditing {
                            TextEditor(text: $editingContent)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .scrollContentBackground(.hidden)
                                .padding(20)
                                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.blue.opacity(0.3), lineWidth: 2)
                                )
                                .frame(minHeight: 200)
                        } else {
                            Text(note.content.isEmpty ? "Empty note - click edit to add content" : note.content)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(note.content.isEmpty ? .secondary : .primary)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    if note.content.isEmpty {
                                        startEditing(note)
                                    }
                                }
                        }
                    }
                    .padding(20)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    )
                    
                    // AI Summary Card
                    if let aiSummary = note.aiSummary {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.purple)
                                
                                Text("AI Summary")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button("Regenerate") {
                                    handleAIAction(.summarize, for: note)
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.purple)
                            }
                            
                            Text(aiSummary)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.primary)
                                .padding(16)
                                .background(.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(20)
                        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    // AI Actions Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Actions")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            aiActionCard("Summarize", icon: "doc.text.magnifyingglass", color: .blue) {
                                handleAIAction(.summarize, for: note)
                            }
                            
                            aiActionCard("Expand Ideas", icon: "arrow.up.left.and.arrow.down.right", color: .green) {
                                handleAIAction(.expand, for: note)
                            }
                            
                            aiActionCard("Rewrite", icon: "pencil.and.outline", color: .orange) {
                                handleAIAction(.rewrite, for: note)
                            }
                            
                            aiActionCard("Extract Tasks", icon: "checkmark.circle", color: .purple) {
                                handleAIAction(.extractActions, for: note)
                            }
                        }
                    }
                    .padding(20)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    )
                    
                    // Tags and Source Cards
                    HStack(alignment: .top, spacing: 16) {
                        // Tags Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Tags")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button {
                                    // Add tag functionality
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if note.tags.isEmpty {
                                Text("No tags")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 70), spacing: 6)
                                ], spacing: 6) {
                                    ForEach(note.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(.blue.opacity(0.1), in: Capsule())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        
                        // Source Card
                        if let sourceUrl = note.sourceUrl {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Source")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "link")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                            .frame(width: 24, height: 24)
                                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(note.tabTitle ?? "Web Source")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            
                                            Text(sourceUrl)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    Button("Open Source") {
                                        // Open source URL
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(24)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Select a Note")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Choose a note from the sidebar to view and edit its content")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Button("Create New Note") {
                createNewNote()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Right Sidebar
    private var rightSidebarView: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            VStack(spacing: 20) {
                HStack {
                    Text("Notes")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { createNewNote() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)
                }
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search notes...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(20)
            
            // Notes List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredNotes) { note in
                        noteCard(note)
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("\(boardVM.notes.count) \(boardVM.notes.count == 1 ? "note" : "notes")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    private func noteCard(_ note: NoteBoardNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Note content preview
            VStack(alignment: .leading, spacing: 8) {
                Text(note.content.isEmpty ? "Empty note" : String(note.content.prefix(80)))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(note.content.isEmpty ? .secondary : .primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    Text(note.createdAt, style: .relative)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if note.pinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                    
                    if note.aiSummary != nil {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(.purple)
                    }
                    
                    Spacer()
                    
                    // Context menu button
                    Button {
                        // Context menu will be handled by the card itself
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(0) // Hidden, context menu will show on right-click
                }
            }
            
            // Tags preview
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.blue.opacity(0.1), in: Capsule())
                        }
                        
                        if note.tags.count > 3 {
                            Text("+\(note.tags.count - 3)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.secondary.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            Group {
                if selectedNote?.id == note.id {
                    // Selected: White background with shadow for elevation
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                } else {
                    // Unselected: Transparent background
                    Color.clear
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedNote?.id == note.id ?
                        Color.clear : // No border for selected (elevation handles it)
                        Color.primary.opacity(0.08), // Subtle border for unselected
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            selectNote(note)
        }
        .contextMenu {
            noteContextMenu(for: note)
        }
    }
    
    // MARK: - Context Menu
    private func noteContextMenu(for note: NoteBoardNote) -> some View {
        Group {
            Button {
                selectNote(note)
                startEditing(note)
            } label: {
                Label("Edit Note", systemImage: "pencil")
            }
            
            Button {
                togglePinNote(note)
            } label: {
                Label(note.pinned ? "Unpin Note" : "Pin Note",
                      systemImage: note.pinned ? "pin.slash" : "pin")
            }
            
            Divider()
            
            Button {
                duplicateNote(note)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button {
                shareNote(note)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Menu("AI Actions") {
                Button("Summarize") {
                    handleAIAction(.summarize, for: note)
                }
                Button("Expand Ideas") {
                    handleAIAction(.expand, for: note)
                }
                Button("Rewrite") {
                    handleAIAction(.rewrite, for: note)
                }
                Button("Extract Tasks") {
                    handleAIAction(.extractActions, for: note)
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                deleteNote(note)
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        }
    }
    
    // MARK: - AI Prompt Bar
    private var aiPromptBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.purple)
            
            TextField("Ask AI about this note...", text: $aiPromptText)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium))
                .onSubmit {
                    processAIPrompt()
                }
            
            Button(action: { processAIPrompt() }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 32, height: 32)
            .background(aiPromptText.isEmpty ? Color.secondary : Color.blue, in: Circle())
            .buttonStyle(.plain)
            .disabled(aiPromptText.isEmpty)
            
            Button(action: {
                showingAIPrompt = false
                aiPromptText = ""
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Helper Views
    private func aiActionCard(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    private var filteredNotes: [NoteBoardNote] {
        let notes = searchText.isEmpty ? boardVM.notes :
            boardVM.notes.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        
        // Sort pinned notes first, then by update date
        return notes.sorted { first, second in
            if first.pinned != second.pinned {
                return first.pinned
            }
            return first.updatedAt > second.updatedAt
        }
    }
    
    // MARK: - Actions
    private func selectNote(_ note: NoteBoardNote) {
        if isEditing {
            saveEditing()
        }
        selectedNote = note
    }
    
    private func createNewNote() {
        let newNote = NoteBoardNote(
            id: UUID(),
            content: "",
            createdAt: Date(),
            updatedAt: Date(),
            sourceUrl: nil,
            tabTitle: nil,
            faviconUrl: nil,
            sessionId: nil,
            tags: [],
            aiSummary: nil,
            suggestions: nil,
            pinned: false,
            archived: false,
            colorLabel: nil
        )
        boardVM.createNote(newNote)
        selectedNote = newNote
        startEditing(newNote)
    }
    
    private func startEditing(_ note: NoteBoardNote) {
        editingContent = note.content
        isEditing = true
    }
    
    private func saveEditing() {
        guard let note = selectedNote else { return }
        
        var updatedNote = note
        updatedNote.content = editingContent
        updatedNote.updatedAt = Date()
        boardVM.updateNote(updatedNote)
        selectedNote = updatedNote
        isEditing = false
    }
    
    private func togglePinNote(_ note: NoteBoardNote) {
        var updatedNote = note
        updatedNote.pinned.toggle()
        updatedNote.updatedAt = Date()
        boardVM.updateNote(updatedNote)
        if selectedNote?.id == note.id {
            selectedNote = updatedNote
        }
    }
    
    private func duplicateNote(_ note: NoteBoardNote) {
        let duplicatedNote = NoteBoardNote(
            id: UUID(),
            content: note.content,
            createdAt: Date(),
            updatedAt: Date(),
            sourceUrl: note.sourceUrl,
            tabTitle: note.tabTitle,
            faviconUrl: note.faviconUrl,
            sessionId: nil,
            tags: note.tags,
            aiSummary: nil, // Don't duplicate AI summary
            suggestions: nil,
            pinned: false, // Don't duplicate pin status
            archived: false,
            colorLabel: note.colorLabel
        )
        boardVM.createNote(duplicatedNote)
    }
    
    private func shareNote(_ note: NoteBoardNote) {
        // Implement share functionality
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(note.content, forType: .string)
    }
    
    private func deleteNote(_ note: NoteBoardNote) {
        boardVM.deleteNote(note)
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
    }
    
    private func processAIPrompt() {
        guard let note = selectedNote, !aiPromptText.isEmpty else { return }
        // Process AI prompt with the selected note
        // Implementation depends on your AI service
        aiPromptText = ""
        showingAIPrompt = false
    }
    
    private func handleAIAction(_ action: AIAction, for note: NoteBoardNote) {
        // Handle AI actions
        switch action {
        case .summarize:
            // Generate AI summary
            break
        case .expand:
            // Expand note content
            break
        case .rewrite:
            // Rewrite note content
            break
        case .extractActions:
            // Extract action items
            break
        }
    }
}

// MARK: - Supporting Types
enum AIAction {
    case summarize
    case expand
    case rewrite
    case extractActions
}
