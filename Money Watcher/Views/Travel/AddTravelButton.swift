//
//  AddTravelButton.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 17/7/26.
//

import SwiftUI

struct AddTravelButton: View {
    @State private var showingAddTravel = false
    
    var body: some View {
        Button {
            showingAddTravel = true
        } label: {
            Image(systemName: "plus")
        }
        .sheet(isPresented: $showingAddTravel) {
            AddTravelView()
        }
    }
}
