/// Turns key presses into query edits and effects (R-4.1, R-5.1, R-5.2).
public enum KeyReducer {
    public enum Key: Equatable, Sendable {
        case character(String)
        case backspace
        case escape
        case enter
    }

    public enum Effect: Equatable, Sendable {
        /// Make the previous app active again.
        case returnFocus
    }

    public static func reduce(_ query: String, _ key: Key) -> (query: String, effect: Effect?) {
        switch key {
        case .character(let text): (query + text, nil)
        case .backspace: (String(query.dropLast()), nil)
        case .escape: query.isEmpty ? (query, .returnFocus) : ("", nil)
        case .enter: (query, .returnFocus)
        }
    }
}
