import Foundation

/// Notices when the sheet file changes on disk (R-1.3): in-place writes, saves by rename, and
/// deletion or recreation all change its inode, size or modification date. Polled, because a
/// file-system event source on the file loses track of it after a save by rename.
public final class ChangeDetector {
    /// How often the app polls; R-1.3 allows 2 s.
    public static let pollInterval = Duration.seconds(1)

    private struct Fingerprint: Equatable {
        let inode: Int?
        let size: Int?
        let modified: Date?
    }

    private let url: URL
    private var last: Fingerprint?

    public init(url: URL) {
        self.url = url
        last = fingerprint()
    }

    /// True once per change since the previous call.
    public func changed() -> Bool {
        let now = fingerprint()
        defer { last = now }
        return now != last
    }

    private func fingerprint() -> Fingerprint? {
        guard
            let attributes = try? FileManager.default.attributesOfItem(
                atPath: url.path(percentEncoded: false))
        else { return nil }
        return Fingerprint(
            inode: attributes[.systemFileNumber] as? Int,
            size: attributes[.size] as? Int,
            modified: attributes[.modificationDate] as? Date)
    }
}
