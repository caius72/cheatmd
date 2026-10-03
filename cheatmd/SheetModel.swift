import CheatCore
import Foundation
import Observation

/// What the window shows: the parsed sheet, or why it cannot be read.
@Observable
final class SheetModel {
    let source: SheetSource
    private(set) var sheet = SheetSection(title: "", level: 0)
    private(set) var error: String?
    var query = ""
    /// Persisted across launches (R-3.6).
    var zoom = Zoom(percent: UserDefaults.standard.object(forKey: "zoom") as? Int ?? 100) {
        didSet { UserDefaults.standard.set(zoom.percent, forKey: "zoom") }
    }

    init(source: SheetSource = SheetSource()) {
        self.source = source
        do {
            try source.createIfMissing()
        } catch {
            self.error =
                "Cannot create \(source.url.path(percentEncoded: false)): \(error.localizedDescription)"
            return
        }
        reload()
    }

    func reload() {
        do {
            sheet = SheetParser.parse(try source.read())
            error = nil
        } catch {
            self.error = "\(error)"
        }
    }

    var results: Results { Matcher.results(for: query, in: sheet) }
}
