import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var editingTransaction: Transaction?

    @State private var searchText = ""
    @State private var selectedCategories: Set<Category> = []
    @State private var isDateFilterEnabled = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var endDate: Date = .now
    @State private var showFilterSheet = false

    private var dateRange: ClosedRange<Date>? {
        guard isDateFilterEnabled else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: endDate)) ?? endDate
        guard start <= end else { return nil }
        return start...end
    }

    private var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || isDateFilterEnabled
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            let matchesSearch = searchText.isEmpty
                || transaction.desc.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategories.isEmpty
                || (transaction.category.map { selectedCategories.contains($0) } ?? false)

            let matchesDate = dateRange.map { $0.contains(transaction.date) } ?? true

            return matchesSearch && matchesCategory && matchesDate
        }
    }

    var body: some View {
        Group {
            if transactions.isEmpty {
                emptyState
            } else if filteredTransactions.isEmpty {
                noResultsState
            } else {
                transactionList
            }
        }
        .navigationTitle("Transactions")
        .searchable(text: $searchText, prompt: "Search transactions")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            TransactionFilterView(
                categories: categories,
                selectedCategories: $selectedCategories,
                isDateFilterEnabled: $isDateFilterEnabled,
                startDate: $startDate,
                endDate: $endDate
            )
        }
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(transaction: transaction)
        }
    }

    private var transactionList: some View {
        List {
            ForEach(filteredTransactions) { transaction in
                TransactionRow(transaction: transaction)
                    .contentShape(Rectangle())
                    .onTapGesture { editingTransaction = transaction }
            }
            .onDelete(perform: delete)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No transactions yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap + to log your first expense.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No matching transactions")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTransactions[index])
        }
    }
}

struct TransactionFilterView: View {
    let categories: [Category]
    @Binding var selectedCategories: Set<Category>
    @Binding var isDateFilterEnabled: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Categories") {
                    if categories.isEmpty {
                        Text("No categories yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories) { category in
                            Button {
                                toggle(category)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 10, height: 10)
                                    Text(category.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedCategories.contains(category) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Date Range") {
                    Toggle("Filter by Date", isOn: $isDateFilterEnabled.animation())
                    if isDateFilterEnabled {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        selectedCategories.removeAll()
                        isDateFilterEnabled = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ category: Category) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    @AppStorage(CurrencySettings.key, store: CurrencySettings.store) private var currencyCode = CurrencySettings.defaultCode

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(transaction.category?.color ?? Color(.systemGray3))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.desc.isEmpty ? "No description" : transaction.desc)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.category?.name ?? "Uncategorized")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(transaction.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TransactionHistoryView()
        .modelContainer(SampleData.preview)
}
