import CheatCore
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(SheetSource().url.path(percentEncoded: false))
            .padding()
    }
}
