import CheatCore
import SwiftUI

struct SheetView: View {
    let model: SheetModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let error = model.error {
                    Text(error).font(.title2).foregroundStyle(.red)
                } else {
                    switch model.results {
                    case .all(let sheet): SectionView(section: sheet)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(32)
        }
        .background(.background)
    }
}

/// A section's own blocks, then its subsections.
struct SectionView: View {
    let section: SheetSection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if section.level > 0 {
                Text(section.title)
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
            Text(text).foregroundStyle(.secondary)
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
            Text(description)
        }
    }
}
