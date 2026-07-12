import SwiftUI
import SwiftData

struct MerchantMappingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MerchantMapping.key) private var mappings: [MerchantMapping]
    @Query private var categories: [Category]

    @State private var editingMapping: MerchantMapping?

    var body: some View {
        List {
            if mappings.isEmpty {
                Text("No merchant mappings yet — they're created automatically as expenses are categorised.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(mappings) { mapping in
                    MerchantMappingRow(mapping: mapping, category: category(named: mapping.category))
                        .contentShape(Rectangle())
                        .onTapGesture { editingMapping = mapping }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Merchant Mappings")
        .sheet(item: $editingMapping) { mapping in
            EditMerchantMappingView(mapping: mapping)
        }
    }

    private func category(named name: String) -> Category? {
        categories.first { $0.name == name }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(mappings[index])
        }
    }
}

private struct MerchantMappingRow: View {
    let mapping: MerchantMapping
    let category: Category?

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(category?.color ?? .gray)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(mapping.key.capitalized)
                    .font(.body)
                Text(mapping.rawMerchantNames.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(mapping.category)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct EditMerchantMappingView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    let mapping: MerchantMapping

    @State private var selectedCategory: String

    init(mapping: MerchantMapping) {
        self.mapping = mapping
        _selectedCategory = State(initialValue: mapping.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Merchant") {
                    Text(mapping.key.capitalized)
                        .font(.headline)
                    ForEach(mapping.rawMerchantNames, id: \.self) { name in
                        Text(name)
                            .foregroundStyle(.secondary)
                    }
                    .onDelete(perform: deleteRawName)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories) { category in
                            Text(category.name).tag(category.name)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Edit Mapping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func deleteRawName(_ offsets: IndexSet) {
        mapping.rawMerchantNames.remove(atOffsets: offsets)
    }

    private func save() {
        mapping.category = selectedCategory
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MerchantMappingsView()
            .modelContainer(SampleData.preview)
    }
}
