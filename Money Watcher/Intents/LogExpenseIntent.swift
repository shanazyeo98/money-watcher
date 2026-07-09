//
//  LogExpenseIntent.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 8/7/26.
//

import AppIntents
import SwiftData

enum LogExpenseIntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount:
            return "Amount must be a number greater than 0."
        }
    }
}

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log expense"

    static var description = IntentDescription(stringLiteral: "Log an expense in Money Watcher")

    @Parameter(title: "Amount")
    var amount: String

    @Parameter(title: "Merchant")
    var merchant: String

    @Parameter(title: "Name")
    var name: String

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let amountValue = Double(amount), amountValue > 0 else {
            throw LogExpenseIntentError.invalidAmount
        }
        
        let debugInfo = DebugLog(
            amount: amount,
            merchant: merchant,
            name: name
        )
        let modelContext = SharedModelContainer.shared.mainContext
        modelContext.insert(debugInfo)
        
//        let desc = [merchant, name]
//            .filter { !$0.isEmpty }
//            .joined(separator: " — ")
//
//        let modelContext = SharedModelContainer.shared.mainContext
//
//        let defaultCategory = try? modelContext.fetch(
//            FetchDescriptor<Category>(predicate: #Predicate { $0.isDefault })
//        ).first
//
//        let transaction = Transaction(amount: amountValue, desc: desc, date: Date(), category: defaultCategory)
//        modelContext.insert(transaction)
        try modelContext.save()

        return .result()
    }
}
