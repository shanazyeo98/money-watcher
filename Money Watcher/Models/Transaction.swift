import Foundation
import SwiftData

// SwiftData: the objects needed in the database are marked with @Model

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var desc: String
    var date: Date
    var category: Category?
    var travel: Travel?

    // The amount as originally entered, before conversion into `amount`'s currency.
    var originalAmount: Double = 0
    // "" sentinel means this row predates currency tracking and hasn't been backfilled yet.
    var originalCurrencyCode: String = ""
    // originalAmount * exchangeRate == amount
    var exchangeRate: Double = 1.0

    init(
        amount: Double,
        desc: String,
        date: Date,
        category: Category? = nil,
        travel: Travel? = nil,
        originalAmount: Double? = nil,
        originalCurrencyCode: String? = nil,
        exchangeRate: Double = 1.0
    ) {
        self.id = UUID()
        self.amount = amount
        self.desc = desc
        self.date = date
        self.category = category
        self.travel = travel
        self.originalAmount = originalAmount ?? amount
        self.originalCurrencyCode = originalCurrencyCode ?? (travel?.currencyCode ?? CurrencySettings.current)
        self.exchangeRate = exchangeRate
    }
}
