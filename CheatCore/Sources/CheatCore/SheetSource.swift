import Foundation

/// Where the sheet lives (R-1.1).
public struct SheetSource: Sendable {
    public let url: URL

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        url = home.appending(path: ".config/cheatmd/cheatmd.md")
    }
}
