import SwiftUI
import SwiftData
import Charts

// @Query : wrapper that automatically fetches the objects stored in the database
// data is live and fetches automatically

struct HomeView: View {
    @Query(sort: \Category.name)
    private var categories: [Category]
    @Query private var transactions: [Transaction]

    @State private var selectedMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var showMonthPicker = false
    @State private var selectedDay: Date?

    private var monthTransactions: [Transaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var heatmapTransactions: [Transaction] {
        monthTransactions.filter { $0.travel == nil }
    }

    private var dailyTotals: [Date: Double] {
        Dictionary(grouping: heatmapTransactions) { Calendar.current.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0.0) { $0 + $1.amount } }
    }

    private var maxDailyTotal: Double {
        dailyTotals.values.max() ?? 0
    }

    private var calendarCells: [Date?] {
        let calendar = Calendar.current
        guard
            let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth),
            let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        let days: [Date?] = monthRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }

        return Array(repeating: nil, count: leadingBlanks) + days
    }

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let startIndex = calendar.firstWeekday - 1
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    private var totalBudget: Double {
        categories.reduce(0.0) { $0 + $1.budgetAmount }
    }

    private var totalSpent: Double {
        monthTransactions.reduce(0.0) { $0 + $1.amount }
    }

    private var overallProgress: Double {
        if totalBudget <= 0 && totalSpent > 0 { return 1.0 }
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }

    @AppStorage(CurrencySettings.key, store: CurrencySettings.store) private var currencyCode = CurrencySettings.defaultCode

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overallCard
                breakdownCard
                spendingActivityCard
                if categories.isEmpty {
                    emptyState
                } else {
                    categoryBreakdown
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                monthSelector
            }
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthYearPickerView(selectedMonth: $selectedMonth)
        }
        .onChange(of: selectedMonth) {
            selectedDay = nil
        }
    }

    private var monthSelector: some View {
        HStack(spacing: 18) {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Button {
                showMonthPicker = true
            } label: {
                Text(selectedMonth, format: .dateTime.month(.wide).year())
                    .fontWeight(.semibold)
            }

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(.primary)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func spent(for category: Category) -> Double {
        monthTransactions
            .filter { $0.category?.persistentModelID == category.persistentModelID }
            .reduce(0.0) { $0 + $1.amount }
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
            if monthTransactions.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(categories) { item in
                    SectorMark(
                        angle: .value("Amount", spent(for: item)),
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

    private var spendingActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Activity")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(calendarCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            date: day,
                            amount: dailyTotals[day] ?? 0,
                            maxAmount: maxDailyTotal,
                            selectedDay: $selectedDay
                        )
                    } else {
                        Color.clear
                            .frame(height: 28)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDay = nil
        }
        .overlayPreferenceValue(DayCellAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if let selectedDay, let anchor = anchors[selectedDay] {
                    let rect = proxy[anchor]
                    dayTooltip(for: selectedDay)
                        .position(x: rect.midX, y: rect.minY - 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func dayTooltip(for day: Date) -> some View {
        Text("\(day.formatted(.dateTime.month(.abbreviated).day())) · \((dailyTotals[day] ?? 0).formatted(.currency(code: currencyCode)))")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(categories) { category in
                CategoryProgressRow(category: category, spent: spent(for: category), currencyCode: currencyCode)
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
    let spent: Double
    let currencyCode: String

    private var progress: Double {
        if category.budgetAmount <= 0 && spent > 0 { return 1.0 }
        guard category.budgetAmount > 0 else { return 0 }
        return min(spent / category.budgetAmount, 1.0)
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
                Text("\(spent.formatted(.currency(code: currencyCode))) / \(category.budgetAmount.formatted(.currency(code: currencyCode)))")
                    .font(.caption)
                    .foregroundStyle(isOverBudget ? .red : .secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.color)
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

struct DayCellAnchorKey: PreferenceKey {
    static var defaultValue: [Date: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Date: Anchor<CGRect>], nextValue: () -> [Date: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct DayCell: View {
    let date: Date
    let amount: Double
    let maxAmount: Double
    @Binding var selectedDay: Date?

    private var isSelected: Bool {
        selectedDay.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
    }

    private var intensity: Double {
        guard maxAmount > 0, amount > 0 else { return 0 }
        return amount / maxAmount
    }

    private var fillColor: Color {
        switch intensity {
        case 0: Color(.systemGray5)
        case ..<0.2: Color.accentColor.opacity(0.2)
        case ..<0.4: Color.accentColor.opacity(0.4)
        case ..<0.6: Color.accentColor.opacity(0.6)
        case ..<0.8: Color.accentColor.opacity(0.8)
        default: Color.accentColor
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(fillColor)
            .frame(height: 28)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary, lineWidth: 1.5)
                }
            }
            .onTapGesture {
                selectedDay = isSelected ? nil : date
            }
            .anchorPreference(key: DayCellAnchorKey.self, value: .bounds) { anchor in
                isSelected ? [date: anchor] : [:]
            }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(SampleData.preview)
}
