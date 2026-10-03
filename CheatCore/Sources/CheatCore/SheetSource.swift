import Foundation

/// Where the sheet lives (R-1.1).
public struct SheetSource: Sendable {
    public let url: URL

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        url = home.appending(path: ".config/cheatmd/cheatmd.md")
    }
}

// Planted lint violation: force_try.
public let planted = try! String(contentsOfFile: "/etc/hosts", encoding: .utf8)
