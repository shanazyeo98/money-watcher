//
//  DebugLog.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 9/7/26.
//

import Foundation
import SwiftData

@Model
final class DebugLog {
    var createdAt: Date
    var amount: String
    var merchant: String
    var name: String
    
    init(amount: String, merchant: String, name: String) {
        self.createdAt = Date()
        self.amount = amount
        self.merchant = merchant
        self.name = name
    }
}
