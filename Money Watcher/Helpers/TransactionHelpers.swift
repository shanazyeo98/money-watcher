//
//  TransactionHelpers.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 10/7/26.
//

import Foundation

func parseCurrencyAmount(_ value: String) -> Double? {
    let symbol = CurrencySettings.symbol(for: CurrencySettings.current)
    let cleanedValue = value.replacingOccurrences(of: symbol, with: "").trimmingCharacters(in: .whitespaces)
    return Double(cleanedValue)
}
