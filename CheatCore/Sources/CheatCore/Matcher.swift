import Foundation

/// What to display for a query.
public enum Results: Equatable, Sendable {
    /// The whole sheet, unfiltered (R-3.1).
    case all(SheetSection)
    /// Matching entries grouped by section, best sections first (R-4.3, R-4.5).
    case matches([ResultSection])
    /// Nothing matched; the message to show (R-4.6).
    case none(String)
}

/// A section with matching entries. Matched text carries `HighlightAttribute` (R-4.4).
public struct ResultSection: Equatable, Sendable {
    /// Heading titles, outermost first.
    public var path: [AttributedString]
    public var entries: [ResultEntry]
}

public struct ResultEntry: Equatable, Sendable {
    public var keys: AttributedString
    public var description: AttributedString
}

/// Marks text that matched a query term.
public enum HighlightAttribute: AttributedStringKey {
    public typealias Value = Bool
    public static let name = "cheatmd.highlight"
}

public enum Matcher {
    public static func results(for query: String, in sheet: SheetSection) -> Results {
        let terms = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !terms.isEmpty else { return .all(sheet) }

        var scored: [(score: Int, section: ResultSection)] = []
        visit(sheet, path: []) { path, entries in
            let titles = path.map { String($0.characters) }
            let matching = entries.filter { entry in
                let fields = titles + [entry.keys, String(entry.description.characters)]
                return terms.allSatisfy { term in fields.contains { !occurrences(of: term, in: $0).isEmpty } }
            }
            guard !matching.isEmpty else { return }
            let score = terms.count { term in titles.contains { !occurrences(of: term, in: $0).isEmpty } }
            let section = ResultSection(
                path: path.map { highlight(terms, in: $0) },
                entries: matching.map {
                    ResultEntry(
                        keys: highlight(terms, in: AttributedString($0.keys)),
                        description: highlight(terms, in: $0.description))
                })
            scored.append((score, section))
        }
        guard !scored.isEmpty else { return .none("No matches for “\(terms.joined(separator: " "))”") }
        // A stable sort keeps document order among equal scores.
        return .matches(
            scored.enumerated().sorted { ($1.element.score, $0.offset) < ($0.element.score, $1.offset) }
                .map(\.element.section))
    }

    /// Calls `body` for each section, with its heading path, and its entries, in document order.
    private static func visit(
        _ section: SheetSection, path: [AttributedString], _ body: ([AttributedString], [Entry]) -> Void
    ) {
        let path = section.level == 0 ? path : path + [section.title]
        body(path, section.blocks.compactMap { if case .entry(let entry) = $0 { entry } else { nil } })
        for child in section.children { visit(child, path: path, body) }
    }

    /// Every place `term` occurs in `text`, ignoring case, at a word start (R-4.2). A term that
    /// starts with a character that is not a letter or digit may occur anywhere.
    static func occurrences(of term: String, in text: String) -> [Range<String.Index>] {
        guard let first = term.first else { return [] }
        let anywhere = !isWordCharacter(first)
        var found: [Range<String.Index>] = []
        var from = text.startIndex
        while from < text.endIndex,
            let range = text.range(of: term, options: .caseInsensitive, range: from..<text.endIndex)
        {
            let start = range.lowerBound
            if anywhere || start == text.startIndex || !isWordCharacter(text[text.index(before: start)]) {
                found.append(range)
            }
            from = text.index(after: start)
        }
        return found
    }

    private static func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }

    /// Marks every occurrence of every term with `HighlightAttribute` (R-4.4).
    private static func highlight(_ terms: [String], in text: AttributedString) -> AttributedString {
        var text = text
        let plain = String(text.characters)
        for term in terms {
            for range in occurrences(of: term, in: plain) {
                let lower = text.characters.index(
                    text.startIndex, offsetBy: plain.distance(from: plain.startIndex, to: range.lowerBound))
                let upper = text.characters.index(
                    lower, offsetBy: plain.distance(from: range.lowerBound, to: range.upperBound))
                text[lower..<upper][HighlightAttribute.self] = true
            }
        }
        return text
    }
}
