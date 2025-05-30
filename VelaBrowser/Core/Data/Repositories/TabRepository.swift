import Foundation

/// Basic in-memory implementation of a tab repository.
final class TabRepository {
    private(set) var tabs: [Tab] = []
    private var currentTabIndex: Int? = nil

    /// Create a new tab and make it the current one.
    func createTab(url: URL) -> Tab {
        let tab = Tab(id: UUID(), title: url.host ?? url.absoluteString, url: url)
        tabs.append(tab)
        currentTabIndex = tabs.count - 1
        return tab
    }

    /// Close the specified tab.
    func closeTab(_ tab: Tab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: index)
            if currentTabIndex == index { currentTabIndex = tabs.indices.last }
        }
    }

    /// Switch to the tab at the given index if it exists.
    func switchToTab(at index: Int) -> Tab? {
        guard tabs.indices.contains(index) else { return nil }
        currentTabIndex = index
        return tabs[index]
    }

    /// Returns the currently selected tab.
    var currentTab: Tab? {
        guard let index = currentTabIndex, tabs.indices.contains(index) else { return nil }
        return tabs[index]
    }
}
