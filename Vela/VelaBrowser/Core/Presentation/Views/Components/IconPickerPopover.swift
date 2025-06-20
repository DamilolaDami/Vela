//
//  IconPickerPopover.swift
//  Vela
//
//  Created by damilola on 6/18/25.
//
import SwiftUI


struct IconPickerPopover: View {
    @Binding var selectedIconType: IconType
    @Binding var selectedIconValue: String
    @Binding var showIconPicker: Bool
    
    @State private var searchText = ""
    @State private var selectedEmojiCategory: EmojiCategory = .smileys
    
    // Organized emoji categories
    private let emojiCategories: [EmojiCategory: [String]] = [
        .smileys: ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "🤥"],
        .objects: ["📱", "💻", "⌚", "📺", "📻", "📷", "📹", "🎥", "📞", "☎️", "📟", "📠", "🔌", "🔋", "🖥️", "🖨️", "⌨️", "🖱️", "💾", "💿", "📀", "🎮", "🕹️", "📱", "📲", "💳", "💰", "💴", "💵", "💶", "💷", "💸", "🏧", "💹", "💻", "⌨️", "🖥️", "🖨️", "📱"],
        .symbols: ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️", "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐", "⭐", "🌟", "💫", "⚡", "🔥", "💥", "✨", "🌈", "☀️", "🌤️"],
        .activities: ["⚽", "🏀", "🏈", "⚾", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥅", "⛳", "🪁", "🏹", "🎣", "🤿", "🥊", "🥋", "🎽", "🛹", "🛷", "⛸️", "🥌", "🎿", "⛷️", "🏂", "🪂", "🏋️", "🤸", "🤺", "🤾", "🏌️"],
        .nature: ["🌱", "🌿", "☘️", "🍀", "🎋", "🎍", "🌾", "🌵", "🌲", "🌳", "🌴", "🌭", "🍄", "🌰", "🐚", "🪸", "🪨", "🌍", "🌎", "🌏", "🌐", "🗺️", "🏔️", "⛰️", "🌋", "🗻", "🏕️", "🏖️", "🏜️", "🏝️", "🏞️", "🏟️", "🏛️", "🏗️", "🏘️", "🏚️", "🏠", "🏡", "🏢", "🏣"],
        .food: ["🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶️", "🫑", "🌽", "🥕", "🫒", "🧄", "🧅", "🥔", "🍠", "🥐", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳", "🧈", "🥞"]
    ]
    
    // Organized system images by category
    private let systemImageCategories: [String: [String]] = [
        "General": ["folder", "folder.fill", "doc", "doc.fill", "archivebox", "archivebox.fill", "tray", "tray.fill", "externaldrive", "externaldrive.fill"],
        "Interface": ["house", "house.fill", "gear", "gear.circle", "slider.horizontal.3", "ellipsis.circle", "plus", "plus.circle", "minus", "minus.circle", "xmark", "xmark.circle", "checkmark", "checkmark.circle"],
        "Communication": ["envelope", "envelope.fill", "phone", "phone.fill", "message", "message.fill", "bubble.left", "bubble.right", "bell", "bell.fill", "speaker.wave.3", "mic", "video", "video.fill"],
        "Media": ["photo", "photo.fill", "camera", "camera.fill", "music.note", "play", "play.fill", "pause", "pause.fill", "backward", "forward", "speaker", "headphones", "tv", "gamecontroller"],
        "Productivity": ["calendar", "clock", "timer", "stopwatch", "alarm", "pencil", "highlighter", "trash", "paperclip", "link", "bookmark", "flag", "tag", "magnifyingglass", "chart.bar"],
        "People": ["person", "person.fill", "person.2", "person.3", "person.crop.circle", "face.smiling", "heart", "heart.fill", "star", "star.fill", "crown", "medal", "trophy", "gift", "balloon"],
        "Travel": ["car", "car.fill", "airplane", "train.side.front.car", "bicycle", "figure.walk", "map", "globe", "location", "compass", "signpost.right", "building", "building.2", "house.lodge", "tent"],
        "Weather": ["sun.max", "moon", "cloud", "cloud.rain", "cloud.snow", "bolt", "thermometer", "wind", "hurricane", "rainbow", "snowflake", "flame", "drop", "leaf", "tree"]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                HStack {
                    Text("Choose Icon")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Button("Done") {
                        showIconPicker = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search icons...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Type selector
                Picker("Icon Type", selection: $selectedIconType) {
                    ForEach(IconType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content area
            Group {
                switch selectedIconType {
                case .emoji:
                    emojiPickerView
                case .systemImage:
                    systemImagePickerView
                case .custom:
                    customIconView
                }
            }
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var emojiPickerView: some View {
        VStack(spacing: 0) {
            // Emoji category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EmojiCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedEmojiCategory = category
                        }) {
                            VStack(spacing: 4) {
                                Text(category.icon)
                                    .font(.system(size: 16))
                                Text(category.displayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(selectedEmojiCategory == category ? .primary : .secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEmojiCategory == category ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            // Emoji grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                    ForEach(filteredEmojis, id: \.self) { emoji in
                        Button(action: {
                            selectedIconValue = emoji
                            showIconPicker = false
                        }) {
                            Text(emoji)
                                .font(.system(size: 20))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedIconValue == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedIconValue == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }
    
    private var systemImagePickerView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(systemImageCategories.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                            ForEach(filteredSystemImages(for: category), id: \.self) { imageName in
                                Button(action: {
                                    selectedIconValue = imageName
                                    showIconPicker = false
                                }) {
                                    Image(systemName: imageName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(selectedIconValue == imageName ? Color.accentColor.opacity(0.2) : Color.clear)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(selectedIconValue == imageName ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private var customIconView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                
                Text("Custom Icons")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Upload your own icons or choose from thousands of additional options")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
            }
            
            VStack(spacing: 12) {
                Button("Browse Files...") {
                    // Handle file selection
                }
                .buttonStyle(.borderedProminent)
                
                Button("Use System Icon Instead") {
                    selectedIconType = .systemImage
                    selectedIconValue = "folder"
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var filteredEmojis: [String] {
        let emojis = emojiCategories[selectedEmojiCategory] ?? []
        if searchText.isEmpty {
            return emojis
        }
        return emojis.filter { emoji in
            // Simple emoji filtering - in practice you'd want emoji names/keywords
            true
        }
    }
    
    private func filteredSystemImages(for category: String) -> [String] {
        let images = systemImageCategories[category] ?? []
        if searchText.isEmpty {
            return images
        }
        return images.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}

enum EmojiCategory: CaseIterable {
    case smileys, objects, symbols, activities, nature, food
    
    var displayName: String {
        switch self {
        case .smileys: return "Smileys"
        case .objects: return "Objects"
        case .symbols: return "Symbols"
        case .activities: return "Activities"
        case .nature: return "Nature"
        case .food: return "Food"
        }
    }
    
    var icon: String {
        switch self {
        case .smileys: return "😊"
        case .objects: return "📱"
        case .symbols: return "⭐"
        case .activities: return "⚽"
        case .nature: return "🌿"
        case .food: return "🍎"
        }
    }
}
