import AppKit
import CheatCore
import SwiftUI

/// Owns the single fullscreen window (R-6.*).
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static let displayKey = "display"
    private let model = SheetModel()
    private var window: FullscreenWindow?
    private let tracker = PreviousAppTracker<RunningApp>(
        ownProcessIdentifier: ProcessInfo.processInfo.processIdentifier)
    private var activationObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = FullscreenWindow(
            contentViewController: NSHostingController(rootView: SheetView(model: model)))
        window.title = "cheatmd"
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.delegate = self
        window.setFrame(launchScreen().visibleFrame, display: false)
        self.window = window
        addMoveMenuItem()
        trackPreviousApp()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event) ?? event
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        // Once the window is on screen; the backstops below cover an app that is not active yet.
        DispatchQueue.main.async { window.toggleFullScreen(nil) }
    }

    /// Backstops for a fullscreen request that did not take (R-6.1): AppKit refuses fullscreen
    /// while the app is inactive or the screen is locked, and `activate()` is only a request.
    func applicationDidBecomeActive(_ notification: Notification) { enterFullScreenIfNeeded() }
    func windowDidBecomeKey(_ notification: Notification) { enterFullScreenIfNeeded() }

    private func enterFullScreenIfNeeded() {
        guard let window, !window.styleMask.contains(.fullScreen), moveTarget == nil else { return }
        window.toggleFullScreen(nil)
    }

    /// Window → Move to Next Display (R-6.6). Added through AppKit: SwiftUI command buttons do
    /// not fire in an app without SwiftUI windows, and with no SwiftUI scene commands there is no
    /// Window menu to begin with.
    private func addMoveMenuItem() {
        if NSApp.windowsMenu == nil {
            let menu = NSMenu(title: "Window")
            let top = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
            top.submenu = menu
            NSApp.mainMenu?.addItem(top)
            NSApp.windowsMenu = menu
        }
        let arrow = String(UnicodeScalar(UInt16(NSRightArrowFunctionKey)).map(Character.init) ?? " ")
        let item = NSMenuItem(
            title: "Move to Next Display", action: #selector(moveToNextDisplay), keyEquivalent: arrow)
        item.keyEquivalentModifierMask = [.control, .command]
        item.target = self
        NSApp.windowsMenu?.addItem(item)
    }

    /// Feeds every app activation to the tracker, starting with whatever is frontmost now.
    private func trackPreviousApp() {
        if let front = NSWorkspace.shared.frontmostApplication { tracker.activated(RunningApp(front)) }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            MainActor.assumeIsolated { self?.tracker.activated(RunningApp(app)) }
        }
    }

    /// Typing goes to the query (R-4.1, R-5.1, R-5.2). Chords with Command or Control, and keys
    /// that type nothing (arrows, function keys), pass through to the menus and the scroll view.
    private func handle(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.isDisjoint(with: [.command, .control]), let key = Self.key(for: event) else {
            return event
        }
        let (query, effect) = KeyReducer.reduce(model.query, key)
        model.query = query
        if effect == .returnFocus { tracker.previous?.app.activate() }
        return nil
    }

    private static func key(for event: NSEvent) -> KeyReducer.Key? {
        switch event.keyCode {
        case 53: return .escape
        case 36, 76: return .enter
        case 51: return .backspace
        default:
            guard let text = event.characters, !text.isEmpty,
                text.unicodeScalars.allSatisfy({
                    !CharacterSet.controlCharacters.contains($0) && !(0xF700...0xF8FF).contains($0.value)
                })
            else { return nil }
            return .character(text)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// The remembered display while it is connected, else the main one (R-6.3).
    private func launchScreen() -> NSScreen {
        let screens = NSScreen.screens
        guard let main = NSScreen.main ?? screens.first else { preconditionFailure("no screen") }
        let name = DisplayChoice.pick(
            remembered: UserDefaults.standard.string(forKey: Self.displayKey),
            connected: screens.map(\.localizedName), main: main.localizedName)
        return screens.first { $0.localizedName == name } ?? main
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let screen = window?.screen else { return }
        UserDefaults.standard.set(screen.localizedName, forKey: Self.displayKey)
    }

    /// Where to re-enter fullscreen after Move to Next Display.
    private var moveTarget: NSScreen?

    /// Leaves fullscreen, moves to the next display, and re-enters fullscreen (R-6.6).
    @objc func moveToNextDisplay() {
        guard let window, let current = window.screen else { return }
        let screens = NSScreen.screens
        let name = DisplayChoice.next(after: current.localizedName, connected: screens.map(\.localizedName))
        guard name != current.localizedName, let target = screens.first(where: { $0.localizedName == name })
        else { return }
        moveTarget = target
        window.leaveFullScreenToMove()
    }

    /// Re-enters fullscreen after a move, and is the backstop for any path that leaves
    /// fullscreen without `toggleFullScreen` (R-6.2).
    func windowDidExitFullScreen(_ notification: Notification) {
        guard let window else { return }
        if let target = moveTarget {
            window.setFrame(target.visibleFrame, display: true)
            moveTarget = nil
        }
        window.toggleFullScreen(nil)
    }
}

/// A window that can enter fullscreen but never leave it (R-6.2).
final class FullscreenWindow: NSWindow {
    override func toggleFullScreen(_ sender: Any?) {
        guard !styleMask.contains(.fullScreen) else { return }
        super.toggleFullScreen(sender)
    }

    /// The only way out of fullscreen, used to move between displays (R-6.6).
    func leaveFullScreenToMove() {
        if styleMask.contains(.fullScreen) { super.toggleFullScreen(nil) }
    }
}

/// A running app as the tracker sees it.
final class RunningApp: ActivatableApp {
    let app: NSRunningApplication

    init(_ app: NSRunningApplication) { self.app = app }

    var processIdentifier: Int32 { app.processIdentifier }
    var isTerminated: Bool { app.isTerminated }
}
