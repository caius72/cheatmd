import Foundation

/// What to display for a query.
public enum Results: Equatable, Sendable {
    /// The whole sheet, unfiltered (R-3.1).
    case all(SheetSection)
}

public enum Matcher {
    public static func results(for query: String, in sheet: SheetSection) -> Results {
        // ponytail: filtering arrives with slice 3 (R-4.*); until then every query shows all.
        .all(sheet)
    }
}
