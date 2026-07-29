//
//  TravelModeButton.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 29/7/26.
//

import SwiftUI

struct TravelModeButton: View {
    @State private var showingStartTravelMode = false
    
    var body: some View {
        Button {
            showingStartTravelMode = true
        } label: {
            Image(systemName: "airplane.up.forward")
        }
        .sheet(isPresented: $showingStartTravelMode) {
            StartTravelModeSheet()
        }
    }
}
