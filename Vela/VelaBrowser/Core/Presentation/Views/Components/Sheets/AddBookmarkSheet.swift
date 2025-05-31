//
//  AddBookmarkSheet.swift
//  Vela
//
//  Created by damilola on 5/31/25.
//

import SwiftUI

// MARK: - Add/Edit Bookmark Sheet
struct AddBookmarkSheet: View {
    @ObservedObject var bookmarkViewModel: BookmarkViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var urlString: String = ""
    @State private var tagInput: String = ""
    @State private var selectedTags: [String] = []
    @State private var selectedFolder: Bookmark?
    @State private var notes: String = ""
    @State private var isValidURL: Bool = true
    @State private var showingFolderPicker: Bool = false
    @State private var animateAppearance: Bool = false
    @State private var titleFocused: Bool = false
    @State private var urlFocused: Bool = false
    @State private var notesFocused: Bool = false
    
    let initialURL: URL?
    let initialTitle: String?
    
    init(bookmarkViewModel: BookmarkViewModel, url: URL? = nil, title: String? = nil) {
        self.bookmarkViewModel = bookmarkViewModel
        self.initialURL = url
        self.initialTitle = title
        
        _urlString = State(initialValue: url?.absoluteString ?? "")
        _title = State(initialValue: title ?? "")
    }
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(.systemPurple).opacity(0.02),
                    Color(.systemBlue).opacity(0.03),
                    Color(.systemIndigo).opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with glassmorphism
                headerBar
                
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Hero section with animated icon
                        heroSection
                        
                        // Form fields with beautiful styling
                        VStack(spacing: 24) {
                            titleField
                            urlField
                            folderSelection
                            tagsSection
                            notesField
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 24)
                }
            }
        }
        .frame(width: 520, height: 680)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 15)
        .scaleEffect(animateAppearance ? 1 : 0.9)
        .opacity(animateAppearance ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateAppearance = true
            }
            setupForEditing()
        }
        .sheet(isPresented: $bookmarkViewModel.isShowingCreateFolderSheet) {
            CreateFolderSheet(bookmarkViewModel: bookmarkViewModel)
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    dismiss()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(isEditing ? "Edit Bookmark" : "New Bookmark")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                if let url = URL(string: urlString), let host = url.host {
                    Text(host)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    saveBookmark()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text(isEditing ? "Update" : "Save")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: canSave ? [.blue, .purple] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(canSave ? 0.2 : 0.1), lineWidth: 0.5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .keyboardShortcut(.defaultAction)
            .disabled(!canSave)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Animated background circles
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateAppearance ? 1 : 0.8)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateAppearance)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: isEditing ? "bookmark.circle.fill" : "bookmark.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateAppearance ? 1 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateAppearance)
            }
            
            if !urlString.isEmpty, let url = URL(string: urlString), let host = url.host {
                Text(host)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
        }
    }
    
    // MARK: - Form Fields
    private var titleField: some View {
        ModernField(
            icon: "textformat",
            label: "Title",
            placeholder: "Enter bookmark title",
            text: $title,
            isFocused: $titleFocused
        )
    }
    
    private var urlField: some View {
        VStack(alignment: .leading, spacing: 12) {
            ModernField(
                icon: "link",
                label: "URL",
                placeholder: "https://example.com",
                text: $urlString,
                isFocused: $urlFocused,
                isValid: isValidURL
            )
            .onChange(of: urlString) { _ in
                validateURL()
            }
            
            if !isValidURL {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("Please enter a valid URL")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .slide))
            }
        }
    }
    
    private var folderSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    Text("Folder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Button("Create") {
                    bookmarkViewModel.isShowingCreateFolderSheet.toggle()
                }
            }
            
            Menu {
                Button {
                    selectedFolder = nil
                } label: {
                    HStack {
                        Image(systemName: "house")
                        Text("No Folder")
                    }
                }
                
                if !bookmarkViewModel.folders.isEmpty {
                    Divider()
                    
                    ForEach(bookmarkViewModel.folders, id: \.id) { folder in
                        Button {
                            selectedFolder = folder
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(folder.title)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedFolder == nil ? "house.fill" : "folder.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedFolder == nil ? .secondary : .orange)
                        .frame(width: 16)
                    
                    Text(selectedFolder?.title ?? "No folder selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedFolder == nil ? .secondary : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.pink)
                    .frame(width: 20)
                
                Text("Tags")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Tag input with modern styling
            HStack(spacing: 12) {
                TextField("Add tags...", text: $tagInput)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .onSubmit {
                        addTag()
                    }
                
                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? [.gray.opacity(0.3), .gray.opacity(0.2)]
                                    : [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Selected tags with beautiful chips
            if !selectedTags.isEmpty {
                ModernFlowLayout(spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        ModernTagChip(tag: tag) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }
            
            // Suggested tags
            if !bookmarkViewModel.availableTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ModernFlowLayout(spacing: 6) {
                        ForEach(bookmarkViewModel.availableTags.filter { !selectedTags.contains($0) }, id: \.self) { tag in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedTags.append(tag)
                                }
                            } label: {
                                Text(tag)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                    .frame(width: 20)
                
                Text("Notes")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .font(.system(size: 14, weight: .medium))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(minHeight: 80, maxHeight: 140)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(notesFocused ? .blue.opacity(0.3) : .white.opacity(0.1), lineWidth: notesFocused ? 1 : 0.5)
                    )
                    .onTapGesture {
                        notesFocused = true
                    }
                
                if notes.isEmpty {
                    Text("Add personal notes or description...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isEditing: Bool {
        bookmarkViewModel.bookmarkToEdit != nil
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidURL
    }
    
    // MARK: - Actions
    private func setupForEditing() {
        if let bookmark = bookmarkViewModel.bookmarkToEdit {
            title = bookmark.title
            urlString = bookmark.url?.absoluteString ?? ""
            selectedTags = bookmark.tags
            notes = bookmark.notes ?? ""
            if let folderId = bookmark.folderId {
                selectedFolder = bookmarkViewModel.folders.first { $0.id == folderId }
            }
        }
    }
    
    private func validateURL() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            isValidURL = true
            return
        }
        
        var urlToValidate = trimmed
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            urlToValidate = "https://" + trimmed
            urlString = urlToValidate
        }
        
        isValidURL = URL(string: urlToValidate) != nil
    }
    
    private func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !selectedTags.contains(tag) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTags.append(tag)
            }
            tagInput = ""
        }
    }
    
    private func saveBookmark() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty, !trimmedURL.isEmpty, let url = URL(string: trimmedURL) else {
            return
        }
        
        if let existingBookmark = bookmarkViewModel.bookmarkToEdit {
            var updated = existingBookmark
            updated.title = trimmedTitle
            updated.url = url
            updated.tags = selectedTags
            updated.folderId = selectedFolder?.id
            updated.notes = notes.isEmpty ? nil : notes
            
            bookmarkViewModel.updateBookmark(updated)
        } else {
            bookmarkViewModel.addBookmark(
                title: trimmedTitle,
                url: url,
                tags: selectedTags,
                spaceId: nil,
                folderId: selectedFolder?.id
            )
        }
        
        dismiss()
    }
}

// MARK: - Modern Components

struct ModernField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    let isValid: Bool
    
    init(icon: String, label: String, placeholder: String, text: Binding<String>, isFocused: Binding<Bool>, isValid: Bool = true) {
        self.icon = icon
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self._isFocused = isFocused
        self.isValid = isValid
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            !isValid ? .red.opacity(0.5) :
                            isFocused ? .blue.opacity(0.3) : .white.opacity(0.1),
                            lineWidth: isFocused || !isValid ? 1 : 0.5
                        )
                )
                .onTapGesture {
                    isFocused = true
                }
        }
    }
}

struct ModernTagChip: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [.pink, .purple],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Create Folder Sheet
struct CreateFolderSheet: View {
    @ObservedObject var bookmarkViewModel: BookmarkViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var folderName: String = ""
    @State private var selectedParent: Bookmark?
    @State private var animateAppearance: Bool = false
    @State private var nameFocused: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemOrange).opacity(0.02),
                    Color(.systemYellow).opacity(0.03),
                    Color(.systemRed).opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                            Text("Cancel")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Text("New Folder")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            createFolder()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Create")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: canCreate ? [.orange, .red] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(canCreate ? 0.2 : 0.1), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canCreate)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
                
                // Content
                VStack(spacing: 32) {
                    // Hero section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.orange.opacity(0.15), .red.opacity(0.1)],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 40
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .scaleEffect(animateAppearance ? 1 : 0.8)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateAppearance)
                            
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateAppearance ? 1 : 0.5)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateAppearance)
                        }
                    }
                    .padding(.top, 32)
                    
                    // Form
                    VStack(spacing: 24) {
                        ModernField(
                            icon: "textformat",
                            label: "Folder Name",
                            placeholder: "Enter folder name",
                            text: $folderName,
                            isFocused: $nameFocused
                        )
                        
                        // Parent folder selection (similar to main sheet)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                
                                Text("Parent Folder")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            Menu {
                                Button {
                                    selectedParent = nil
                                } label: {
                                    HStack {
                                        Image(systemName: "house")
                                        Text("Root Folder")
                                    }
                                }
                                
                                if !bookmarkViewModel.folders.isEmpty {
                                    Divider()
                                    
                                    ForEach(bookmarkViewModel.folders, id: \.id) { folder in
                                        Button {
                                            selectedParent = folder
                                        } label: {
                                            HStack {
                                                Image(systemName: "folder")
                                                Text(folder.title)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedParent == nil ? "house.fill" : "folder.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedParent == nil ? .secondary : .orange)
                                        .frame(width: 16)
                                    
                                    Text(selectedParent?.title ?? "Root folder")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedParent == nil ? .secondary : .primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 40)
                }
            }
            .frame(width: 480, height: 520)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 15)
            .scaleEffect(animateAppearance ? 1 : 0.9)
            .opacity(animateAppearance ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateAppearance = true
                }
            }
        }
        
        // MARK: - Computed Properties
       
    }
    private var canCreate: Bool {
        !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    private func createFolder() {
        let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        bookmarkViewModel.createFolder(
            name: trimmedName,
            parentFolderId: selectedParent?.id
        )
        
        dismiss()
    }
}
    
    // MARK: - ModernFlowLayout
struct ModernFlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width + spacing > width && currentRowWidth > 0 {
                height += currentRowHeight + spacing
                currentRowWidth = subviewSize.width
                currentRowHeight = subviewSize.height
            } else {
                if currentRowWidth > 0 {
                    currentRowWidth += spacing
                }
                currentRowWidth += subviewSize.width
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            }
        }
        
        height += currentRowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > bounds.maxX && currentX > bounds.minX {
                currentY += currentRowHeight + spacing
                currentX = bounds.minX
                currentRowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(subviewSize)
            )
            
            currentX += subviewSize.width + spacing
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }
    }
}
