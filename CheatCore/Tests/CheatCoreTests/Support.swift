import Foundation

@testable import CheatCore

/// A unique temporary folder, removed when the value goes away.
final class TempDir {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appending(path: "cheatmd-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit { try? FileManager.default.removeItem(at: url) }
}

extension SheetSection {
    /// Plain title text, for compact assertions.
    var name: String { String(title.characters) }

    /// The first child with the given title.
    func child(_ name: String) -> SheetSection? { children.first { $0.name == name } }

    var entries: [Entry] {
        blocks.compactMap {
            if case .entry(let entry) = $0 { entry } else { nil }
        }
    }
}

extension Entry {
    var text: String { String(description.characters) }
}

extension Block {
    /// A one-line summary: `entry:<keys>`, `prose:<text>` or `code:<text>`.
    var summary: String {
        switch self {
        case .entry(let entry): "entry:\(entry.keys)"
        case .prose(let text): "prose:\(String(text.characters))"
        case .code(let text): "code:\(text)"
        }
    }
}

func parse(_ markdown: String) -> SheetSection { SheetParser.parse(markdown) }
