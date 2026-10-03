import Testing

@testable import CheatCore

private final class FakeApp: ActivatableApp {
    let processIdentifier: Int32
    var isTerminated = false

    init(_ pid: Int32) { processIdentifier = pid }
}

/// Plan: T-24. Covers: R-5.2, R-5.3.
@Test func remembersTheLastOtherAppWhileItRuns() {
    let tracker = PreviousAppTracker<FakeApp>(ownProcessIdentifier: 1)
    let terminal = FakeApp(2)
    let safari = FakeApp(3)

    #expect(tracker.previous == nil)  // nothing activated yet
    tracker.activated(terminal)
    tracker.activated(FakeApp(1))  // cheatmd itself
    #expect(tracker.previous === terminal)
    tracker.activated(safari)
    #expect(tracker.previous === safari)
    safari.isTerminated = true
    #expect(tracker.previous == nil)  // quit since
}
