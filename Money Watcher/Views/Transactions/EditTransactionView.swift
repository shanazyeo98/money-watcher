import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    private var validCategories: [Category] {
        categories.filter { $0.isDefault == false }
    }

    let transaction: Transaction

    @State private var amountText: String
    @State private var desc: String
    @State private var date: Date
    @State private var selectedCategory: Category?

    @AppStorage(CurrencySettings.key, store: CurrencySettings.store) private var currencyCode = CurrencySettings.defaultCode

    init(transaction: Transaction) {
        self.transaction = transaction
        _amountText = State(initialValue: String(transaction.amount))
        _desc = State(initialValue: transaction.desc)
        _date = State(initialValue: transaction.date)
        _selectedCategory = State(initialValue: transaction.category)
    }

    private var isValid: Bool {
        guard let value = Double(amountText) else { return false }
        return value > 0
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
                    TextField("Description (optional)", text: $desc)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
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
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard let amount = Double(amountText), amount > 0 else { return }
        transaction.amount = amount
        transaction.desc = desc
        transaction.date = date
        transaction.category = selectedCategory
        dismiss()
    }
}

#Preview {
    EditTransactionView(transaction: Transaction(amount: 12.5, desc: "Coffee", date: .now))
}
