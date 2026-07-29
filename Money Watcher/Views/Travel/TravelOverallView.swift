//
//  TravelOverallView.swift
//  Money Watcher
//
//

import SwiftUI
import SwiftData

struct TravelOverallView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Travel.startDate, order: .reverse) private var travels: [Travel]
    @Environment(TravelModeManager.self) private var travelModeManager
    
    @State private var showingCannotDeleteAlert = false

    var body: some View {
        Group {
            if travels.isEmpty {
                emptyState
            } else {
                travelList
            }
        }
        .navigationTitle("Travels")
    }
    
    private var travelList: some View {
        List {
            ForEach(travels) { travel in
                NavigationLink {
                    TravelDetailView(travel: travel, isMainView: false)
                } label: {
                    TravelRow(travel: travel)
                }
            }
            .onDelete(perform: delete)
        }
        .alert("Unable to delete travel", isPresented: $showingCannotDeleteAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text("This travel is currently active in travel mode. Turn off travel mode before deleting")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No travels yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap + to create a travel.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }
    
    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            let travel = travels[index]
            guard travel.id != travelModeManager.activeTravel?.id else {
                showingCannotDeleteAlert = true
                return
            }
            modelContext.delete(travel)
        }
    }
    
}

struct TravelRow: View {
    let travel: Travel
    
    @AppStorage(CurrencySettings.key, store: CurrencySettings.store) private var currencyCode = CurrencySettings.defaultCode
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(travel.name)
                .fontWeight(.medium)
                Text(travel.country.name)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                Text("\(travel.startDate.formatted(date: .abbreviated, time: .omitted)) - \(travel.endDate.formatted(date: .abbreviated, time: .omitted))")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            }
            Spacer()
            Text(travel.totalSpent, format: .currency(code: travel.currencyCode))
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    TravelOverallView()
        .modelContainer(SampleData.preview)
}
