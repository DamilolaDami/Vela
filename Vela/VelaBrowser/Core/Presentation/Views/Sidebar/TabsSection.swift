import SwiftUI

struct TabsSection: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @Binding var hoveredTab: UUID?
    
    @Binding var draggedTab: Tab? // Add this binding
    @Binding var isDragging: Bool
    
    // Track the previous space to determine slide direction
    @State private var previousSpaceIndex: Int = 0
    @State private var slideDirection: SlideDirection = .none
    @State private var isSpaceHeaderHovered: Bool = false
    
    // Enhanced drag and drop state
    @State private var dragOffset: CGSize = .zero
    @State private var draggedTabIndex: Int?
    @State private var dropZoneHighlight: UUID?
    @State private var dragInsertionIndex: Int?
    @State private var dragInsertionPosition: CGFloat = 0
    
    enum SlideDirection {
        case none, left, right
    }
    
    // Computed properties to separate pinned and regular tabs, excluding folder-assigned tabs
    private var pinnedTabs: [Tab] {
        viewModel.tabs
            .filter { $0.isPinned && $0.folderId == nil }
            .sorted { $0.position < $1.position }
    }
    
    private var regularTabs: [Tab] {
        viewModel.tabs
            .filter { !$0.isPinned && $0.folderId == nil }
            .sorted { $0.position < $1.position }
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    tabsContent(proxy: proxy)
                        .padding(.bottom, 20) // Extra padding to prevent clipping
                }
                .clipped()
                .transition(slideTransition)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.currentSpace?.id)
                .id(viewModel.currentSpace?.id)
            }
        }
        .clipped()
        .onChange(of: viewModel.currentSpace?.id) { _, newSpaceId in
            updateSlideDirection()
        }
        .onChange(of: viewModel.currentTab) { _, newValue in
            if newValue?.url != nil {
                viewModel.tappedTab = newValue
                viewModel.addressBarVM.isShowingEnterAddressPopup = false
            }
        }
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                // Clean up drag state when dragging ends
                cleanupDragState()
            }
        }
        // Add a timer-based cleanup as a fallback
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            // If we have a dragged tab but no active drag operation, clean up
            if draggedTab != nil && !isDragging {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if draggedTab != nil && !isDragging {
                        cleanupDragState()
                    }
                }
            }
        }
    }
    
    private func tabsContent(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 8) {
            // Space Header with Edit Button
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 4) {
                        viewModel.currentSpace?.displayIcon
                            .foregroundStyle(viewModel.currentSpace?.displayColor ?? .blue)
                        Text("\(viewModel.currentSpace?.name ?? "Personal Space")")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("\(regularTabs.count + pinnedTabs.count) tabs")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                        
                        if isSpaceHeaderHovered {
                            Button(action: {
                                // Handle edit action here
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .fill(Color(NSColor.controlBackgroundColor))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                            .onHover { hovering in
                                if hovering {
                                    isSpaceHeaderHovered = true
                                }
                            }
                        }
                    }
                    .fixedSize()
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSpaceHeaderHovered)
                }
                .padding(.vertical, 8)
                .onHover { hovering in
                    isSpaceHeaderHovered = hovering
                }
            }
            
            NewTabButton {
                viewModel.startCreatingNewTab()
            }
            
            // Pinned Tabs Section (if any exist)
            if !pinnedTabs.isEmpty {
                VStack(spacing: 4) {
                    HStack {
                        Text("Pinned")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    
                    // Pinned tabs list with enhanced drag and drop
                    LazyVStack(spacing: 2) {
                        ForEach(Array(pinnedTabs.enumerated()), id: \.element.id) { index, tab in
                            VStack(spacing: 0) {
                                // Drop insertion indicator for pinned tabs
                                if dragInsertionIndex == index && draggedTab?.isPinned == true {
                                    DropInsertionIndicator()
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.5, anchor: .center).combined(with: .opacity),
                                            removal: .scale(scale: 0.5, anchor: .center).combined(with: .opacity)
                                        ))
                                }
                                
                                PinnedTabRow(
                                    viewModel: viewModel,
                                    tab: tab,
                                    isSelected: tab.id == viewModel.currentTab?.id && !viewModel.isInBoardMode,
                                    isHovered: hoveredTab == tab.id,
                                    onSelect: { viewModel.selectTab(tab) },
                                    onHover: { isHovering in
                                        hoveredTab = isHovering ? tab.id : nil
                                    }
                                )
                                .id("pinned-\(tab.id)")
                                .modifier(EnhancedDragEffectModifier(
                                    isDragged: draggedTab?.id == tab.id,
                                    isDropTarget: dropZoneHighlight == tab.id,
                                    isAboveDropTarget: dragInsertionIndex == index
                                ))

                                .onDrag {
                                    startDrag(tab: tab, index: index)
                                    return NSItemProvider(object: tab.id.uuidString as NSString)
                                }
                                .onDrop(
                                    of: [.text],
                                    delegate: EnhancedTabDropDelegate(
                                        tab: tab,
                                        tabs: pinnedTabs,
                                        tabIndex: index,
                                        draggedTab: $draggedTab,
                                        draggedTabIndex: $draggedTabIndex,
                                        dropZoneHighlight: $dropZoneHighlight,
                                        dragInsertionIndex: $dragInsertionIndex,
                                        isDragging: $isDragging,
                                        isPinned: true,
                                        viewModel: viewModel,
                                        scrollProxy: proxy,
                                        onCleanup: cleanupDragState
                                    )
                                )
                                
                                // Drop insertion indicator at the end
                                if index == pinnedTabs.count - 1 && dragInsertionIndex == pinnedTabs.count && draggedTab?.isPinned == true {
                                    DropInsertionIndicator()
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.5, anchor: .center).combined(with: .opacity),
                                            removal: .scale(scale: 0.5, anchor: .center).combined(with: .opacity)
                                        ))
                                }
                            }
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, 12)
            }
            
            // Regular Tabs Section with enhanced drag and drop
            LazyVStack(spacing: 2) {
                ForEach(Array(regularTabs.enumerated()), id: \.element.id) { index, tab in
                    VStack(spacing: 0) {
                        // Drop insertion indicator for regular tabs
                        if dragInsertionIndex == index && draggedTab?.isPinned == false {
                            DropInsertionIndicator()
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.5, anchor: .center).combined(with: .opacity),
                                    removal: .scale(scale: 0.5, anchor: .center).combined(with: .opacity)
                                ))
                        }
                        
                        TabRow(
                            viewModel: viewModel,
                            previewManager: previewManager,
                            tab: tab,
                            isSelected: tab.id == viewModel.currentTab?.id && !viewModel.isInBoardMode,
                            isHovered: hoveredTab == tab.id,
                            onSelect: { viewModel.selectTab(tab) },
                            onClose: {
                                if tab.folderId != nil {
                                    if let folder = viewModel.folders.first(where: { $0.id == tab.folderId }) {
                                        viewModel.removeTab(tab, from: folder)
                                        NotificationService.shared.show(type: .success, title: "Tab removed from folder")
                                    } else {
                                        print("Error: Folder with ID \(tab.folderId!) not found")
                                        viewModel.closeTab(tab)
                                    }
                                } else {
                                    viewModel.closeAndDeleteTab(tab)
                                }
                                },
                            onHover: { isHovering in
                                hoveredTab = isHovering ? tab.id : nil
                            }
                        )
                        .id("regular-\(tab.id)")
                        .modifier(EnhancedDragEffectModifier(
                            isDragged: draggedTab?.id == tab.id,
                            isDropTarget: dropZoneHighlight == tab.id,
                            isAboveDropTarget: dragInsertionIndex == index
                        ))

                        .onDrag {
                            startDrag(tab: tab, index: index)
                            return NSItemProvider(object: tab.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: EnhancedTabDropDelegate(
                                tab: tab,
                                tabs: regularTabs,
                                tabIndex: index,
                                draggedTab: $draggedTab,
                                draggedTabIndex: $draggedTabIndex,
                                dropZoneHighlight: $dropZoneHighlight,
                                dragInsertionIndex: $dragInsertionIndex,
                                isDragging: $isDragging,
                                isPinned: false,
                                viewModel: viewModel,
                                scrollProxy: proxy,
                                onCleanup: cleanupDragState
                            )
                        )
                        
                        // Drop insertion indicator at the end
                        if index == regularTabs.count - 1 && dragInsertionIndex == regularTabs.count && draggedTab?.isPinned == false {
                            DropInsertionIndicator()
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.5, anchor: .center).combined(with: .opacity),
                                    removal: .scale(scale: 0.5, anchor: .center).combined(with: .opacity)
                                ))
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 0) // Remove extra horizontal padding to prevent clipping
    }
    
    private func startDrag(tab: Tab, index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            draggedTab = tab
            draggedTabIndex = index
            isDragging = true
        }
        
        // Set a fallback timer to clean up if drag doesn't complete properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if draggedTab?.id == tab.id && isDragging {
                cleanupDragState()
            }
        }
    }
    
    // NEW: Centralized cleanup function
    private func cleanupDragState() {
        withAnimation(.easeOut(duration: 0.2)) {
            draggedTab = nil
            draggedTabIndex = nil
            dropZoneHighlight = nil
            dragInsertionIndex = nil
            isDragging = false
            dragOffset = .zero
        }
    }
    
    private var slideTransition: AnyTransition {
        switch slideDirection {
        case .left:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .right:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .none:
            return .opacity
        }
    }
    
    private func updateSlideDirection() {
        let spaces = viewModel.spaces
        guard let currentSpace = viewModel.currentSpace,
              let currentIndex = spaces.firstIndex(where: { $0.id == currentSpace.id }) else {
            slideDirection = .none
            previousSpaceIndex = 0
            return
        }
        
        // Determine direction based on index comparison
        if currentIndex > previousSpaceIndex {
            slideDirection = .right // Forward animation
        } else if currentIndex < previousSpaceIndex {
            slideDirection = .left // Backward animation
        } else {
            slideDirection = .none // No change in space
        }
        
        // Update previous index after determining direction
        previousSpaceIndex = currentIndex
    }
}

// MARK: - Drop Insertion Indicator
struct DropInsertionIndicator: View {
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(height: 2)
            .padding(.horizontal, 12)
            .clipShape(Capsule())
    }
}

// MARK: - Enhanced TabDropDelegate
struct EnhancedTabDropDelegate: DropDelegate {
    let tab: Tab
    let tabs: [Tab]
    let tabIndex: Int
    @Binding var draggedTab: Tab?
    @Binding var draggedTabIndex: Int?
    @Binding var dropZoneHighlight: UUID?
    @Binding var dragInsertionIndex: Int?
    @Binding var isDragging: Bool
    let isPinned: Bool
    let viewModel: BrowserViewModel
    let scrollProxy: ScrollViewProxy
    let onCleanup: () -> Void // NEW: Cleanup callback
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTab = draggedTab,
              let draggedIndex = draggedTabIndex else {
            onCleanup()
            return false
        }
        
        // Don't drop on the same tab
        if draggedTab.id == tab.id {
            onCleanup()
            return false
        }
        
        // Only allow reordering within the same section (pinned/regular)
        if draggedTab.isPinned != isPinned {
            onCleanup()
            return false
        }
        
        // Determine the target index based on insertion point
        let targetIndex = dragInsertionIndex ?? tabIndex
        
        // Perform the reorder with animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            viewModel.reorderTab(draggedTab, to: targetIndex, isPinned: isPinned)
        }
        
        onCleanup()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedTab = draggedTab,
              draggedTab.id != tab.id,
              draggedTab.isPinned == isPinned else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            dropZoneHighlight = tab.id
            
            // Determine insertion index based on drop location
            let location = info.location
            let tabHeight: CGFloat = 44 // Approximate tab height
            let relativePosition = location.y / tabHeight
            
            if relativePosition < 0.5 {
                dragInsertionIndex = tabIndex
            } else {
                dragInsertionIndex = tabIndex + 1
            }
        }
        
        // Auto-scroll to keep the drop target visible
        let scrollId = isPinned ? "pinned-\(tab.id)" : "regular-\(tab.id)"
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy.scrollTo(scrollId, anchor: .center)
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.easeOut(duration: 0.15)) {
            if dropZoneHighlight == tab.id {
                dropZoneHighlight = nil
            }
            dragInsertionIndex = nil
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard let draggedTab = draggedTab else {
            return DropProposal(operation: .forbidden)
        }
        
        // Allow drop only within the same section
        if draggedTab.isPinned == isPinned && draggedTab.id != tab.id {
            // Update insertion index based on mouse position
            let location = info.location
            let tabHeight: CGFloat = 44
            let relativePosition = location.y / tabHeight
            
            withAnimation(.easeInOut(duration: 0.1)) {
                if relativePosition < 0.5 {
                    dragInsertionIndex = tabIndex
                } else {
                    dragInsertionIndex = tabIndex + 1
                }
            }
            
            return DropProposal(operation: .move)
        }
        
        return DropProposal(operation: .forbidden)
    }
}

// MARK: - Enhanced Drag Effect Modifier
struct EnhancedDragEffectModifier: ViewModifier {
    let isDragged: Bool
    let isDropTarget: Bool
    let isAboveDropTarget: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isDragged ? 1.02 : 1.0)
            .opacity(isDragged ? 0.85 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isDropTarget ? Color.blue.opacity(0.1) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isDropTarget)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isDropTarget ? Color.blue.opacity(0.4) : Color.clear,
                        lineWidth: isDropTarget ? 1 : 0
                    )
                    .animation(.easeInOut(duration: 0.2), value: isDropTarget)
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDragged)
            .zIndex(isDragged ? 10 : 0)
            .allowsHitTesting(!isDragged) // Prevent interaction with dragged item
    }
}
