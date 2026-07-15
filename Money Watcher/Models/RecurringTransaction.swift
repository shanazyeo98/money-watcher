//
//  Recurrence.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 13/7/26.
//

import SwiftData
import Foundation
import SwiftUI

enum Recurrence: String, CaseIterable, Hashable, Codable {
    case day
    case week
    case fortnight
    case month
    case year
    
    var description: String {
        switch self {
        case .day:
            return "Everyday"
        case .week:
            return "Every week"
        case .fortnight:
            return "Every fortnight"
        case .month:
            return "Every month"
        case .year:
            return "Every year"
        }
    }
    
    var dateComponent: DateComponents {
        switch self {
        case .day:
            return DateComponents(day: 1)
        case .week:
            return DateComponents(day: 7)
        case .fortnight:
            return DateComponents(day: 14)
        case .month:
            return DateComponents(month: 1)
        case .year:
            return DateComponents(year: 1)
        }
    }
    
    func calculateNextOccurence(from currentDate: Date) -> Date? {
        return Calendar.current.date(byAdding: self.dateComponent, to: currentDate)
    }
}

@Model
final class RecurringTransaction {
    var desc: String
    var amount: Double
    var category: Category?
    var frequency: Recurrence
    var latestOccurence: Date
    var endDate: Date?
    
    init(desc: String, amount: Double, category: Category? = nil, frequency: Recurrence, latestOccurence: Date, endDate: Date?) {
        self.desc = desc
        self.amount = amount
        self.category = category
        self.frequency = frequency
        self.latestOccurence = latestOccurence
        self.endDate = endDate
    }
}

