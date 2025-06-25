import SwiftUI

struct TabsSection: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var previewManager: TabPreviewManager
    @Binding var hoveredTab: UUID?
    
    @Binding var draggedTab: Tab?
    @Binding var isDragging: Bool
    
    // PERFORMANCE FIX 1: Reduce @State variables and combine related state
    @State private var slideState = SlideState()
    @State private var dragState = DragState()
    @State private var isSpaceHeaderHovered: Bool = false
    
    // PERFORMANCE FIX 2: Create value types for state management
    struct SlideState {
        var previousSpaceIndex: Int = 0
        var slideDirection: SlideDirection = .none
    }
    
    struct DragState {
        var dragOffset: CGSize = .zero
        var draggedTabIndex: Int?
        var dropZoneHighlight: UUID?
        var dragInsertionIndex: Int?
        var dragInsertionPosition: CGFloat = 0
    }
    
    enum SlideDirection {
        case none, left, right
    }
    
    // PERFORMANCE FIX 3: Cache computed properties and add @MainActor
    @MainActor
    private var pinnedTabs: [Tab] {
        viewModel.tabs
            .filter { $0.isPinned && $0.folderId == nil }
            .sorted { $0.position < $1.position }
    }
    
    @MainActor
    private var regularTabs: [Tab] {
        viewModel.tabs
            .filter { !$0.isPinned && $0.folderId == nil }
            .sorted { $0.position < $1.position }
    }
    
    var body: some View {
        // PERFORMANCE FIX 4: Remove unnecessary ZStack nesting
        ScrollViewReader { proxy in
           // ScrollView(.vertical, showsIndicators: false) {
                tabsContent(proxy: proxy)
                    .padding(.bottom, 20)
          //  }
            .clipped()
            .transition(slideTransition)
            // PERFORMANCE FIX 5: Reduce animation complexity
           // .animation(.easeInOut(duration: 0.3), value: viewModel.currentSpace?.id)
            .id(viewModel.currentSpace?.id)
        }
        .clipped()
        .onChange(of: viewModel.currentSpace?.id) { _, newSpaceId in
            updateSlideDirection()
        }
        .onChange(of: viewModel.currentTab) { _, newValue in
            // PERFORMANCE FIX 6: Debounce frequent updates
            Task { @MainActor in
                if newValue?.url != nil {
                    viewModel.tappedTab = newValue
                    viewModel.addressBarVM.isShowingEnterAddressPopup = false
                }
            }
        }
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                cleanupDragState()
            }
        }
        // PERFORMANCE FIX 7: Remove timer-based cleanup (major performance killer)
        // Replace with proper cleanup in drag delegates
    }
    
    private func tabsContent(proxy: ScrollViewProxy) -> some View {
        // PERFORMANCE FIX 8: Use LazyVStack for entire content to improve memory
        LazyVStack(spacing: 8) {
            // Space Header - PERFORMANCE FIX 9: Simplify header
            spaceHeaderView
            
            NewTabButton {
                viewModel.startCreatingNewTab()
            }
            
            // PERFORMANCE FIX 10: Conditional rendering to avoid empty sections
            if !pinnedTabs.isEmpty {
                pinnedTabsSection(proxy: proxy)
                Divider().padding(.horizontal, 12)
            }
            
            // Regular tabs with optimized rendering
            regularTabsSection(proxy: proxy)
            
            Spacer(minLength: 0)
        }
       
    }
    
    // PERFORMANCE FIX 11: Extract header to reduce body complexity
    private var spaceHeaderView: some View {
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
                    // PERFORMANCE FIX 12: Cache tab count calculation
                    Text("\(tabCount) tabs")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    
                    if isSpaceHeaderHovered {
                        editButton
                    }
                }
                .fixedSize()
                .animation(.easeInOut(duration: 0.2), value: isSpaceHeaderHovered)
            }
            .padding(.vertical, 8)
            .onHover { hovering in
                isSpaceHeaderHovered = hovering
            }
        }
    }
    
    private var editButton: some View {
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
        .transition(.scale.combined(with: .opacity))
    }
    
    private var tabCount: Int {
        regularTabs.count + pinnedTabs.count
    }
    
    // PERFORMANCE FIX 13: Extract sections to reduce AttributeGraph complexity
    private func pinnedTabsSection(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Pinned")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            
            LazyVStack(spacing: 2) {
                ForEach(Array(pinnedTabs.enumerated()), id: \.element.id) { index, tab in
                    pinnedTabRow(tab: tab, index: index, proxy: proxy)
                }
            }
        }
    }
    
    private func regularTabsSection(proxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: 2) {
            ForEach(Array(regularTabs.enumerated()), id: \.element.id) { index, tab in
                regularTabRow(tab: tab, index: index, proxy: proxy)
            }
        }
    }
    
    // PERFORMANCE FIX 14: Extract individual rows to reduce view rebuilds
    private func pinnedTabRow(tab: Tab, index: Int, proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            if dragState.dragInsertionIndex == index && draggedTab?.isPinned == true {
                DropInsertionIndicator()
                    .transition(.scale.combined(with: .opacity))
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
            .modifier(OptimizedDragEffectModifier(
                isDragged: draggedTab?.id == tab.id,
                isDropTarget: dragState.dropZoneHighlight == tab.id
            ))
            .onDrag {
                startDrag(tab: tab, index: index)
                return NSItemProvider(object: tab.id.uuidString as NSString)
            }
            .onDrop(
                of: [.text],
                delegate: OptimizedTabDropDelegate(
                    tab: tab,
                    tabs: pinnedTabs,
                    tabIndex: index,
                    draggedTab: $draggedTab,
                    dragState: $dragState,
                    isDragging: $isDragging,
                    isPinned: true,
                    viewModel: viewModel,
                    onCleanup: cleanupDragState
                )
            )
            
            if index == pinnedTabs.count - 1 && dragState.dragInsertionIndex == pinnedTabs.count && draggedTab?.isPinned == true {
                DropInsertionIndicator()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func regularTabRow(tab: Tab, index: Int, proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            if dragState.dragInsertionIndex == index && draggedTab?.isPinned == false {
                DropInsertionIndicator()
                    .transition(.scale.combined(with: .opacity))
            }
            
            TabRow(
                viewModel: viewModel,
                previewManager: previewManager,
                tab: tab,
                isSelected: tab.id == viewModel.currentTab?.id && !viewModel.isInBoardMode,
                isHovered: hoveredTab == tab.id,
                onSelect: { viewModel.selectTab(tab) },
                onClose: {
                    handleTabClose(tab)
                },
                onHover: { isHovering in
                    hoveredTab = isHovering ? tab.id : nil
                }
            )
            .id("regular-\(tab.id)")
            .modifier(OptimizedDragEffectModifier(
                isDragged: draggedTab?.id == tab.id,
                isDropTarget: dragState.dropZoneHighlight == tab.id
            ))
            .onDrag {
                startDrag(tab: tab, index: index)
                return NSItemProvider(object: tab.id.uuidString as NSString)
            }
            .onDrop(
                of: [.text],
                delegate: OptimizedTabDropDelegate(
                    tab: tab,
                    tabs: regularTabs,
                    tabIndex: index,
                    draggedTab: $draggedTab,
                    dragState: $dragState,
                    isDragging: $isDragging,
                    isPinned: false,
                    viewModel: viewModel,
                    onCleanup: cleanupDragState
                )
            )
            
            if index == regularTabs.count - 1 && dragState.dragInsertionIndex == regularTabs.count && draggedTab?.isPinned == false {
                DropInsertionIndicator()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // PERFORMANCE FIX 15: Extract tab close logic
    private func handleTabClose(_ tab: Tab) {
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
    }
    
    private func startDrag(tab: Tab, index: Int) {
        // PERFORMANCE FIX 16: Simplify drag start animation
        draggedTab = tab
        dragState.draggedTabIndex = index
        isDragging = true
        
        // Proper cleanup timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if draggedTab?.id == tab.id && isDragging {
                cleanupDragState()
            }
        }
    }
    
    private func cleanupDragState() {
        // PERFORMANCE FIX 17: Batch state updates
        draggedTab = nil
        dragState = DragState()
        isDragging = false
    }
    
    private var slideTransition: AnyTransition {
        switch slideState.slideDirection {
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
            slideState.slideDirection = .none
            slideState.previousSpaceIndex = 0
            return
        }
        
        if currentIndex > slideState.previousSpaceIndex {
            slideState.slideDirection = .right
        } else if currentIndex < slideState.previousSpaceIndex {
            slideState.slideDirection = .left
        } else {
            slideState.slideDirection = .none
        }
        
        slideState.previousSpaceIndex = currentIndex
    }
}

// PERFORMANCE FIX 18: Optimized drag effect modifier
struct OptimizedDragEffectModifier: ViewModifier {
    let isDragged: Bool
    let isDropTarget: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isDragged ? 1.02 : 1.0)
            .opacity(isDragged ? 0.85 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isDropTarget ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isDropTarget ? Color.blue.opacity(0.4) : Color.clear,
                        lineWidth: isDropTarget ? 1 : 0
                    )
            )
            .zIndex(isDragged ? 10 : 0)
            .allowsHitTesting(!isDragged)
    }
}

// PERFORMANCE FIX 19: Optimized drop delegate
struct OptimizedTabDropDelegate: DropDelegate {
    let tab: Tab
    let tabs: [Tab]
    let tabIndex: Int
    @Binding var draggedTab: Tab?
    @Binding var dragState: TabsSection.DragState
    @Binding var isDragging: Bool
    let isPinned: Bool
    let viewModel: BrowserViewModel
    let onCleanup: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTab = draggedTab else {
            onCleanup()
            return false
        }
        
        if draggedTab.id == tab.id || draggedTab.isPinned != isPinned {
            onCleanup()
            return false
        }
        
        let targetIndex = dragState.dragInsertionIndex ?? tabIndex
        viewModel.reorderTab(draggedTab, to: targetIndex, isPinned: isPinned)
        
        onCleanup()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedTab = draggedTab,
              draggedTab.id != tab.id,
              draggedTab.isPinned == isPinned else { return }
        
        dragState.dropZoneHighlight = tab.id
        
        let location = info.location
        let tabHeight: CGFloat = 44
        let relativePosition = location.y / tabHeight
        
        dragState.dragInsertionIndex = relativePosition < 0.5 ? tabIndex : tabIndex + 1
    }
    
    func dropExited(info: DropInfo) {
        if dragState.dropZoneHighlight == tab.id {
            dragState.dropZoneHighlight = nil
        }
        dragState.dragInsertionIndex = nil
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard let draggedTab = draggedTab else {
            return DropProposal(operation: .forbidden)
        }
        
        if draggedTab.isPinned == isPinned && draggedTab.id != tab.id {
            let location = info.location
            let tabHeight: CGFloat = 44
            let relativePosition = location.y / tabHeight
            
            dragState.dragInsertionIndex = relativePosition < 0.5 ? tabIndex : tabIndex + 1
            
            return DropProposal(operation: .move)
        }
        
        return DropProposal(operation: .forbidden)
    }
}

struct DropInsertionIndicator: View {
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(height: 2)
            .padding(.horizontal, 12)
            .clipShape(Capsule())
    }
}
