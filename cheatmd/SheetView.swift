import CheatCore
import SwiftUI

struct SheetView: View {
    let model: SheetModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QueryBar(query: model.query)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let error = model.error {
                        Text(error).font(.title2).foregroundStyle(.red)
                    } else {
                        switch model.results {
                        case .all(let sheet): SectionView(section: sheet)
                        case .matches(let sections):
                            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                                ResultSectionView(section: section)
                            }
                        case .none(let message): Text(message).font(.title2).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(32)
            }
        }
        .background(.background)
    }
}

/// The query, always visible (R-4.1).
struct QueryBar: View {
    let query: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
            Text(query.isEmpty ? "Type to filter" : query)
                .foregroundStyle(query.isEmpty ? .tertiary : .primary)
        }
        .font(.title2.monospaced())
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }
}

/// A matching section: its heading path, then its matching entries (R-4.3).
struct ResultSectionView: View {
    let section: ResultSection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                section.path.map(\.marked).reduce(into: AttributedString()) { line, title in
                    line += line.characters.isEmpty ? title : "  ›  " + title
                }
            )
            .font(.title2.bold())
            .padding(.top, 8)
            ForEach(Array(section.entries.enumerated()), id: \.offset) { _, entry in
                EntryRow(keys: entry.keys.marked, description: entry.description.marked)
            }
        }
    }
}

/// A section's own blocks, then its subsections.
struct SectionView: View {
    let section: SheetSection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if section.level > 0 {
                Text(section.title.inertLinks)
                    .font(
                        section.level == 1
                            ? .largeTitle.bold() : section.level == 2 ? .title2.bold() : .headline
                    )
                    .padding(.top, section.level == 1 ? 16 : 8)
            }
            ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                BlockView(block: block)
            }
            ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                SectionView(section: child)
            }
        }
    }
}

struct BlockView: View {
    let block: Block

    var body: some View {
        switch block {
        case .entry(let entry):
            EntryRow(keys: AttributedString(entry.keys), description: entry.description)
        case .prose(let text):
            Text(text.inertLinks).foregroundStyle(.secondary)
        case .code(let text):
            Text(text).font(.body.monospaced()).foregroundStyle(.secondary)
        }
    }
}

/// Keys in a monospaced, tinted box, then the description (R-3.4).
struct EntryRow: View {
    let keys: AttributedString
    let description: AttributedString

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(keys)
                .font(.body.monospaced().weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.tint.opacity(0.15), in: .rect(cornerRadius: 5))
                .frame(minWidth: 110, alignment: .leading)
            Text(description.inertLinks)
        }
    }
}

extension AttributedString {
    /// Matched text gets a highlight background (R-4.4).
    var marked: AttributedString {
        transformingAttributes(\.highlight) { highlight in
            if highlight.value == true {
                highlight.replace(with: \.backgroundColor, value: Color.yellow.opacity(0.45))
            }
        }
    }

    /// Link text keeps a link style but cannot be clicked: the sheet is display-only, and a
    /// clickable link could open any URL scheme.
    var inertLinks: AttributedString {
        transformingAttributes(\.link) { link in
            if link.value != nil { link.replace(with: \.underlineStyle, value: Text.LineStyle.single) }
        }
    }
}

extension AttributeScopes {
    struct CheatAttributes: AttributeScope {
        let highlight: HighlightAttribute
        let swiftUI: SwiftUIAttributes
    }

    var cheat: CheatAttributes.Type { CheatAttributes.self }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.CheatAttributes, T>) -> T
    {
        self[T.self]
    }
}

#Preview("vi ma", traits: .fixedLayout(width: 1366, height: 1024)) {
    let model = SheetModel()
    model.query = "vi ma"
    return SheetView(model: model)
}
