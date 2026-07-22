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

    @State private var currencyCodeText = ""

    init(transaction: Transaction? = nil, defaultTravel: Travel? = nil) {
        self.transaction = transaction
        self.lockedTravel = defaultTravel
        _amountText = State(initialValue: transaction.map { String($0.amount) } ?? "")
        _desc = State(initialValue: transaction?.desc ?? "")
        _date = State(initialValue: transaction?.date ?? Date())
        _selectedCategory = State(initialValue: transaction?.category)
        _selectedTravel = State(initialValue: transaction?.travel ?? defaultTravel)
    }

    private var isValid: Bool {
        guard let value = Double(amountText) else { return false }
        return value > 0 && !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setCurrencyCode() {
        if let travel = selectedTravel {
            currencyCodeText = CurrencySettings.symbol(for: travel.currencyCode)
        } else {
            currencyCodeText = CurrencySettings.symbol(for: currencyCode)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text(currencyCodeText)
                            .foregroundStyle(.secondary)
                            .onAppear {
                                setCurrencyCode()
                            }
                            .onChange(of: selectedTravel) {
                                setCurrencyCode()
                            }
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
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
            }
            .onChange(of: selectedTravel) { oldValue, newValue in
                if newValue != nil {
                    isRecurring = false
                    selectedCategory = categories.first { $0.isDefault }
                }
            }
        }
    }

    private func save() {
        guard isValid, let amount = Double(amountText) else { return }

        if let transaction {
            transaction.amount = amount
            transaction.desc = desc
            transaction.date = date
            transaction.category = selectedCategory
            transaction.travel = selectedTravel
        } else {
            let newTransaction = Transaction(amount: amount, desc: desc, date: date, category: selectedCategory, travel: selectedTravel)
            modelContext.insert(newTransaction)
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
