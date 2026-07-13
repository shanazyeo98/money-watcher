import SwiftUI
import SwiftData

struct RecurringTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringTransaction.latestOccurence, order: .reverse) private var recurringTransactions: [RecurringTransaction]

    @State private var editingTransaction: RecurringTransaction?

    var body: some View {
        List {
            if !recurringTransactions.isEmpty {
                ForEach(recurringTransactions) { transaction in
                    RecurringTransactionRow(transaction: transaction)
                        .contentShape(Rectangle())
                        .onTapGesture { editingTransaction = transaction }
                }
                .onDelete(perform: delete)
            }
        }
        .overlay {
            if recurringTransactions.isEmpty {
                Text("No recurring transactions yet — mark a transaction as recurring when adding it.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .navigationTitle("Recurring Transactions")
        .sheet(item: $editingTransaction) { transaction in
            EditRecurringTransactionView(transaction: transaction)
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recurringTransactions[index])
        }
    }
}

private struct RecurringTransactionRow: View {
    let transaction: RecurringTransaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(transaction.category?.color ?? .gray)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.desc.isEmpty ? "(No description)" : transaction.desc)
                    .font(.body)
                Text(transaction.frequency.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(transaction.amount, format: .currency(code: "USD"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct EditRecurringTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]
    private var userCategories: [Category] {
        categories.filter { !$0.isDefault }
    }

    let transaction: RecurringTransaction

    @State private var desc: String
    @State private var amountText: String
    @State private var selectedCategory: Category?
    @State private var frequency: Recurrence
    @State private var latestOccurence: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    init(transaction: RecurringTransaction) {
        self.transaction = transaction
        _desc = State(initialValue: transaction.desc)
        _amountText = State(initialValue: String(transaction.amount))
        _selectedCategory = State(initialValue: transaction.category)
        _frequency = State(initialValue: transaction.frequency)
        _latestOccurence = State(initialValue: transaction.latestOccurence)
        _hasEndDate = State(initialValue: transaction.endDate != nil)
        _endDate = State(initialValue: transaction.endDate ?? Date())
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
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Details") {
                    TextField("Description (optional)", text: $desc)
                    DatePicker("Latest Occurrence", selection: $latestOccurence, displayedComponents: .date)
                }

                Section("Recurrence") {
                    Picker("Recurrence", selection: $frequency) {
                        ForEach(Recurrence.allCases, id: \.self) { option in
                            Text(option.description).tag(option)
                        }
                    }
                    Toggle("Has End Date?", isOn: $hasEndDate.animation())
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(userCategories) { category in
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

                Section {
                    Button("Delete Recurring Transaction", role: .destructive) {
                        delete()
                    }
                }
            }
            .navigationTitle("Edit Recurring Transaction")
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
        transaction.desc = desc
        transaction.amount = amount
        transaction.category = selectedCategory
        transaction.frequency = frequency
        transaction.latestOccurence = latestOccurence
        transaction.endDate = hasEndDate ? endDate : nil
        dismiss()
    }

    private func delete() {
        modelContext.delete(transaction)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecurringTransactionsView()
            .modelContainer(SampleData.preview)
    }
}
