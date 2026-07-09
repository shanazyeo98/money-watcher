import SwiftUI
import SwiftData

@main
struct Money_WatcherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
