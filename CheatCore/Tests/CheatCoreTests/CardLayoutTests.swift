import Foundation
import Testing

@testable import CheatCore

/// Plan: T-13. Covers: R-3.2.
@Test func columnsFollowWidthAndZoomAndCardsFillTheShortestColumn() {
    #expect(CardLayout.columns(width: 1366, zoom: 1.0) == 3)
    #expect(CardLayout.columns(width: 400, zoom: 1.0) == 1)
    #expect(CardLayout.columns(width: 0, zoom: 1.0) == 1)
    #expect(CardLayout.columns(width: 1366, zoom: 2.0) == 1)

    // Heights 5, 1, 1, 3, 2 into 2 columns: 5 | 1, 1 (=2) | +3 → 5 | 5 | tie → left gets 2.
    #expect(CardLayout.distribute(weights: [5, 1, 1, 3, 2], columns: 2) == [[0, 4], [1, 2, 3]])
    #expect(CardLayout.distribute(weights: [1, 1, 1], columns: 3) == [[0], [1], [2]])
    #expect(CardLayout.distribute(weights: [], columns: 2) == [[], []])
}

/// Plan: T-14. Covers: R-3.2.
@Test func topLevelSectionsAndResultSectionsAreTheCards() {
    let onlySubheadings = parse("intro\n## A\n- `a` one\n### A1\n- `b` two\n## B\n- `c` three")
    guard case .all(let sheet) = Matcher.results(for: "", in: onlySubheadings) else {
        Issue.record("expected the whole sheet")
        return
    }

    let cards = CardLayout.cards(for: .all(sheet))
    #expect(cards.map(\.title) == ["", "A", "B"])
    #expect(cards[0].weight == 2)  // untitled card: its one paragraph plus a header line
    #expect(cards[1].weight == 4)  // A's heading, its entry, A1's heading, its entry

    let noIntro = parse("# vi\n- `i` insert")
    #expect(CardLayout.cards(for: Matcher.results(for: "", in: noIntro)).map(\.title) == ["vi"])

    let filtered = CardLayout.cards(for: Matcher.results(for: "t", in: onlySubheadings))
    #expect(filtered.map(\.title) == ["A › A1", "B"])
    #expect(CardLayout.cards(for: .none("No matches")).isEmpty)
}
