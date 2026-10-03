import Foundation
import Testing

@testable import CheatCore

private let sheet = parse(
    """
    intro
    # vi
    - `i` insert
    ## Macros
    - `qa` record macro into a
    - `@a` replay macro
    ## Marks
    - `ma` set mark a
    # tmux
    - `C-b %` split
    - `C-b m` mark pane
    """)

/// The matching entries' keys, section by section.
private func keys(_ results: Results) -> [[String]] {
    guard case .matches(let sections) = results else { return [] }
    return sections.map { $0.entries.map { String($0.keys.characters) } }
}

/// The highlighted substrings of a text, in order.
private func highlights(_ text: AttributedString) -> [String] {
    text.runs[HighlightAttribute.self].compactMap { value, range in
        value == true ? String(text[range].characters) : nil
    }
}

/// Plan: T-11. Covers: R-3.1.
@Test(arguments: ["", "   "])
func anEmptyQueryShowsTheWholeSheet(query: String) {
    #expect(Matcher.results(for: query, in: sheet) == .all(sheet))
}

/// Plan: T-17. Covers: R-4.2.
@Test func everyTermMustOccurAtAWordStart() {
    // The objective's example: "vi ma" finds vi → Macros and nothing under tmux.
    let viMa = keys(Matcher.results(for: "vi ma", in: sheet))
    #expect(viMa.flatMap { $0 }.contains("qa"))
    #expect(!viMa.flatMap { $0 }.contains("C-b m"))

    #expect(
        keys(Matcher.results(for: "VI MACRO", in: sheet)) == keys(Matcher.results(for: "vi macro", in: sheet))
    )
    #expect(keys(Matcher.results(for: "acro", in: sheet)).isEmpty)  // inside a word
    #expect(keys(Matcher.results(for: "%", in: sheet)) == [["C-b %"]])  // non-letter: anywhere
    #expect(keys(Matcher.results(for: "tmux macro", in: sheet)).isEmpty)  // only one term matches
}

/// Plan: T-18. Covers: R-4.3.
@Test func onlyMatchingEntriesAppearUnderTheirFullHeadingPath() throws {
    guard case .matches(let sections) = Matcher.results(for: "replay", in: sheet) else {
        Issue.record("expected matches")
        return
    }

    let only = try #require(sections.first)
    #expect(sections.count == 1)
    #expect(only.path.map { String($0.characters) } == ["vi", "Macros"])
    #expect(only.entries.map { String($0.keys.characters) } == ["@a"])
}

/// Plan: T-19. Covers: R-4.4.
@Test func everyWordStartOccurrenceIsHighlighted() throws {
    let marks = parse("# vi\n## Marks\n- `ma` mark a, or remark mark b")
    guard case .matches(let sections) = Matcher.results(for: "ma", in: marks) else {
        Issue.record("expected matches")
        return
    }
    let section = try #require(sections.first)
    let entry = try #require(section.entries.first)

    #expect(highlights(section.path[1]) == ["Ma"])
    #expect(highlights(entry.keys) == ["ma"])
    // "remark" holds "ma" inside a word: not highlighted.
    #expect(highlights(entry.description) == ["ma", "ma"])
    #expect(String(entry.description.characters) == "mark a, or remark mark b")
}

/// Plan: T-20. Covers: R-4.5.
@Test func sectionsWithMoreTermsInTheirHeadingsComeFirst() {
    let ranked = parse(
        """
        # one
        - `a` set mark
        # two
        ## mark
        - `b` set mark
        # mark set
        - `c` one
        - `d` two
        """)

    // "mark set": `# mark set` holds both terms, `two → mark` one, `one` none.
    #expect(keys(Matcher.results(for: "mark set", in: ranked)) == [["c", "d"], ["b"], ["a"]])
    // Ties keep document order.
    #expect(keys(Matcher.results(for: "set", in: ranked)) == [["c", "d"], ["a"], ["b"]])
}

/// Plan: T-21. Covers: R-4.6.
@Test func aQueryMatchingNothingSaysSo() {
    #expect(Matcher.results(for: " zzz ", in: sheet) == .none("No matches for “zzz”"))
}

private let isDebugBuild: Bool = {
    #if DEBUG
        true
    #else
        false
    #endif
}()

@Suite struct Performance {
    /// Plan: T-22. Covers: R-4.7.
    @Test(.disabled(if: isDebugBuild, "timing is only meaningful in a release build"))
    func filteringTwoThousandEntriesTakesUnder50ms() {
        var markdown = ""
        for section in 0..<40 {
            markdown += "# tool\(section)\n"
            for sub in 0..<5 {
                markdown += "## group\(sub) mode\n"
                for entry in 0..<10 {
                    markdown += "- `C-\(entry)` move **cursor** to target \(section)-\(sub)-\(entry)\n"
                }
            }
        }
        let big = parse(markdown)
        let clock = ContinuousClock()
        let times = (0..<5).map { _ in clock.measure { _ = Matcher.results(for: "group mo", in: big) } }

        #expect(times.sorted()[2] < .milliseconds(50))
    }
}
