/// Sheet zoom in 10% steps, 50–300% (R-3.6). Whole percents avoid floating-point drift.
public struct Zoom: Equatable, Sendable {
    public private(set) var percent: Int

    public init(percent: Int = 100) {
        self.percent = min(max(percent, 50), 300)
    }

    public var scale: Double { Double(percent) / 100 }

    public mutating func zoomIn() { self = Zoom(percent: percent + 10) }
    public mutating func zoomOut() { self = Zoom(percent: percent - 10) }
    public mutating func reset() { self = Zoom() }
}
