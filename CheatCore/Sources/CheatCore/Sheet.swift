import Foundation

/// A heading and everything under it (R-2.1). The root section has level 0 and no title.
public struct SheetSection: Equatable, Sendable {
    public var title: AttributedString
    public var level: Int
    public var blocks: [Block] = []
    public var children: [SheetSection] = []

    public init(title: AttributedString, level: Int, blocks: [Block] = [], children: [SheetSection] = []) {
        self.title = title
        self.level = level
        self.blocks = blocks
        self.children = children
    }
}

/// One block of a section's own content, in document order.
public enum Block: Equatable, Sendable {
    case entry(Entry)
    case prose(AttributedString)
    case code(String)
}

/// One keyboard shortcut (R-2.2, R-2.3).
public struct Entry: Equatable, Sendable {
    public var keys: String
    public var description: AttributedString
}
