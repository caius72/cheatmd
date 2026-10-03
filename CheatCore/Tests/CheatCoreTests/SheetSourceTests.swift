import Foundation
import Testing

@testable import CheatCore

/// Plan: T-1. Covers: R-1.1.
@Test func sheetPathIsUnderDotConfigInHome() {
    let source = SheetSource(home: URL(filePath: "/h"))
    #expect(source.url.path(percentEncoded: false) == "/h/.config/cheatmd/cheatmd.md")
}
