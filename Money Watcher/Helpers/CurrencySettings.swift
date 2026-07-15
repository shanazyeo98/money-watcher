//
//  CurrencySettings.swift
//  Money Watcher
//

import Foundation

enum CurrencySettings {
    static let store = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier) ?? .standard
    static let key = "currencyCode"

    static var defaultCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    static var current: String {
        store.string(forKey: key) ?? defaultCode
    }

    static var selectableCodes: [String] {
        Locale.commonISOCurrencyCodes.sorted()
    }

    static func displayName(for code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    static func symbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }
}
