//
//  CountryPickerView.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 17/7/26.
//

import Observation
import SwiftUI
import SwiftData

@Observable
final class TravelModeManager {
    let stringKey = "activeTravelID"
    
    var activeTravel: Travel? {
        didSet {
            UserDefaults.standard.set(activeTravel?.id.uuidString, forKey: stringKey)
        }
    }
    
    var isTravelModeOn: Bool {
        activeTravel != nil
    }
    
    func enable(for travel: Travel) {
        activeTravel = travel
    }
    
    func disable() {
        activeTravel = nil
    }
    
    func restore(from context: ModelContext) {
        guard
            let id = UserDefaults.standard.string(forKey: stringKey),
            let storedID = UUID(uuidString: id) else { return }
        let descriptor = FetchDescriptor<Travel>(
            predicate: #Predicate { $0.id == storedID }
        )
        
        if let travel = try? context.fetch(descriptor).first {
            activeTravel = travel
        } else {
            UserDefaults.standard.removeObject(forKey: stringKey)
        }
    }
}
