//
//  AddTravelView.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 15/7/26.
//

import Foundation
import SwiftData
import SwiftUI

struct AddTravelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let travel: Travel?

    @State private var name: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var budget: Double?
    @State private var selectedCountry: Country
    @State private var currencyCode = CurrencySettings.defaultCode

    private var isValid: Bool {
        let calendar = Calendar.current
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
              calendar.startOfDay(for: startDate) <= calendar.startOfDay(for: endDate)
    }

    init(travel: Travel? = nil) {
        self.travel = travel

        if let travel {
            _name = State(initialValue: travel.name)
            _startDate = State(initialValue: travel.startDate)
            _endDate = State(initialValue: travel.endDate)
            _budget = State(initialValue: travel.budget)
            _selectedCountry = State(initialValue: travel.country)
            _currencyCode = State(initialValue: travel.currencyCode)
        } else {
            let regionCode = Locale.current.region?.identifier ?? "US"
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? "United States"
            _selectedCountry = State(initialValue: Country(id: regionCode, name: name))
            if let seededEndDate = Calendar.current.date(byAdding: DateComponents(day: 7), to: Date()) {
                _endDate = State(initialValue: seededEndDate)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip's Details") {
                    TextField("Name", text: $name)
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(Country.all) { country in
                            Text(country.name).tag(country)
                        }
                    }
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                Section("Budget") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(CurrencySettings.selectableCodes, id: \.self) { code in
                            Text(CurrencySettings.displayName(for: code)).tag(code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    LabeledContent("Amount") {
                        TextField("", value: $budget, format: .currency(code: currencyCode))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle(travel == nil ? "Add New Travel" : "Edit Travel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(travel == nil ? "Add" : "Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    func save() {
        guard isValid else { return }

        if let travel {
            travel.name = name
            travel.startDate = startDate
            travel.endDate = endDate
            travel.budget = budget
            travel.country = selectedCountry
            travel.currencyCode = currencyCode
        } else {
            let newTravel = Travel(name: name, startDate: startDate, endDate: endDate, budget: budget, country: selectedCountry, currencyCode: currencyCode)
            modelContext.insert(newTravel)
        }

        dismiss()
    }
}

#Preview("Add") {
    AddTravelView()
}

#Preview("Edit") {
    AddTravelView(travel: Travel(name: "Japan Trip", startDate: .now, endDate: .now, budget: 1000, country: Country(id: "JP", name: "Japan"), currencyCode: "JPY"))
}
