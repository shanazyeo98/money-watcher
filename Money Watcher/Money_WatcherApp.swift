import SwiftUI
import SwiftData

@main
struct Money_WatcherApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainer.shared)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                RecurrenceService.generateDueOccurrences()
            }
        }
    }
}
