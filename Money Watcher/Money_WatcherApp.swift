import SwiftUI
import SwiftData

@main
struct Money_WatcherApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            Transaction.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            seedDefaultCategoryIfNeeded(container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    private static func seedDefaultCategoryIfNeeded(_ cont: ModelContainer) {
        let isExistingCategorySeeded = (try? cont.mainContext.fetch(
            FetchDescriptor<Category>(
                predicate: #Predicate { $0.isDefault }
            )
        ).isEmpty) == false
        
        guard !isExistingCategorySeeded else { return }
        
        let uncategorisedCategory = Category(name: "Uncategorised", colorName: "gray", budgetAmount: 0, isDefault: true)
        cont.mainContext.insert(uncategorisedCategory)
        try? cont.mainContext.save()
    }
}
