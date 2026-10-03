import Testing

@testable import CheatCore

/// Plan: T-31. Covers: R-6.3.
@Test func opensOnTheRememberedDisplayOnlyWhileItIsConnected() {
    let connected = ["Built-in Retina Display", "Kai's iPad"]

    #expect(
        DisplayChoice.pick(remembered: "Kai's iPad", connected: connected, main: connected[0]) == "Kai's iPad"
    )
    #expect(
        DisplayChoice.pick(remembered: "Old Monitor", connected: connected, main: connected[0])
            == connected[0])
    #expect(DisplayChoice.pick(remembered: nil, connected: connected, main: connected[0]) == connected[0])
}

/// Plan: T-32. Covers: R-6.6.
@Test func moveGoesToTheNextDisplayAndWrapsAround() {
    let connected = ["DELL", "Built-in", "Sidecar"]

    #expect(DisplayChoice.next(after: "DELL", connected: connected) == "Built-in")
    #expect(DisplayChoice.next(after: "Sidecar", connected: connected) == "DELL")
    #expect(DisplayChoice.next(after: "DELL", connected: ["DELL"]) == "DELL")
}
