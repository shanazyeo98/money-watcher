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
        do {
            let recurringExpenses = try context.fetch(FetchDescriptor<RecurringTransaction>())
            guard !recurringExpenses.isEmpty else { return }
            
            for expense in recurringExpenses {
                var lastDate = expense.latestOccurence
                while let next = expense.frequency.calculateNextOccurence(from: lastDate),
                      next <= date,
                      expense.endDate == nil || next <= expense.endDate! {
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
