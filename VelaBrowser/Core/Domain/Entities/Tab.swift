import Foundation

/// Represents a single browser tab.
struct Tab: Identifiable {
    let id: UUID
    var title: String
    var url: URL
}
