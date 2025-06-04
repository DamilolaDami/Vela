//
//  VelaPilotView.swift
//  Vela
//
//  Created by damilola on 6/1/25
//

import SwiftUI

struct VelaPilotView: View {
    @StateObject var viewModel: VelaPilotViewModel
    @ObservedObject var browserViewModel: BrowserViewModel
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
           
                // Main content only when visible
                VStack(spacing: 0) {
                    searchHeader
                    commandContent
                    bottomActions
                }
                .frame(width: 640, height: min(650, calculateHeight()))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColor)
                )
                .shadow(color: .black.opacity(0.25), radius: 60, x: 0, y: 24)
                .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.94).combined(with: .opacity),
                    removal: .scale(scale: 1.04).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.isVisible)
                .focusable()
                .focused($isTextFieldFocused)
                .onKeyPress(.upArrow) {
                    viewModel.selectPrevious()
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    viewModel.selectNext()
                    return .handled
                }
                .onKeyPress(.return) {
                    viewModel.executeSelectedCommand()
                    return .handled
                }
                .onKeyPress(.escape) {
                    viewModel.hide()
                    return .handled
                }
        }
        .onAppear {
            viewModel.show()
            isTextFieldFocused = true
        }
    }
    
    private func calculateHeight() -> CGFloat {
        let headerHeight: CGFloat = 74
        let bottomActionsHeight: CGFloat = 56
        let contentHeight = CGFloat(min(viewModel.filteredCommands.count * 55 + (viewModel.groupedCommands.count * 32), 470))
        return headerHeight + contentHeight + bottomActionsHeight
    }
    
    private var searchHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Search icon
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
                
                TextField("Search for commands, tabs, or actions...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .focused($isTextFieldFocused)
                    .onChange(of: viewModel.searchText) { newValue in
                        viewModel.updateSearch(newValue)
                    }
                    .onSubmit {
                        viewModel.executeSelectedCommand()
                    }
                
                Spacer()
                
                // AI button
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.purple.opacity(0.8))
                    
                    Text("Ask AI")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("Tab")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.08))
                )
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        viewModel.updateSearch("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.searchText.isEmpty)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Separator
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.1))
        }
    }
    
    private var commandContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    if viewModel.searchText.isEmpty {
                        // Grouped commands when not searching
                        ForEach(orderedCategories, id: \.self) { category in
                            if let commands = viewModel.groupedCommands[category.rawValue], !commands.isEmpty {
                                CommandGroupView(
                                    groupName: category.rawValue,
                                    commands: commands,
                                    viewModel: viewModel,
                                    onCommandTap: { command in
                                        if let index = viewModel.getGlobalIndex(for: command) {
                                            viewModel.selectedCommandIndex = index
                                            viewModel.executeSelectedCommand()
                                        }
                                    }
                                )
                            }
                        }
                    } else {
                        // Filtered results when searching
                        ForEach(Array(viewModel.filteredCommands.enumerated()), id: \.element.id) { index, command in
                            CommandRowView(
                                command: command,
                                isSelected: index == viewModel.selectedCommandIndex,
                                showCategory: true
                            )
                            .id(index)
                            .onTapGesture {
                                viewModel.selectedCommandIndex = index
                                viewModel.executeSelectedCommand()
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 470)
            .onChange(of: viewModel.selectedCommandIndex) { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
    
    private var orderedCategories: [CommandCategory] {
        return [
            .tabs,
            .navigation,
            .bookmarks,
            .developer,
            //removing integrations  and ai for now
            //.ai,
          //  .integrations,
            .settings,
            .history,
            .downloads,
            .privacy,
            .window,
            .pageActions,
            .search,
            .display
        ]
    }
    
    private var bottomActions: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.1))
            
            HStack(alignment: .center) {
                // Current selection info
                HStack(spacing: 10) {
                    if let selectedCommand = viewModel.selectedCommand {
                        ZStack {
                            Circle()
                                .fill(selectedCommand.category.color.opacity(0.2))
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: selectedCommand.icon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(selectedCommand.category.color)
                        }
                        
                        Text(selectedCommand.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary.opacity(0.8))
                    } else {
                        Text("No selection")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Keyboard shortcuts
                HStack(spacing: 20) {
                    KeyboardShortcutButton(icon: "arrow.turn.up.left", text: "Actions", shortcut: "⌘K")
                    KeyboardShortcutButton(icon: "ellipsis", text: "More", shortcut: "⌘,")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(NSColor.systemGray) : .white
    }
}

// MARK: - Command Group View
struct CommandGroupView: View {
    let groupName: String
    let commands: [VelaPilotCommand]
    let viewModel: VelaPilotViewModel
    let onCommandTap: (VelaPilotCommand) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Group header
            HStack {
                Text(groupName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1.2)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.15))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Commands
            ForEach(commands, id: \.id) { command in
                CommandRowView(
                    command: command,
                    isSelected: viewModel.isCommandSelected(command),
                    showCategory: false
                )
                .onTapGesture {
                    onCommandTap(command)
                }
            }
        }
    }
}

// MARK: - Command Row View
struct CommandRowView: View {
    let command: VelaPilotCommand
    let isSelected: Bool
    let showCategory: Bool
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [command.category.color, command.category.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: command.category.color.opacity(0.3), radius: isSelected ? 4 : 2, x: 0, y: 2)
                
                Image(systemName: command.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center) {
                    Text(command.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if showCategory {
                        Text("in \(command.category.rawValue)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.leading, 8)
                    }
                }
                
                if let subtitle = command.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action indicators
            HStack(spacing: 10) {
                if let shortcut = command.shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                
                Image(systemName: "return")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColorForState())
                .padding(.horizontal, isSelected ? 8 : 0)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
    
    private func backgroundColorForState() -> Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else if isHovering {
            return Color.gray.opacity(0.05)
        } else {
            return .clear
        }
    }
}

// MARK: - Keyboard Shortcut Button
struct KeyboardShortcutButton: View {
    let icon: String
    let text: String
    let shortcut: String
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(shortcut)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(isHovering ? 0.12 : 0.08))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(isHovering ? 0.05 : 0))
        )
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - ViewModel Extension
extension VelaPilotViewModel {
    var selectedCommand: VelaPilotCommand? {
        guard selectedCommandIndex >= 0 && selectedCommandIndex < filteredCommands.count else {
            return nil
        }
        return filteredCommands[selectedCommandIndex]
    }
    
    var groupedCommands: [String: [VelaPilotCommand]] {
        let commands = searchText.isEmpty ? filteredCommands : filteredCommands
        return Dictionary(grouping: commands) { command in
            command.category.rawValue
        }
    }
}
