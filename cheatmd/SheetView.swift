import CheatCore
import SwiftUI

struct SheetView: View {
    let model: SheetModel

    var body: some View {
        let fonts = Fonts(scale: model.zoom.scale)
        VStack(alignment: .leading, spacing: 0) {
            QueryBar(query: model.query)
            if let error = model.error {
                Text(error).font(fonts.title).foregroundStyle(.red).padding(Fonts.margin)
            } else if case .none(let message) = model.results {
                Text(message).font(fonts.title).foregroundStyle(.secondary).padding(Fonts.margin)
            } else {
                CardGrid(cards: CardLayout.cards(for: model.results), scale: model.zoom.scale)
            }
            Spacer(minLength: 0)
        }
        .environment(\.fonts, fonts)
        .font(fonts.body)
        .background(.background)
    }
}

/// Cards flowing into columns, each card into the shortest column (R-3.2).
struct CardGrid: View {
    let cards: [Card]
    let scale: Double

    var body: some View {
        GeometryReader { geometry in
            let columns = CardLayout.columns(width: geometry.size.width - 2 * Fonts.margin, zoom: scale)
            let plan = CardLayout.distribute(weights: cards.map(\.weight), columns: columns)
            ScrollView {
                HStack(alignment: .top, spacing: Fonts.gap) {
                    ForEach(plan.indices, id: \.self) { column in
                        VStack(spacing: Fonts.gap) {
                            ForEach(plan[column], id: \.self) { CardView(card: cards[$0]) }
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
                .padding(Fonts.margin)
            }
        }
    }
}

struct CardView: View {
    let card: Card
    @Environment(\.fonts) private var fonts

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch card {
            case .section(let section):
                if !section.title.characters.isEmpty {
                    Text(section.title.inertLinks).font(fonts.title)
                }
                SectionBody(section: section)
            case .result(let result):
                Text(
                    result.path.map(\.marked).reduce(into: AttributedString()) { line, title in
                        line += line.characters.isEmpty ? title : "  ›  " + title
                    }
                )
                .font(fonts.title)
                ForEach(Array(result.entries.enumerated()), id: \.offset) { _, entry in
                    EntryRow(keys: entry.keys.marked, description: entry.description.marked)
                }
            }
        }
        .padding(Fonts.gap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12))
    }
}

/// The query, always visible (R-4.1).
struct QueryBar: View {
    let query: String
    @Environment(\.fonts) private var fonts

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
            Text(query.isEmpty ? "Type to filter" : query)
                .foregroundStyle(query.isEmpty ? .tertiary : .primary)
        }
        .font(fonts.query)
        .padding(.horizontal, Fonts.margin)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }
}

/// A section's own blocks, then its subsections with their headings.
struct SectionBody: View {
    let section: SheetSection
    @Environment(\.fonts) private var fonts

    var body: some View {
        ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
            BlockView(block: block)
        }
        ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
            Text(child.title.inertLinks).font(fonts.heading).padding(.top, 6)
            AnyView(SectionBody(section: child))
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
            Text(text).monospaced().foregroundStyle(.secondary)
        }
    }
}

/// Keys in a monospaced, tinted box, then the description (R-3.4).
struct EntryRow: View {
    let keys: AttributedString
    let description: AttributedString
    @Environment(\.fonts) private var fonts

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(keys)
                .monospaced()
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.tint.opacity(0.15), in: .rect(cornerRadius: 5))
                .frame(minWidth: fonts.keysWidth, alignment: .leading)
            Text(description.inertLinks)
        }
    }
}

/// Font sizes for the zoom level (R-3.6), sized to read at arm's length on a 13" iPad.
struct Fonts {
    static let margin = 24.0
    static let gap = 16.0
    let scale: Double

    var body: Font { .system(size: 15 * scale) }
    var title: Font { .system(size: 22 * scale, weight: .bold) }
    var heading: Font { .system(size: 17 * scale, weight: .semibold) }
    var query: Font { .system(size: 20 * scale).monospaced() }
    var keysWidth: Double { 96 * scale }
}

extension EnvironmentValues {
    @Entry var fonts = Fonts(scale: 1)
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

#Preview("whole sheet", traits: .fixedLayout(width: 1366, height: 1024)) {
    SheetView(model: SheetModel())
}

#Preview("vi ma", traits: .fixedLayout(width: 1366, height: 1024)) {
    let model = SheetModel()
    model.query = "vi ma"
    return SheetView(model: model)
}
