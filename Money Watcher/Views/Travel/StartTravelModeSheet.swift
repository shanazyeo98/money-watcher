//
//  StartTravelModeSheet.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 28/7/26.
//

import SwiftUI
import SwiftData

struct StartTravelModeSheet: View {
    @Environment(TravelModeManager.self) private var travelModeManager
    @Query(sort: \Travel.startDate, order: .reverse) private var travels: [Travel]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTravel: Travel?
    
    var body: some View {
        NavigationStack {
            Group {
                if travels.isEmpty {
                    noTravelsView
                }
                else if !travelModeManager.isTravelModeOn {
                    startTravelModeView
                } else {
                    endTravelModeView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .onAppear() {
            selectedTravel = travels.first
        }
        
    }
    
    private var noTravelsView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Enable travel mode?")
                .font(.headline)
                .foregroundStyle(.foreground)
                .multilineTextAlignment(.center)
            Text("Create a travel in the travel tab in order to enable travel mode feature")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Okay") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.top, 16)
        }
        .padding(.horizontal, 16)
    }
    
    private var startTravelModeView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Enable travel mode?")
                .font(.headline)
                .foregroundStyle(.foreground)
                .multilineTextAlignment(.center)
            Text("Starting travel mode will switch the home tab's view to the selected travel's view and any new automated transactions coming in will be tagged to the travel")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Select a travel to enable travel mode")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Picker("Travel", selection: $selectedTravel) {
                ForEach(travels) {
                    travel in
                    Text(travel.name).tag(travel as Travel?)
                }
            }
            Button("Start Travel Mode") {
                startTravelMode()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.top, 16)
        }
        .padding(.horizontal, 16)
    }
    
    private var endTravelModeView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Disable travel mode?")
                .font(.headline)
                .foregroundStyle(.foreground)
                .multilineTextAlignment(.center)
            Text("Disabling travel mode will switch back to the monthly view and new automated transactions will not be tagged with a travel")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("End Travel Mode") {
                endTravelMode()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.top, 16)
        }
        .padding(.horizontal, 16)
    }
    
    private func startTravelMode() {
        guard let selectedTravel = selectedTravel else { return }
        travelModeManager.enable(for: selectedTravel)
    }
    
    private func endTravelMode() {
        travelModeManager.disable()
    }
}

#Preview {
}
