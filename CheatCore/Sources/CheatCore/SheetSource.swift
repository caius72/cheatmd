import Foundation

/// The sheet file: where it lives (R-1.1), first-launch creation (R-1.2), and reading.
public struct SheetSource: Sendable {
    public let url: URL

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        url = home.appending(path: ".config/cheatmd/cheatmd.md")
    }

    /// The bundled sample written on first launch.
    public static let sample: String = {
        guard let url = Bundle.module.url(forResource: "sample", withExtension: "md"),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else { preconditionFailure("sample.md missing from the CheatCore bundle") }
        return text
    }()

    /// Writes the sample, and any missing folders, only when no file exists (R-1.2, R-1.5).
    public func createIfMissing() throws {
        guard !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(Self.sample.utf8).write(to: url, options: .withoutOverwriting)
    }

    public func read() throws(SheetError) -> String {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw SheetError(path: url.path(percentEncoded: false), reason: error.localizedDescription)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw SheetError(path: url.path(percentEncoded: false), reason: "not valid UTF-8")
        }
        return text
    }
}

/// Why the sheet could not be shown, naming the file (R-1.4).
public struct SheetError: Error, Equatable, Sendable, CustomStringConvertible {
    public let path: String
    public let reason: String

    public var description: String { "Cannot read \(path): \(reason)" }
}
