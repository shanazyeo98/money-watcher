import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    private var validCategories: [Category] {
        categories.filter { $0.isDefault == false }
    }
    @Query(sort: \Travel.startDate) private var travels: [Travel]

    let transaction: Transaction?
    let lockedTravel: Travel?

    @State private var amountText: String
    @State private var desc: String
    @State private var date: Date
    @State private var selectedCategory: Category?
    @State private var selectedTravel: Travel?
    @State private var isRecurring = false
    @State private var selectedRecurrence: Recurrence = .day
    @State private var endDate: Date = Date()
    @State private var hasEndDate = false

    @AppStorage(CurrencySettings.key, store: CurrencySettings.store) private var currencyCode = CurrencySettings.defaultCode

    @State private var selectedCurrencyCode = ""
    @State private var exchangeRate: Double = 1.0
    @State private var isFetchingRate = false
    @State private var rateFetchFailed = false

    init(transaction: Transaction? = nil, defaultTravel: Travel? = nil) {
        self.transaction = transaction
        self.lockedTravel = defaultTravel
        let travel = transaction?.travel ?? defaultTravel
        _amountText = State(initialValue: transaction.map { String($0.originalAmount) } ?? "")
        _desc = State(initialValue: transaction?.desc ?? "")
        _date = State(initialValue: transaction?.date ?? Date())
        _selectedCategory = State(initialValue: transaction?.category)
        _selectedTravel = State(initialValue: travel)
        _selectedCurrencyCode = State(initialValue: transaction?.originalCurrencyCode ?? travel?.currencyCode ?? "")
        _exchangeRate = State(initialValue: transaction?.exchangeRate ?? 1.0)
    }

    private var isValid: Bool {
        guard let value = Double(amountText) else { return false }
        return value > 0 && !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Currency of the budget this transaction rolls up into: the travel's
    // currency when tagged to a travel, otherwise the home currency.
    private var targetCurrencyCode: String {
        selectedTravel?.currencyCode ?? currencyCode
    }

    private var convertedAmountPreview: Double {
        (Double(amountText) ?? 0) * exchangeRate
    }

    private func fetchRateIfNeeded() async {
        guard selectedCurrencyCode != targetCurrencyCode else {
            exchangeRate = 1.0
            rateFetchFailed = false
            return
        }

        // Editing a transaction whose currency pair hasn't changed — keep the rate it was saved with.
        if let transaction,
           transaction.originalCurrencyCode == selectedCurrencyCode,
           (transaction.travel?.currencyCode ?? currencyCode) == targetCurrencyCode {
            exchangeRate = transaction.exchangeRate
            rateFetchFailed = false
            return
        }

        isFetchingRate = true
        rateFetchFailed = false
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        do {
            exchangeRate = try await ExchangeRateService.rate(from: selectedCurrencyCode, to: targetCurrencyCode)
        } catch {
            exchangeRate = 1.0
            rateFetchFailed = true
        }
        isFetchingRate = false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    Picker("Currency", selection: $selectedCurrencyCode) {
                        ForEach(CurrencySettings.selectableCodes, id: \.self) { code in
                            Text(CurrencySettings.displayName(for: code)).tag(code)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    HStack {
                        Text(CurrencySettings.symbol(for: selectedCurrencyCode))
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }

                    if selectedCurrencyCode != targetCurrencyCode {
                        conversionPreviewRow
                    }
                }
                .task(id: "\(selectedCurrencyCode)|\(targetCurrencyCode)") {
                    await fetchRateIfNeeded()
                }

                Section("Details") {
                    TextField("Description", text: $desc)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                if !travels.isEmpty {
                    Section("Travel") {
                        Picker("Travel", selection: $selectedTravel) {
                            Text("None").tag(nil as Travel?)
                            ForEach(travels) { travel in
                                Text(travel.name).tag(travel as Travel?)
                            }
                        }
                        .disabled(lockedTravel != nil)
                    }
                }

                if transaction == nil && selectedTravel == nil {
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
                }

                if selectedTravel == nil {
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
            }
            .navigationTitle(transaction == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(transaction == nil ? "Add" : "Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if transaction == nil {
                    selectedCategory = categories.first { $0.isDefault }
                }
                if selectedCurrencyCode.isEmpty {
                    selectedCurrencyCode = targetCurrencyCode
                }
            }
            .onChange(of: selectedTravel) { oldValue, newValue in
                if newValue != nil {
                    isRecurring = false
                    selectedCategory = categories.first { $0.isDefault }
                }
                // Follow the new budget's currency by default; the user can still override it.
                if transaction == nil {
                    selectedCurrencyCode = newValue?.currencyCode ?? currencyCode
                }
            }
        }
    }

    @ViewBuilder
    private var conversionPreviewRow: some View {
        HStack {
            if isFetchingRate {
                ProgressView()
                    .controlSize(.small)
                Text("Converting…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if rateFetchFailed {
                Text("Rate unavailable — using 1:1. You can adjust this later.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("≈ \(convertedAmountPreview.formatted(.currency(code: targetCurrencyCode)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        guard isValid, let originalAmountValue = Double(amountText) else { return }
        let convertedAmount = originalAmountValue * exchangeRate

        if selectedCategory == nil {
            selectedCategory = categories.first { $0.isDefault == true }
        }

        if let transaction {
            transaction.amount = convertedAmount
            transaction.desc = desc
            transaction.date = date
            transaction.category = selectedCategory
            transaction.travel = selectedTravel
            transaction.originalAmount = originalAmountValue
            transaction.originalCurrencyCode = selectedCurrencyCode
            transaction.exchangeRate = exchangeRate
        } else {
            let newTransaction = Transaction(
                amount: convertedAmount,
                desc: desc,
                date: date,
                category: selectedCategory,
                travel: selectedTravel,
                originalAmount: originalAmountValue,
                originalCurrencyCode: selectedCurrencyCode,
                exchangeRate: exchangeRate
            )
            modelContext.insert(newTransaction)
            if isRecurring {
                let recurringTxn = RecurringTransaction(
                    desc: desc,
                    amount: convertedAmount,
                    category: selectedCategory,
                    frequency: selectedRecurrence,
                    latestOccurence: date,
                    endDate: hasEndDate ? endDate : nil
                )
                modelContext.insert(recurringTxn)
            }
        }

        dismiss()
    }
}

#Preview("Add") {
    TransactionFormView()
}

#Preview("Edit") {
    TransactionFormView(transaction: Transaction(amount: 12.5, desc: "Coffee", date: .now))
}
