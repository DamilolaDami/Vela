//
//  NoteBoardSection.swift
//  Vela
//
//  Created by damilola on 6/5/25.
//

import SwiftUI

struct NoteBoardSection: View {
    @ObservedObject var boardVM: NoteBoardViewModel
    @ObservedObject var viewModel: BrowserViewModel
    @State private var hoveredBoardId: UUID?
    let onBoardSelected: () -> Void
    
    var body: some View {
        ZStack{
            if !boardVM.boards.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Section Header
                    HStack {
                        Text("Boards")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Optional: Add board count indicator
                        if !boardVM.boards.isEmpty {
                            Text("\(boardVM.boards.count)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(NSColor.quaternaryLabelColor))
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    
                        LazyVStack(spacing: 4) {
                            ForEach(boardVM.boards, id: \.id) { board in
                                BoardRow(
                                    board: board,
                                    boardVM: boardVM,
                                    isSelected: boardVM.selectedBoard?.id == board.id && viewModel.isInBoardMode,
                                    isHovered: hoveredBoardId == board.id,
                                    onSelect: {
                                        viewModel.selectBoard(board)
                                    },
                                    onHover: { hovering in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            hoveredBoardId = hovering ? board.id : nil
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                
                }
                .padding(.vertical, 8)
            }
        }
            
    }
}

// MARK: - Board Row

struct BoardRow: View {
    let board: NoteBoard // Assuming your board model
    @ObservedObject var boardVM: NoteBoardViewModel
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void
    @State private var isColorPickerHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Board Color Indicator
            BoardColorIndicator(
                board: board,
                isHovered: isColorPickerHovered
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isColorPickerHovered = hovering
                }
            }
            
            // Board Title and Info
            VStack(alignment: .leading, spacing: 2) {
                Text(board.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.3), value: board.title)
                
                // Optional: Show note count or last modified
//                if let noteCount = board.noteCount, noteCount > 0 {
//                    Text("\(noteCount) note\(noteCount == 1 ? "" : "s")")
//                        .font(.system(size: 10))
//                        .foregroundColor(.gray)
//                        .lineLimit(1)
//                }
            }
            
            Spacer()
            
            // Board Status Indicators
            HStack(spacing: 6) {
                // Pinned indicator
              
                // Recent activity indicator
//                if board.hasRecentActivity {
//                    Circle()
//                        .fill(Color.green)
//                        .frame(width: 6, height: 6)
//                        .transition(.scale.combined(with: .opacity))
//                }
            }
            
            // More options button (shown on hover)
            if isHovered || isSelected {
                Button(action: {
                    // Show board options menu
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(Color(NSColor.separatorColor).opacity(0.3))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isSelected ?
                    Color.white :
                    Color(NSColor.controlBackgroundColor).opacity(isHovered ? 1.0 : 0)
                )
                .shadow(
                    color: isSelected ? Color.black.opacity(0.08) : Color.clear,
                    radius: isSelected ? 3 : 0,
                    x: 0,
                    y: isSelected ? 1 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.gray.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            BoardContextMenu(board: board, boardVM: boardVM)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onSelect()
            }
        }
        .onHover { hovering in
            onHover(hovering)
        }
    }
}

// MARK: - Board Color Indicator

struct BoardColorIndicator: View {
    let board: NoteBoard
    let isHovered: Bool
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color(NSColor.quaternaryLabelColor))
                .frame(width: 24, height: 24)
            
            // Color indicator
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            boardColor,
                            boardColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18, height: 18)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .shadow(
                    color: boardColor.opacity(0.3),
                    radius: isHovered ? 3 : 1,
                    x: 0,
                    y: 1
                )
            
            // Subtle pattern overlay for visual interest
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 18, height: 18)
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private var boardColor: Color {
        // Convert your board color to SwiftUI Color
        if let colorLabel = board.colorLabel {
            return Color(colorLabel) // Assuming you have a Color extension
        }
        return Color.blue // Default color
    }
}

// MARK: - Empty Boards View

struct EmptyBoardsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No boards available")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Create your first board to get started")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
    }
}

// MARK: - Board Context Menu

struct BoardContextMenu: View {
    let board: NoteBoard
    @ObservedObject var boardVM: NoteBoardViewModel
    
    var body: some View {
        Group {
            Button("Open Board") {
                boardVM.selectedBoard = board
              //  boardVM.loadNotes(for: board)
            }
            
            Button("Rename Board") {
                // Handle rename
            }
            
            Divider()
            
//            Button(board.isPinned ? "Unpin Board" : "Pin Board") {
//                // Handle pin toggle
//            }
            
            Button("Change Color") {
                // Handle color change
            }
            
            Divider()
            
            Button("Duplicate Board") {
                // Handle duplicate
            }
            
            Button("Export Board") {
                // Handle export
            }
            
            Divider()
            
            Button("Delete Board") {
                boardVM.deleteBoard(board)
            }
            .foregroundColor(.red)
        }
    }
}
