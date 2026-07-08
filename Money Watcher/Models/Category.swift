import Foundation
import SwiftData
import SwiftUI

// core feature of SwiftData - can automatically transform a standard Swift class into a data model that SwiftData can save, fetch and update
@Model
final class Category: Identifiable {
    var name: String
    var colorName: String
    var budgetAmount: Double
    
    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction] = []
    
    static let defaultLabel = "Uncategorised"
    var isDefault: Bool = false

    init(name: String, colorName: String, budgetAmount: Double, isDefault: Bool = false) {
        self.name = name
        self.colorName = colorName
        self.budgetAmount = budgetAmount
        self.isDefault = isDefault
    }

    var color: Color {
        Category.color(for: colorName)
    }

    var totalSpent: Double {
        transactions.reduce(0.0) { $0 + $1.amount }
    }

    static func color(for name: String) -> Color {
        switch name {
        case "red":    return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green":  return .green
        case "teal":   return .teal
        case "blue":   return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink":   return .pink
        default:       return .gray
        }
    }

    static let colorOptions = [
        "red", "orange", "yellow", "green", "teal", "blue", "indigo", "purple", "pink"
    ]
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
    }
}
