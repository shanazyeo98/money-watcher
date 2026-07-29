//
//  LogExpenseIntent.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 8/7/26.
//

import AppIntents
import SwiftData
import Foundation
import SwiftUI

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
        guard let parsedAmount = parseCurrencyAmount(amount), parsedAmount.amount > 0 else {
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
        var assignedTravel: Travel?
        
        guard let defaultCategoryName = defaultCategory?.name else {
            throw LogExpenseIntentError.noDefaultCategory
        }
        
        let cleanedMerchant = cleanMerchantName()
        
        if let activeTravelID = UserDefaults.standard.string(forKey: "activeTravelID") {
            let travels = try modelContext.fetch(FetchDescriptor<Travel>())
            assignedTravel = travels.first { $0.id.uuidString == activeTravelID }
        } else {
            let retrievedMappings = try modelContext.fetch(FetchDescriptor<MerchantMapping>())
            
            if let retrievedCategoryFromMapping = try checkInternalMapping(for: cleanedMerchant, existingMappings: retrievedMappings) {
                assignedCategory = retrievedCategoryFromMapping
            } else {
                do {
                    let categorizedMerchant = try await MerchantCategorizer.categorize(merchant: cleanedMerchant, availableCategories: parsedCategories)
                    assignedCategory = categorizedMerchant.category
                    storeMapping(rawMerchant: cleanedMerchant, parsedMerchant: categorizedMerchant, existingMappings: retrievedMappings)
                } catch {
                    assignedCategory = defaultCategoryName
                }
            }
        }
        
        let category = categories.first { $0.name == assignedCategory } ?? defaultCategory

        let targetCurrencyCode = assignedTravel?.currencyCode ?? CurrencySettings.current
        let originalCurrencyCode = parsedAmount.currencyCode ?? targetCurrencyCode
        var exchangeRate = 1.0
        if originalCurrencyCode != targetCurrencyCode {
            exchangeRate = (try? await ExchangeRateService.rate(from: originalCurrencyCode, to: targetCurrencyCode)) ?? 1.0
        }

        let transaction = Transaction(
            amount: parsedAmount.amount * exchangeRate,
            desc: desc,
            date: Date(),
            category: category,
            travel: assignedTravel,
            originalAmount: parsedAmount.amount,
            originalCurrencyCode: originalCurrencyCode,
            exchangeRate: exchangeRate
        )
        modelContext.insert(transaction)
    }
    
    @MainActor
    private func storeMapping(rawMerchant: String, parsedMerchant: MerchantCategorization, existingMappings: [MerchantMapping]) {
        if let mapping = existingMappings.first(where: { $0.key == parsedMerchant.normalizedMerchant }) {
            mapping.appendMerchantNames(rawMerchant)
        } else {
            let modelContext = SharedModelContainer.shared.mainContext
            modelContext.insert(MerchantMapping(key: parsedMerchant.normalizedMerchant, merchantName: rawMerchant, category: parsedMerchant.category))
        }
    }
    
    private func cleanMerchantName() -> String {
        var cleanedName = merchant
        if let range = cleanedName.range(of: "*") {
            cleanedName = String(cleanedName[range.upperBound...])
        }
        return cleanedName
    }
    
    @MainActor
    private func checkInternalMapping(for merchant: String, existingMappings: [MerchantMapping]) throws -> String? {
        let retrievedMapping = existingMappings.first { $0.rawMerchantNames.contains(merchant) }
        guard let mapping = retrievedMapping else { return nil }
        return mapping.category
    }
}
