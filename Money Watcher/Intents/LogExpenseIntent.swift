//
//  LogExpenseIntent.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 8/7/26.
//

import AppIntents
import SwiftData
import SwiftData

enum LogExpenseIntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case noDefaultCategory

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount:
            return "Amount must be a number greater than 0."
        case .noDefaultCategory:
            return "No default category set up"
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
        let debugInfo = DebugLog(
            amount: amount,
            merchant: merchant,
            name: name
        )
        let modelContext = SharedModelContainer.shared.mainContext
        modelContext.insert(debugInfo)
        
        try await storeTransaction()

        try modelContext.save()

        return .result()
    }
    
    @MainActor
    private func storeTransaction() async throws {
        guard let amountValue = parseCurrencyAmount(amount), amountValue > 0 else {
            throw LogExpenseIntentError.invalidAmount
        }
        
        let desc = [merchant, name]
            .filter { !$0.isEmpty }
            .joined(separator: " — ")
        
        let modelContext = SharedModelContainer.shared.mainContext
        
        let categories = try modelContext.fetch(FetchDescriptor<Category>())
        let defaultCategory = categories.first { $0.isDefault }
        let parsedCategories = categories.map { $0.name }
        var assignedCategory: String?
        
        guard let defaultCategoryName = defaultCategory?.name else {
            throw LogExpenseIntentError.noDefaultCategory
        }
        
        do {
            assignedCategory = try await MerchantCategorizer.categorize(merchant: merchant, availableCategories: parsedCategories)
        } catch {
            assignedCategory = defaultCategoryName
        }
        
        let category = categories.first { $0.name == assignedCategory }
        
        let transaction = Transaction(amount: amountValue, desc: desc, date: Date(), category: category)
        modelContext.insert(transaction)
    }
}
