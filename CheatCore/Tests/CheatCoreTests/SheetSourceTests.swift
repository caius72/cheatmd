import Foundation
import Testing

@testable import CheatCore

/// Plan: T-1. Covers: R-1.1.
@Test func sheetPathIsUnderDotConfigInHome() {
    let source = SheetSource(home: URL(filePath: "/h"))
    #expect(source.url.path(percentEncoded: false) == "/h/.config/cheatmd/cheatmd.md")
}

/// Plan: T-2. Covers: R-1.2.
@Test func firstLaunchCreatesTheSheetFromTheSample() throws {
    let home = try TempDir()
    let source = SheetSource(home: home.url)

    try source.createIfMissing()
    let text = try source.read()

    #expect(text == SheetSource.sample)
    let top = parse(text).children.map(\.name)
    #expect(top.contains("vi"))
    #expect(top.contains("tmux"))
}

/// Plan: T-3. Covers: R-1.5.
@Test func anExistingSheetIsNeverWritten() throws {
    let home = try TempDir()
    let source = SheetSource(home: home.url)
    try FileManager.default.createDirectory(
        at: source.url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("# mine\n".utf8).write(to: source.url)
    let past = Date(timeIntervalSince1970: 1_000_000)
    try FileManager.default.setAttributes([.modificationDate: past], ofItemAtPath: source.url.path)

    try source.createIfMissing()
    _ = try source.read()

    #expect(try String(contentsOf: source.url, encoding: .utf8) == "# mine\n")
    let modified = try FileManager.default.attributesOfItem(atPath: source.url.path)[.modificationDate]
    #expect(modified as? Date == past)
}

/// Plan: T-5. Covers: R-1.4.
@Test func unreadableSheetsNameThePathAndTheReason() throws {
    let home = try TempDir()
    let source = SheetSource(home: home.url)
    let path = source.url.path(percentEncoded: false)

    // Missing after start-up: the error names the path, and no sample is written.
    let missing = #expect(throws: SheetError.self) { try source.read() }
    #expect(missing?.path == path)
    #expect(missing?.description.contains(path) == true)
    #expect(missing?.reason.isEmpty == false)

    try source.createIfMissing()
    try Data([0x23, 0x20, 0xFF, 0xFE]).write(to: source.url)
    let invalid = #expect(throws: SheetError.self) { try source.read() }
    #expect(invalid?.description == "Cannot read \(path): not valid UTF-8")

    try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: path)
    let denied = #expect(throws: SheetError.self) { try source.read() }
    #expect(denied?.description.contains(path) == true)
    #expect(denied?.reason.localizedCaseInsensitiveContains("permission") == true)

    // Fixed again: the next read succeeds.
    try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: path)
    try Data("# back\n".utf8).write(to: source.url)
    #expect(try source.read() == "# back\n")
}
