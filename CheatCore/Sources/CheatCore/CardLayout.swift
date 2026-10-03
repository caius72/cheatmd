import Foundation

/// One card on screen: a top-level section, or a result section while filtering (R-3.2).
public enum Card: Equatable, Sendable {
    case section(SheetSection)
    case result(ResultSection)

    /// The card's heading as plain text; empty for the untitled first card.
    public var title: String {
        switch self {
        case .section(let section): String(section.title.characters)
        case .result(let result): result.path.map { String($0.characters) }.joined(separator: " › ")
        }
    }

    /// Estimated height in lines: the header line plus every block and subheading.
    public var weight: Int {
        switch self {
        case .section(let section): 1 + Self.contentWeight(section)
        case .result(let result): 1 + result.entries.count
        }
    }

    private static func contentWeight(_ section: SheetSection) -> Int {
        section.blocks.count + section.children.reduce(0) { $0 + 1 + contentWeight($1) }
    }
}

public enum CardLayout {
    /// Narrowest card at 100% zoom: 1366 pt holds 3 columns.
    static let minimumCardWidth = 420.0

    public static func cards(for results: Results) -> [Card] {
        switch results {
        case .all(let sheet):
            let intro =
                sheet.blocks.isEmpty
                ? [] : [Card.section(SheetSection(title: "", level: 0, blocks: sheet.blocks))]
            return intro + sheet.children.map(Card.section)
        case .matches(let sections): return sections.map(Card.result)
        case .none: return []
        }
    }

    public static func columns(width: Double, zoom: Double) -> Int {
        max(1, Int(width / (minimumCardWidth * zoom)))
    }

    /// Card indices per column: each card goes to the shortest column, ties to the leftmost.
    public static func distribute(weights: [Int], columns: Int) -> [[Int]] {
        var result = Array(repeating: [Int](), count: columns)
        var heights = Array(repeating: 0, count: columns)
        for (index, weight) in weights.enumerated() {
            guard let shortest = heights.indices.min(by: { heights[$0] < heights[$1] }) else { break }
            result[shortest].append(index)
            heights[shortest] += weight
        }
        return result
    }
}
