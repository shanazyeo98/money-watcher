//
//  Travel.swift
//  Money Watcher
//

import Foundation
import SwiftData

@Model
final class Travel {
    var name: String
    var startDate: Date
    var endDate: Date
    var budget: Double?
    var country: Country
    var currencyCode: String
    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction] = []
    
    var totalSpent: Double {
        transactions.reduce(0.0) { $0 + $1.amount }
    }
    
    init(name: String, startDate: Date, endDate: Date, budget: Double? = nil, country: Country, currencyCode: String) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.country = country
        self.currencyCode = currencyCode
    }
}
