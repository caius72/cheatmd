import SwiftUI

@main
struct CheatmdApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    // The window is AppKit's (see AppDelegate); this scene only satisfies `App`.
    var body: some Scene {
        // Keep SwiftUI's standard menus (Quit lives there); drop only the empty Settings item.
        Settings { EmptyView() }
            .commands { CommandGroup(replacing: .appSettings) {} }
    }
}
