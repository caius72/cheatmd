/// An app that can be returned to; `NSRunningApplication` in the app target.
public protocol ActivatableApp: AnyObject {
    var processIdentifier: Int32 { get }
    var isTerminated: Bool { get }
}

/// Remembers the last other app to become active, to return focus to it (R-5.2, R-5.3).
public final class PreviousAppTracker<App: ActivatableApp> {
    private let ownProcessIdentifier: Int32
    private var last: App?

    public init(ownProcessIdentifier: Int32) {
        self.ownProcessIdentifier = ownProcessIdentifier
    }

    public func activated(_ app: App) {
        if app.processIdentifier != ownProcessIdentifier { last = app }
    }

    /// The app to return to, or nil when there is none or it has quit.
    public var previous: App? {
        guard let last, !last.isTerminated else { return nil }
        return last
    }
}
