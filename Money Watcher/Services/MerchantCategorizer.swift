//
//  MerchantCategorizer.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 10/7/26.
//

import Foundation

enum MerchantCategorizerError: Error {
    case missingAPIKey
    case requestFailed(statusCode: Int)
    case invalidResponse
    case noCategories
    case urlIssue
}

struct MerchantCategorization {
    let category: String
    let normalizedMerchant: String
}

enum MerchantCategorizer {
    private static let apiURL = URL(string: "https://api.anthropic.com/v1/messages")
    private static let model = "claude-haiku-4-5"
    private static let apiVersion = "2023-06-01"
    private static let maxTokens = 256
    private static let apiKeyVariable = "ANTHROPIC_API_KEY"
    
    static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: apiKeyVariable) as? String
    }
    
    static func categorize(
        merchant: String,
        availableCategories: [String]
    ) async throws -> MerchantCategorization {
        guard let apiKey, !apiKey.isEmpty else {
            throw MerchantCategorizerError.missingAPIKey
        }
        guard !availableCategories.isEmpty else {
            throw MerchantCategorizerError.noCategories
        }
        
        let tool: [String: Any] = [
            "name": "categorize_transaction",
            "description": "Assign the single best-fitting spending category to this transaction. If there is no match, assign it to Uncategorised",
            "input_schema": [
                "type": "object",
                "properties": [
                    "category": [
                        "type": "string",
                        "enum": availableCategories,
                        "description": "Assign the single best-fitting spending category to this transaction. If there is no match, assign it to Uncategorised"
                    ],
                    "normalizedMerchant": [
                        "type": "string",
                        "description": "The general brand/store name only — with location, suburb, branch numbers, and payment-processor prefixes removed"
                    ]
                ],
                "required": ["category", "normalizedMerchant"]
            ]
        ]
        
        let userContent = """
            Merchant: \(merchant)
            Pick the single best-fitting category for this transaction from the available options and return the general brand/store name — with location, suburb, branch numbers, and payment-processor prefixes removed
            """
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "tools": [tool],
            "tool_choice": ["type": "tool", "name": "categorize_transaction"],
            "messages": [
                ["role": "user", "content": userContent]
            ]
        ]
        
        guard let url = apiURL else { throw MerchantCategorizerError.urlIssue }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw MerchantCategorizerError.requestFailed(statusCode: status)
        }
        
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let toolUse = content.first(where: { $0["type"] as? String == "tool_use" }),
            let input = toolUse["input"] as? [String: Any],
            let category = input["category"] as? String,
            let returnedMerchant = input["normalizedMerchant"] as? String
        else {
            throw MerchantCategorizerError.invalidResponse
        }
        
        return MerchantCategorization(category: category, normalizedMerchant: returnedMerchant)
    }
}
