import SwiftUI

@main
struct CheatmdApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    // The window is AppKit's (see AppDelegate); this scene only satisfies `App`.
    var body: some Scene {
        Settings { EmptyView() }.commandsRemoved()
    }
}
