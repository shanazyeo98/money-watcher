import Foundation
import SwiftData

@Model
final class Transaction {
    var amount: Double
    var desc: String
    var date: Date
    var category: Category?

    init(amount: Double, desc: String, date: Date, category: Category? = nil) {
        self.amount = amount
        self.desc = desc
        self.date = date
        self.category = category
    }
}
