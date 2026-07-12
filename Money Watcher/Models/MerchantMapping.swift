//
//  MerchantMapping.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 12/7/26.
//

import SwiftData

@Model
final class MerchantMapping {
    var key: String
    var rawMerchantNames: [String] = []
    var category: String
    
    init(key: String, merchantName: String, category: String) {
        self.key = key
        self.category = category
        self.rawMerchantNames.append(merchantName)
    }
    
    func appendMerchantNames(_ merchantName: String) {
        rawMerchantNames.append(merchantName)
    }
}
