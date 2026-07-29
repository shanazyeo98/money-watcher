//
//  TransactionHelpers.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 10/7/26.
//

import Foundation

struct ParsedCurrencyAmount {
    let amount: Double
    // nil means no explicit currency indicator was found in the text — the
    // caller should assume it's already in whatever currency is expected.
    let currencyCode: String?
}

// Bank/card notification text (fed in via Shortcuts) commonly prefixes the
// amount with a shorthand that's ambiguous under a bare "$" — e.g. "A$20.00"
// (AUD) vs "S$20.00" (SGD). Longest-prefix-first so "US$" isn't shadowed by "$".
private let currencyPrefixMap: [(prefix: String, code: String)] = [
    ("AU$", "AUD"), ("A$", "AUD"),
    ("SG$", "SGD"), ("S$", "SGD"),
    ("HK$", "HKD"),
    ("NT$", "TWD"),
    ("NZ$", "NZD"),
    ("CA$", "CAD"), ("C$", "CAD"),
    ("US$", "USD"),
    ("R$", "BRL"),
    ("£", "GBP"),
    ("€", "EUR"),
    ("¥", "JPY"),
    ("₩", "KRW"),
    ("₹", "INR")
]

func parseCurrencyAmount(_ value: String) -> ParsedCurrencyAmount? {
    let trimmed = value.trimmingCharacters(in: .whitespaces)

    // Leading ISO code, e.g. "SGD 20.00" or "USD20.00".
    if let isoMatch = trimmed.range(of: #"^[A-Z]{3}\b"#, options: .regularExpression) {
        let code = String(trimmed[isoMatch])
        let rest = trimmed[isoMatch.upperBound...].trimmingCharacters(in: .whitespaces)
        guard let amount = Double(rest) else { return nil }
        return ParsedCurrencyAmount(amount: amount, currencyCode: code)
    }

    // Known shorthand symbol/prefix.
    for (prefix, code) in currencyPrefixMap where trimmed.hasPrefix(prefix) {
        let rest = trimmed.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
        guard let amount = Double(rest) else { return nil }
        return ParsedCurrencyAmount(amount: amount, currencyCode: code)
    }

    // No explicit currency indicator — fall back to stripping the home
    // currency's own symbol (today's behavior) and leave currencyCode nil.
    let symbol = CurrencySettings.symbol(for: CurrencySettings.current)
    let cleanedValue = trimmed.replacingOccurrences(of: symbol, with: "").trimmingCharacters(in: .whitespaces)
    guard let amount = Double(cleanedValue) else { return nil }
    return ParsedCurrencyAmount(amount: amount, currencyCode: nil)
}
