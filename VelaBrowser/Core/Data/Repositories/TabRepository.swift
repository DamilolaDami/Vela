import Foundation

/// Simple in-memory repository storing tabs.
final class TabRepository {
    private(set) var tabs: [Tab] = []
    private var currentIndex: Int?

    /// Creates a new tab and selects it.
    @discardableResult
    func createTab(url: URL) -> Tab {
        let tab = Tab(url: url)
        tabs.append(tab)
        currentIndex = tabs.count - 1
        return tab
    }

    /// Close the given tab and adjust the current index if needed.
    func close(tab: Tab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tabs.remove(at: index)
        if let current = currentIndex {
            if current == index {
                currentIndex = tabs.indices.last
            } else if current > index {
                currentIndex = current - 1
            }
        }
    }

    /// Switch to the tab at a specific index.
    func switchToTab(at index: Int) -> Tab? {
        guard tabs.indices.contains(index) else { return nil }
        currentIndex = index
        return tabs[index]
    }

    /// Currently selected tab if any.
    var currentTab: Tab? {
        guard let index = currentIndex, tabs.indices.contains(index) else { return nil }
        return tabs[index]
    }
}
