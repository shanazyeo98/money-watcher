import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    private var validCategories: [Category] {
        categories.filter { !$0.isDefault }
    }
    
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    
    var body: some View {
        List {
            Section {
                if validCategories.isEmpty {
                    Text("No categories yet — tap + to add one.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(validCategories) { category in
                        CategorySettingsRow(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture { editingCategory = category }
                    }
                    .onDelete(perform: delete)
                }
            } header: {
                HStack {
                    Text("Budget Categories")
                    Spacer()
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            Section("Automation") {
                NavigationLink("Merchant Mappings") {
                    MerchantMappingsView()
                }
            }

            Section("Debug") {
                NavigationLink("Debug Logs") {
                    DebugLogView()
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
        .sheet(item: $editingCategory) { category in
            AddCategoryView(category: category)
        }
    }
    
    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

struct CategorySettingsRow: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(category.color)
                .frame(width: 14, height: 14)
            Text(category.name)
                .font(.body)
            Spacer()
            Text(category.budgetAmount, format: .currency(code: "USD"))
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(SampleData.preview)
}
