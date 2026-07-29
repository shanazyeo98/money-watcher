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

    init(amount: Double, desc: String, date: Date, category: Category? = nil, travel: Travel? = nil) {
        self.id = UUID()
        self.amount = amount
        self.desc = desc
        self.date = date
        self.category = category
        self.travel = travel
    }
}
