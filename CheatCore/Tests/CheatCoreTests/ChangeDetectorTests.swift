import Foundation
import Testing

@testable import CheatCore

/// Plan: T-4. Covers: R-1.3.
@Test func detectsEveryKindOfSaveAndNothingElse() throws {
    let home = try TempDir()
    let url = home.url.appending(path: "sheet.md")
    try Data("# one\n".utf8).write(to: url)
    let detector = ChangeDetector(url: url)

    #expect(ChangeDetector.pollInterval <= .seconds(2))
    #expect(!detector.changed())  // untouched

    let handle = try FileHandle(forWritingTo: url)  // in place, same inode
    try handle.seekToEnd()
    try handle.write(contentsOf: Data("- `a` b\n".utf8))
    try handle.close()
    #expect(detector.changed())
    #expect(!detector.changed())  // reported once

    let temp = home.url.appending(path: "sheet.md.swp")  // save by rename, as vim does
    try Data("# two\n".utf8).write(to: temp)
    _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
    #expect(detector.changed())

    try FileManager.default.removeItem(at: url)  // deleted, then recreated
    #expect(detector.changed())
    try Data("# three\n".utf8).write(to: url)
    #expect(detector.changed())
    #expect(!detector.changed())
}
