//
//  SharedModelContainer.swift
//  Money Watcher
//

import Foundation
import SwiftData

// App Intents run headlessly (no SwiftUI view hierarchy), so they can't rely on
// `@Environment(\.modelContext)`. This gives both the app and intents the same
// container regardless of who initializes it first.
@MainActor
enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.shanazyeo.moneywatcher"

    static let shared: ModelContainer = {
        let schema = Schema([
            Category.self,
            Transaction.self,
            DebugLog.self,
            MerchantMapping.self
        ])

        let config: ModelConfiguration
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = appGroupURL.appendingPathComponent("MoneyWatcher.sqlite")
            config = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            print("Could not generate app group storage")
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            seedDefaultCategoryIfNeeded(container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private static func seedDefaultCategoryIfNeeded(_ container: ModelContainer) {
        let isExistingCategorySeeded = (try? container.mainContext.fetch(
            FetchDescriptor<Category>(
                predicate: #Predicate { $0.isDefault }
            )
        ).isEmpty) == false

        guard !isExistingCategorySeeded else { return }

        let uncategorisedCategory = Category(name: "Uncategorised", colorName: "gray", budgetAmount: 0, isDefault: true)
        container.mainContext.insert(uncategorisedCategory)
        try? container.mainContext.save()
    }
}
