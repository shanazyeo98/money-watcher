import SwiftUI
import SwiftData
import Charts

// @Query : wrapper that automatically fetches the objects stored in the database
// data is live and fetches automatically

struct HomeView: View {
    @Query(sort: \Category.name)
    private var categories: [Category]
    @Query private var transactions: [Transaction]
    
    private var date: Date {
        Date()
    }
    
    private var totalBudget: Double {
        categories.reduce(0.0) { $0 + $1.budgetAmount }
    }
    
    private var totalSpent: Double {
        transactions.reduce(0.0) { $0 + $1.amount }
    }
    
    private var overallProgress: Double {
        if totalBudget <= 0 && totalSpent > 0 { return 1.0 }
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }
    
    private var currencyCode: String = "AUD"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overallCard
                breakdownCard
                if categories.isEmpty {
                    emptyState
                } else {
                    categoryBreakdown
                }
            }
            .padding()
        }
        .navigationTitle("\(Text(date, format: .dateTime.month(.wide)))'s Overview")
    }
    
    private var overallCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Total Budget")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            
            HStack(alignment: .bottom, spacing: 6) {
                Text(totalSpent, format: .currency(code: currencyCode))
                    .font(.system(size: 34, weight: .bold))
                Text("of \(totalBudget.formatted(.currency(code: currencyCode)))")
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
                        .fill(overallProgress > 0.9 ? Color.red : Color.accentColor)
                        .frame(width: geo.size.width * overallProgress, height: 12)
                        .animation(.easeInOut, value: overallProgress)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(Int(overallProgress * 100))% used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let remaining = max(0, totalBudget - totalSpent)
                Text("\(remaining.formatted(.currency(code: currencyCode))) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown")
                .font(.headline)
                .foregroundStyle(.secondary)
            if transactions.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(categories) { item in
                    SectorMark(
                        angle: .value("Amount", item.totalSpent),
                        innerRadius: .ratio(0.75),
                        angularInset: 2.0
                    )
                    .foregroundStyle(by: .value("Category", item.name))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartForegroundStyleScale(domain: categories.map(\.name), range: categories.map(\.color))
                // domain - the values that appear in the chart
                // range - the color to use
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ForEach(categories) { category in
                CategoryProgressRow(category: category, currencyCode: currencyCode)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No categories yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Go to Settings to create your budget categories.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

struct CategoryProgressRow: View {
    let category: Category
    let currencyCode: String
    
    private var progress: Double {
        if category.budgetAmount <= 0 && category.totalSpent > 0 { return 1.0 }
        guard category.budgetAmount > 0 else { return 0 }
        return min(category.totalSpent / category.budgetAmount, 1.0)
    }
    
    private var isOverBudget: Bool { progress >= 1.0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(category.color)
                    .frame(width: 12, height: 12)
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(category.totalSpent.formatted(.currency(code: currencyCode))) / \(category.budgetAmount.formatted(.currency(code: currencyCode)))")
                    .font(.caption)
                    .foregroundStyle(isOverBudget ? .red : .secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOverBudget ? Color.red : category.color)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

#Preview {
    HomeView()
        .modelContainer(SampleData.preview)
}
