//
//  TransactionHelpers.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 10/7/26.
//

import Foundation

func parseCurrencyAmount(_ value: String) -> Double? {
//    let formatter = NumberFormatter()
//    formatter.numberStyle = .currency
//    formatter.locale = Locale(identifier: "en_AU")
    
    let cleanedValue = value.replacingOccurrences(of: "A$", with: "").trimmingCharacters(in: .whitespaces)
//    let amount = formatter.number(from: cleanedValue)?.doubleValue
    let amount = Double(cleanedValue)
    print("amount: \(amount), cleanedValue: \(cleanedValue)")
    
    return amount
}
