import Foundation
import Testing

@testable import CheatCore

/// Plan: T-6. Covers: R-2.1.
@Test func headingsNestUnderTheNearestLowerLevel() {
    let root = parse(
        """
        # A
        ## B
        ### C
        ## D
        # E
        ### F
        """)

    #expect(root.children.map(\.name) == ["A", "E"])
    let a = root.child("A")
    #expect(a?.children.map(\.name) == ["B", "D"])
    #expect(a?.child("B")?.children.map(\.name) == ["C"])
    #expect(a?.child("D")?.children.isEmpty == true)
    // A skipped level still nests under the nearest lower one.
    #expect(root.child("E")?.children.map(\.name) == ["F"])
    #expect(root.child("E")?.child("F")?.level == 3)
}

/// Plan: T-7. Covers: R-2.2.
@Test func listItemsStartingWithACodeSpanAreEntries() {
    let root = parse(
        """
        # vi
        - `qa` record macro into a
        - `@a` / `@@` replay macro
        - `x` – delete
        - `ZZ`
        - press `u` to undo
        - outer
          - `>>` indent line
        """)
    let vi = root.child("vi")
    let entries = vi?.entries ?? []

    #expect(entries.map(\.keys) == ["qa", "@a / @@", "x", "ZZ", ">>"])
    #expect(entries.map(\.text) == ["record macro into a", "replay macro", "delete", "", "indent line"])
    #expect(vi?.blocks.map(\.summary).contains("prose:• press u to undo") == true)
}

/// Plan: T-8. Covers: R-2.3.
@Test func tableBodyRowsAreEntries() {
    let root = parse(
        """
        # tmux

        | keys | action |
        |---|---|
        | `C-b %` | split \\| vertical |
        | `C-b z` | zoom pane |
        | `C-b ?` | |

        | keys | action | note |
        |---|---|---|
        | `C-b d` | detach | session keeps running |

        | only |
        |---|
        | `C-b ?` |
        """)
    let entries = root.child("tmux")?.entries ?? []

    #expect(entries.map(\.keys) == ["C-b %", "C-b z", "C-b ?", "C-b d"])
    #expect(entries.map(\.text) == ["split | vertical", "zoom pane", "", "detach session keeps running"])
}

/// Plan: T-9. Covers: R-2.4.
@Test func entriesBelongToTheInnermostSection() {
    let root = parse(
        """
        - `?` before any heading
        # vi
        - `i` insert
        ## Macros
        - `qa` record
        """)

    #expect(root.name.isEmpty)
    #expect(root.entries.map(\.keys) == ["?"])
    #expect(root.child("vi")?.entries.map(\.keys) == ["i"])
    #expect(root.child("vi")?.child("Macros")?.entries.map(\.keys) == ["qa"])
}

/// Plan: T-10. Covers: R-2.5.
@Test func otherBlocksAreKeptInOrderButAreNotEntries() {
    let root = parse(
        """
        # vi
        Modal editor.

        ```
        :help
        ```

        > Esc gets you out.

        - plain item
        - `i` insert

        ---

        1. first step
        """)

    #expect(
        root.child("vi")?.blocks.map(\.summary) == [
            "prose:Modal editor.", "code::help\n", "prose:Esc gets you out.", "prose:• plain item",
            "entry:i", "prose:⸻", "prose:1. first step",
        ])
}

/// Plan: T-12. Covers: R-3.3.
@Test func descriptionsKeepInlineStyles() throws {
    let root = parse("- `k` **bold** *italic* `code` [link](https://example.com)")
    let description = try #require(root.entries.first?.description)

    func intent(of word: String) -> InlinePresentationIntent? {
        guard let range = description.range(of: word) else { return nil }
        return description[range].inlinePresentationIntent
    }
    #expect(intent(of: "bold") == .stronglyEmphasized)
    #expect(intent(of: "italic") == .emphasized)
    #expect(intent(of: "code") == .code)
    let link = try #require(description.range(of: "link"))
    #expect(description[link].link == URL(string: "https://example.com"))
}
