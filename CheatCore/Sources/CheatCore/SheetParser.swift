import Foundation

/// Markdown → section tree, using Foundation's parser and its presentation intents.
public enum SheetParser {
    public static func parse(_ markdown: String) -> SheetSection {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible)
        let text = (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
        var builder = Builder()
        for (intent, range) in text.runs[\.presentationIntent] {
            builder.add(AttributedString(text[range]), intent: intent?.components ?? [])
        }
        return builder.finish()
    }
}

private struct Builder {
    /// Open sections, outermost first; `stack[0]` is the root.
    var stack = [SheetSection(title: "", level: 0)]
    /// List items whose first paragraph has been seen: only that one can be an entry.
    var seenListItems = Set<Int>()
    /// The table row being collected: its identity, whether it is a header, and its cells.
    var row: (id: Int, isHeader: Bool, columns: Int, cells: [AttributedString])?

    mutating func add(_ text: AttributedString, intent: [PresentationIntent.IntentType]) {
        let kinds = intent.map(\.kind)
        if let cell = kinds.firstIndex(where: { if case .tableCell = $0 { true } else { false } }),
            case .table(let columns) = kinds[cell + 2]
        {
            addCell(text, rowIntent: intent[cell + 1], columns: columns.count)
            return
        }
        flushRow()
        switch kinds.first {
        case .header(let level):
            open(SheetSection(title: text, level: level))
        case .codeBlock:
            append(.code(String(text.characters)))
        case .paragraph:
            addParagraph(text, kinds: kinds, intent: intent)
        default:
            append(.prose(text))
        }
    }

    mutating func addParagraph(
        _ text: AttributedString, kinds: [PresentationIntent.Kind], intent: [PresentationIntent.IntentType]
    ) {
        guard kinds.count > 1, case .listItem(let ordinal) = kinds[1] else {
            append(.prose(text))
            return
        }
        let isFirst = seenListItems.insert(intent[1].identity).inserted
        if isFirst, let entry = listEntry(text) {
            append(.entry(entry))
            return
        }
        let ordered = kinds.count > 2 && kinds[2] == .orderedList
        append(.prose(AttributedString(ordered ? "\(ordinal). " : "• ") + text))
    }

    mutating func addCell(
        _ text: AttributedString, rowIntent: PresentationIntent.IntentType, columns: Int
    ) {
        if row?.id != rowIntent.identity {
            flushRow()
            row = (rowIntent.identity, rowIntent.kind == .tableHeaderRow, columns, [])
        }
        row?.cells.append(text)
    }

    mutating func flushRow() {
        guard let row else { return }
        self.row = nil
        if row.isHeader { return }
        guard row.columns >= 2, let keys = row.cells.first else {
            append(.prose(row.cells.reduce(AttributedString(), +)))
            return
        }
        let rest = row.cells.dropFirst().filter { !$0.characters.isEmpty }
        let description = rest.dropFirst().reduce(rest.first ?? AttributedString()) { $0 + " " + $1 }
        append(.entry(Entry(keys: String(keys.characters), description: description)))
    }

    mutating func open(_ section: SheetSection) {
        while stack.count > 1, let top = stack.last, top.level >= section.level { close() }
        stack.append(section)
    }

    mutating func close() {
        let done = stack.removeLast()
        stack[stack.count - 1].children.append(done)
    }

    mutating func append(_ block: Block) {
        stack[stack.count - 1].blocks.append(block)
    }

    mutating func finish() -> SheetSection {
        flushRow()
        while stack.count > 1 { close() }
        return stack[0]
    }
}

/// Splits a list item's first paragraph into keys and description (R-2.2), or nil when it
/// does not start with a code span.
private func listEntry(_ text: AttributedString) -> Entry? {
    var keys = ""
    var pending = ""
    var descriptionStart: AttributedString.Index?
    for run in text.runs {
        let chunk = String(text[run.range].characters)
        if run.inlinePresentationIntent?.contains(.code) == true {
            keys += pending + chunk
            pending = ""
        } else if !keys.isEmpty, chunk.allSatisfy({ !$0.isLetter && !$0.isNumber }) {
            pending += chunk
        } else {
            descriptionStart = run.range.lowerBound
            break
        }
    }
    guard !keys.isEmpty else { return nil }
    let description = descriptionStart.map { AttributedString(pending) + AttributedString(text[$0...]) }
    return Entry(keys: keys, description: trimmed(description ?? AttributedString()))
}

/// Trims leading whitespace and one leading dash or colon (R-2.2); markdown already drops trailing
/// whitespace.
private func trimmed(_ text: AttributedString) -> AttributedString {
    var text = text
    func dropLeadingSpace() {
        while let first = text.characters.first, first.isWhitespace { text.characters.removeFirst() }
    }
    dropLeadingSpace()
    if let first = text.characters.first, "-–—:".contains(first) {
        text.characters.removeFirst()
        dropLeadingSpace()
    }
    return text
}
