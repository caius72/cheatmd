import Testing

@testable import CheatCore

/// Plan: T-16. Covers: R-4.1.
@Test func typingEditsTheQuery() {
    #expect(KeyReducer.reduce("v", .character("i")) == ("vi", nil))
    #expect(KeyReducer.reduce("vi", .character(" ")) == ("vi ", nil))
    #expect(KeyReducer.reduce("vi", .backspace) == ("v", nil))
    #expect(KeyReducer.reduce("", .backspace) == ("", nil))
}

/// Plan: T-23. Covers: R-5.1, R-5.2.
@Test func escapeClearsThenReturnsFocusAndReturnAlwaysReturnsFocus() {
    #expect(KeyReducer.reduce("vi ma", .escape) == ("", nil))
    #expect(KeyReducer.reduce("", .escape) == ("", .returnFocus))
    #expect(KeyReducer.reduce("vi ma", .enter) == ("vi ma", .returnFocus))
    #expect(KeyReducer.reduce("", .enter) == ("", .returnFocus))
}
