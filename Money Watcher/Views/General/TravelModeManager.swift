//
//  CountryPickerView.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 17/7/26.
//

import Observation
import SwiftUI

@Observable
final class TravelModeManager {
    var activeTravel: Travel? {
        didSet {
            UserDefaults.standard.set(activeTravel?.id.uuidString, forKey: "activeTravelID")
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
}
