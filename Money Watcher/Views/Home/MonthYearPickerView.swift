import SwiftUI

struct MonthYearPickerView: View {
    @Binding var selectedMonth: Date
    @Environment(\.dismiss) private var dismiss

    @State private var monthIndex: Int
    @State private var year: Int

    private let months = Calendar.current.monthSymbols
    private let years: [Int]

    init(selectedMonth: Binding<Date>) {
        self._selectedMonth = selectedMonth
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selectedMonth.wrappedValue)
        self._monthIndex = State(initialValue: (components.month ?? 1) - 1)
        self._year = State(initialValue: components.year ?? calendar.component(.year, from: .now))

        let currentYear = calendar.component(.year, from: .now)
        self.years = Array((currentYear - 15)...(currentYear + 15))
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Month", selection: $monthIndex) {
                    ForEach(months.indices, id: \.self) { index in
                        Text(months[index]).tag(index)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Year", selection: $year) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var components = DateComponents()
                        components.year = year
                        components.month = monthIndex + 1
                        components.day = 1
                        if let date = Calendar.current.date(from: components) {
                            selectedMonth = date
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}

#Preview {
    MonthYearPickerView(selectedMonth: .constant(.now))
}
