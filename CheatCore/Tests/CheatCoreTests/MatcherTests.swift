import Foundation
import Testing

@testable import CheatCore

/// Plan: T-11. Covers: R-3.1.
@Test(arguments: ["", "   "])
func anEmptyQueryShowsTheWholeSheet(query: String) {
    let sheet = parse("intro\n# vi\n- `i` insert\n## Macros\n- `qa` record\n# tmux\n- `C-b d` detach")

    #expect(Matcher.results(for: query, in: sheet) == .all(sheet))
}
