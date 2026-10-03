import Testing

@testable import CheatCore

/// Plan: T-15. Covers: R-3.6.
@Test func zoomStepsByTenPercentBetweenFiftyAndThreeHundred() {
    var zoom = Zoom()
    #expect(zoom.percent == 100)
    zoom.zoomIn()
    #expect(zoom.percent == 110)
    #expect(zoom.scale == 1.1)

    for _ in 0..<30 { zoom.zoomIn() }
    #expect(zoom.percent == 300)
    for _ in 0..<30 { zoom.zoomOut() }
    #expect(zoom.percent == 50)

    zoom.reset()
    #expect(zoom.percent == 100)
    #expect(Zoom(percent: 1000).percent == 300)  // a stored value out of range is clamped
}
