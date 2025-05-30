
import Foundation

struct Space: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var color: SpaceColor
    var tabs: [Tab] = []
    let createdAt: Date = Date()
    
    enum SpaceColor: String, CaseIterable {
        case blue, purple, pink, red, orange, yellow, green, gray
    }
}
