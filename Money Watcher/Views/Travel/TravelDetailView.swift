//
//  TravelDetailView.swift
//  Money Watcher
//

import SwiftUI
import SwiftData

struct TravelDetailView: View {
    let travel: Travel

    @Environment(\.modelContext) private var modelContext
    @State private var editingTransaction: Transaction?
    @State private var showingEditTravel = false

    private var sortedTransactions: [Transaction] {
        travel.transactions.sorted { $0.date > $1.date }
    }

    private var progress: Double {
        guard let budget = travel.budget else { return 0 }
        if budget <= 0 { return travel.totalSpent > 0 ? 1.0 : 0 }
        return min(travel.totalSpent / budget, 1.0)
    }

    var body: some View {
        List {
            Section {
                overviewCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Transactions") {
                if travel.transactions.isEmpty {
                    emptyStateRow
                } else {
                    ForEach(sortedTransactions) { transaction in
                        TravelTransactionRow(transaction: transaction, currencyCode: travel.currencyCode)
                            .contentShape(Rectangle())
                            .onTapGesture { editingTransaction = transaction }
                    }
                    .onDelete(perform: deleteTransaction)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(travel.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditTravel = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                AddTransactionButton(defaultTravel: travel)
            }
        }
        .sheet(item: $editingTransaction) { transaction in
            TransactionFormView(transaction: transaction)
        }
        .sheet(isPresented: $showingEditTravel) {
            AddTravelView(travel: travel)
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(travel.country.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(travel.startDate.formatted(date: .abbreviated, time: .omitted)) - \(travel.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let budget = travel.budget {
                HStack(alignment: .bottom, spacing: 6) {
                    Text(travel.totalSpent, format: .currency(code: travel.currencyCode))
                        .font(.system(size: 34, weight: .bold))
                    Text("of \(budget.formatted(.currency(code: travel.currencyCode)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 5)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(progress > 0.9 ? Color.red : Color.accentColor)
                            .frame(width: geo.size.width * progress, height: 12)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(Int(progress * 100))% used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    let remaining = max(0, budget - travel.totalSpent)
                    Text("\(remaining.formatted(.currency(code: travel.currencyCode))) remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Total spent")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(travel.totalSpent, format: .currency(code: travel.currencyCode))
                    .font(.system(size: 34, weight: .bold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var emptyStateRow: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No transactions yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Transactions tagged to this travel will appear here.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowSeparator(.hidden)
    }

    private func deleteTransaction(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedTransactions[index])
        }
    }
}

struct TravelTransactionRow: View {
    let transaction: Transaction
    let currencyCode: String

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
    let travel = Travel(
        name: "Japan Trip",
        startDate: .now,
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
        budget: 1000,
        country: Country(id: "JP", name: "Japan"),
        currencyCode: "JPY"
    )
    let txn1 = Transaction(amount: 4500, desc: "Ramen", date: .now, travel: travel)
    let txn2 = Transaction(amount: 12000, desc: "Hotel", date: .now, travel: travel)
    travel.transactions = [txn1, txn2]

    return NavigationStack {
        TravelDetailView(travel: travel)
    }
}
