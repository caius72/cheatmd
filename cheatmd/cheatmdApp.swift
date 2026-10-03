import SwiftUI

@main
struct CheatmdApp: App {
    @State private var model = SheetModel()

    var body: some Scene {
        WindowGroup {
            SheetView(model: model)
        }
    }
}
