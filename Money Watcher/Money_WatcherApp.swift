import SwiftUI
import SwiftData

@main
struct Money_WatcherApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var travelModeManager = TravelModeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(travelModeManager)
        }
        .modelContainer(SharedModelContainer.shared)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                RecurrenceService.generateDueOccurrences()
            }
        }
    }
}
