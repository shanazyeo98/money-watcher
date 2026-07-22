//
//  Country.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 17/7/26.
//

import Foundation

struct Country: Identifiable, Hashable, Comparable, Codable{
    let id: String
    let name: String
    
    static func < (lhs: Country, rhs: Country) -> Bool {
        lhs.name < rhs.name
    }
}

extension Country {
    static var all: [Country] {
        let locale = Locale.current
        return Locale.Region.isoRegions
            .filter { $0.isISORegion }
            .compactMap { region in
                guard let name = locale.localizedString(forRegionCode: region.identifier) else { return nil }
                return Country(id: region.identifier, name: name)
            }
            .sorted()
    }
}
