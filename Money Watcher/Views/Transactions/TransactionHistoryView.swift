import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    var body: some View {
        Group {
            if transactions.isEmpty {
                emptyState
            } else {
                transactionList
            }
        }
        .navigationTitle("Transactions")
    }
    
    private var transactionList: some View {
        List {
            ForEach(transactions) { transaction in
                TransactionRow(transaction: transaction)
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
    
    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(transactions[index])
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
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
                Text(transaction.amount, format: .currency(code: "USD"))
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
