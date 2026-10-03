/// Which display to open on (R-6.3): the remembered one while it is connected, else the main one.
public enum DisplayChoice {
    public static func pick(remembered: String?, connected: [String], main: String) -> String {
        guard let remembered, connected.contains(remembered) else { return main }
        return remembered
    }

    /// The display after `current`, wrapping around after the last (R-6.6).
    public static func next(after current: String, connected: [String]) -> String {
        guard let index = connected.firstIndex(of: current) else { return current }
        return connected[(index + 1) % connected.count]
    }
}
