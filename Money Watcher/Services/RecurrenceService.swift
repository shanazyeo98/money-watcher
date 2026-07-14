//
//  Untitled.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 13/7/26.
//

import SwiftData
import Foundation

@MainActor
enum RecurrenceService {
    static func generateDueOccurrences(for date: Date = .now) {
        let context = SharedModelContainer.shared.mainContext
        let calendar = Calendar.current
        do {
            let recurringExpenses = try context.fetch(FetchDescriptor<RecurringTransaction>())
            guard !recurringExpenses.isEmpty else { return }
            
            for expense in recurringExpenses {
                var lastDate = expense.latestOccurence
                while let next = expense.frequency.calculateNextOccurence(from: lastDate),
                      calendar.startOfDay(for: next) <= calendar.startOfDay(for: date),
                      expense.endDate == nil || calendar.startOfDay(for: next) <= calendar.startOfDay(for: expense.endDate!) {
                    let newExpense = Transaction(amount: expense.amount, desc: expense.desc, date: next, category: expense.category)
                    context.insert(newExpense)
                    lastDate = next
                    expense.latestOccurence = lastDate
                }
            }
            
            try? context.save()
        } catch {
            print("Something went wrong with recurrence service")
        }
    }
}
