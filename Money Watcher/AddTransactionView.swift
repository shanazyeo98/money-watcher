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
            .task {
                selectedCategory = categories.first { $0.isDefault }
            }
        }
    }

    private func save() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let transaction = Transaction(amount: amount, desc: desc, date: date, category: selectedCategory)
        modelContext.insert(transaction)
        dismiss()
    }
}
