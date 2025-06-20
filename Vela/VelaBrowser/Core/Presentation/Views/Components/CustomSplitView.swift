//
//  CustomSplitView.swift
//  Vela
//
//  Created by damilola on 6/18/25.
//

import SwiftUI

// MARK: - Custom Split View
struct CustomSplitView<Sidebar: View, Detail: View>: View {
    let sidebar: Sidebar
    let detail: Detail
    
    @State private var sidebarWidth: CGFloat
    @State private var isResizing = false
    @State private var isDragging = false
    
    private let minSidebarWidth: CGFloat
    private let maxSidebarWidth: CGFloat
    private let dividerWidth: CGFloat = 1
    
    init(
        sidebarWidth: CGFloat = 250,
        minSidebarWidth: CGFloat = 200,
        maxSidebarWidth: CGFloat = 400,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.detail = detail()
        self._sidebarWidth = State(initialValue: sidebarWidth)
        self.minSidebarWidth = minSidebarWidth
        self.maxSidebarWidth = maxSidebarWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar
                sidebar
                    .frame(width: sidebarWidth)
                    .clipped()
                
                // Divider
                Divider()
                    .frame(width: dividerWidth)
                    .background(Color(NSColor.separatorColor))
                    .overlay(
                        // Invisible resize handle
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 8)
                            .contentShape(Rectangle())
                            .cursor(.resizeLeftRight)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.resizeLeftRight.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if !isDragging {
                                            isDragging = true
                                            isResizing = true
                                        }
                                        
                                        let newWidth = sidebarWidth + value.translation.width
                                        sidebarWidth = min(max(newWidth, minSidebarWidth),
                                                         min(maxSidebarWidth, geometry.size.width * 0.6))
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                        isResizing = false
                                    }
                            )
                    )
                
                // Detail view
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
        }
        .animation(.easeInOut(duration: 0.1), value: isResizing ? nil : sidebarWidth)
    }
}

// MARK: - Collapsible Split View
struct CollapsibleSplitView<Sidebar: View, Detail: View>: View {
    let sidebar: Sidebar
    let detail: Detail
    
    @State private var sidebarWidth: CGFloat
    @State private var isCollapsed = false
    @State private var isResizing = false
    @State private var isDragging = false
    
    private let defaultSidebarWidth: CGFloat
    private let minSidebarWidth: CGFloat
    private let maxSidebarWidth: CGFloat
    private let dividerWidth: CGFloat = 1
    
    init(
        sidebarWidth: CGFloat = 250,
        minSidebarWidth: CGFloat = 200,
        maxSidebarWidth: CGFloat = 400,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.detail = detail()
        self.defaultSidebarWidth = sidebarWidth
        self._sidebarWidth = State(initialValue: sidebarWidth)
        self.minSidebarWidth = minSidebarWidth
        self.maxSidebarWidth = maxSidebarWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar
                if !isCollapsed {
                    sidebar
                        .frame(width: sidebarWidth)
                        .clipped()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                
                // Detail view
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isCollapsed)
        .animation(.easeInOut(duration: 0.1), value: isResizing ? nil : sidebarWidth)
    }
    
    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isCollapsed.toggle()
        }
    }
}

// MARK: - Split View with Column Visibility
struct ConfigurableSplitView<Sidebar: View, Detail: View>: View {
    let sidebar: Sidebar
    let detail: Detail
    
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @State private var sidebarWidth: CGFloat
    @State private var isResizing = false
    @State private var isDragging = false
    
    private let defaultSidebarWidth: CGFloat
    private let minSidebarWidth: CGFloat
    private let maxSidebarWidth: CGFloat
    private let dividerWidth: CGFloat = 1
    
    init(
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        sidebarWidth: CGFloat = 250,
        minSidebarWidth: CGFloat = 200,
        maxSidebarWidth: CGFloat = 400,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self._columnVisibility = columnVisibility
        self.sidebar = sidebar()
        self.detail = detail()
        self.defaultSidebarWidth = sidebarWidth
        self._sidebarWidth = State(initialValue: sidebarWidth)
        self.minSidebarWidth = minSidebarWidth
        self.maxSidebarWidth = maxSidebarWidth
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            if columnVisibility != .detailOnly {
                sidebar
                    .frame(width: sidebarWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            // Detail view
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable(false) // Move this to HStack instead of the whole view
        .animation(.easeInOut(duration: 0.25), value: columnVisibility)
        .animation(.easeInOut(duration: 0.1), value: isResizing ? nil : sidebarWidth)
    }
}

// MARK: - Cursor Extension
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Usage Examples
struct CustomSplitViewExample: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        VStack {
            // Example 1: Basic Custom Split View
            CustomSplitView(
                sidebarWidth: 250,
                minSidebarWidth: 200,
                maxSidebarWidth: 400
            ) {
                // Sidebar content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sidebar")
                        .font(.headline)
                        .padding()
                    
                    List(0..<10) { index in
                        Text("Item \(index)")
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
            } detail: {
                // Detail content
                VStack {
                    Text("Detail View")
                        .font(.largeTitle)
                    Text("This is the main content area")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(height: 300)
            
            Divider()
            
            // Example 2: Collapsible Split View
            CollapsibleSplitView(
                sidebarWidth: 250,
                minSidebarWidth: 200,
                maxSidebarWidth: 400
            ) {
                // Sidebar content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collapsible Sidebar")
                        .font(.headline)
                        .padding()
                    
                    List(0..<5) { index in
                        Text("Item \(index)")
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
            } detail: {
                // Detail content
                VStack {
                    Text("Collapsible Detail View")
                        .font(.largeTitle)
                    Text("Click the sidebar button to toggle")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(height: 300)
            
            Divider()
            
            // Example 3: Configurable Split View (like NavigationSplitView)
            ConfigurableSplitView(
                columnVisibility: $columnVisibility,
                sidebarWidth: 250,
                minSidebarWidth: 200,
                maxSidebarWidth: 400
            ) {
                // Sidebar content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configurable Sidebar")
                        .font(.headline)
                        .padding()
                    
                    List(0..<5) { index in
                        Text("Item \(index)")
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
            } detail: {
                // Detail content
                VStack {
                    Text("Configurable Detail View")
                        .font(.largeTitle)
                    
                    HStack {
                        Button("Show All") {
                            columnVisibility = .all
                        }
                        Button("Detail Only") {
                            columnVisibility = .detailOnly
                        }
                        Button("Automatic") {
                            columnVisibility = .automatic
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(height: 300)
        }
        .padding()
    }
}
