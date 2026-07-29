//
//  ExchangeRateService.swift
//  Money Watcher
//

import Foundation

enum ExchangeRateError: Error {
    case invalidURL
    case requestFailed(statusCode: Int)
    case invalidResponse
    case unsupportedCurrency
}

// Free, keyless daily FX rates. Chosen over Frankfurter because it covers the
// full ISO currency list (CurrencySettings/Travel.currencyCode allow any of
// them), not just the ~33 currencies Frankfurter tracks.
enum ExchangeRateService {
    private static let baseURL = "https://open.er-api.com/v6/latest"
    private static let store = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier) ?? .standard

    private struct Cache: Codable {
        let base: String
        let rates: [String: Double]
        let fetchedAt: Date
    }

    static func rate(from: String, to: String) async throws -> Double {
        guard from != to else { return 1.0 }

        if let cached = readCache(base: from),
           Calendar.current.isDateInToday(cached.fetchedAt),
           let rate = cached.rates[to] {
            return rate
        }

        do {
            let fresh = try await fetchLive(base: from)
            writeCache(fresh)
            guard let rate = fresh.rates[to] else { throw ExchangeRateError.unsupportedCurrency }
            return rate
        } catch {
            // Fall back to a stale cache rather than failing outright — an
            // older rate still beats blocking/losing the transaction.
            if let stale = readCache(base: from), let rate = stale.rates[to] {
                return rate
            }
            throw error
        }
    }

    private static func fetchLive(base: String) async throws -> Cache {
        guard let url = URL(string: "\(baseURL)/\(base)") else {
            throw ExchangeRateError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ExchangeRateError.requestFailed(statusCode: status)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rates = json["rates"] as? [String: Double]
        else {
            throw ExchangeRateError.invalidResponse
        }

        return Cache(base: base, rates: rates, fetchedAt: Date())
    }

    private static func readCache(base: String) -> Cache? {
        guard let data = store.data(forKey: cacheKey(for: base)) else { return nil }
        return try? JSONDecoder().decode(Cache.self, from: data)
    }

    private static func writeCache(_ cache: Cache) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        store.set(data, forKey: cacheKey(for: cache.base))
    }

    private static func cacheKey(for base: String) -> String { "fxCache_\(base)" }
}
