import SwiftUI
import SwiftData

// Environment: a dictionary of shared values that flows down the view hierarchy

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    private var validCategories: [Category] {
        categories.filter { $0.isDefault == false }
    }

    @State private var amountText = ""
    @State private var desc = ""
    @State private var date = Date()
    @State private var selectedCategory: Category?
    @State private var isRecurring = false
    @State private var selectedRecurrence: Recurrence = .day
    @State private var endDate: Date = Date()
    @State private var hasEndDate = false

    @AppStorage(CurrencySettings.key, store: CurrencySettings.store) private var currencyCode = CurrencySettings.defaultCode

    private var isValid: Bool {
        guard let value = Double(amountText) else { return false }
        return value > 0 && !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text(CurrencySettings.symbol(for: currencyCode))
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Details") {
                    TextField("Description", text: $desc)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Recurrence") {
                    Toggle("Is Recurring?", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Recurrence", selection: $selectedRecurrence) {
                            ForEach(Recurrence.allCases, id: \.self) { option in
                                Text(option.description).tag(option)
                            }
                        }
                        Toggle("Has End Date?", isOn: $hasEndDate.animation())
                        if hasEndDate {
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        }
                    }
                }

                Section("Category") {
                    if validCategories.isEmpty {
                        Text("No categories — add some in Settings first.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as Category?)
                            ForEach(validCategories) { category in
                                HStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 10, height: 10)
                                    Text(category.name)
                                }
                                .tag(category as Category?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                selectedCategory = categories.first { $0.isDefault }
            }
        }
    }

    private func save() {
        guard isValid, let amount = Double(amountText) else { return }
        let transaction = Transaction(amount: amount, desc: desc, date: date, category: selectedCategory)
        modelContext.insert(transaction)
        if isRecurring {
            let recurringTxn = RecurringTransaction(
                desc: desc,
                amount: amount,
                category: selectedCategory,
                frequency: selectedRecurrence,
                latestOccurence: date,
                endDate: hasEndDate ? endDate : nil
            )
            modelContext.insert(recurringTxn)
        }
        dismiss()
    }
}

#Preview {
    AddTransactionView()
}
