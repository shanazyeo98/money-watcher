import SwiftUI
import SwiftData

struct MerchantMappingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MerchantMapping.key) private var mappings: [MerchantMapping]
    @Query private var categories: [Category]

    @State private var editingMapping: MerchantMapping?
    
    @State private var searchText = ""
    
    var filteredMappings: [MerchantMapping] {
        if searchText.isEmpty {
            return mappings
        } else {
            return mappings.filter {
                $0.key.localizedStandardContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            if !mappings.isEmpty && !filteredMappings.isEmpty {
                ForEach(filteredMappings) { mapping in
                    MerchantMappingRow(mapping: mapping, category: category(named: mapping.category))
                        .contentShape(Rectangle())
                        .onTapGesture { editingMapping = mapping }
                }
                .onDelete(perform: delete)
            }
        }
        .overlay {
            if mappings.isEmpty {
                Text("No merchant mappings yet — they're created automatically as expenses are categorised.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else if filteredMappings.isEmpty {
                Text("No merchant mappings found")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .navigationTitle("Merchant Mappings")
        .sheet(item: $editingMapping) { mapping in
            EditMerchantMappingView(mapping: mapping)
        }
        .searchable(text: $searchText)
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
    private var userCategories: [Category] {
        categories.filter { !$0.isDefault }
    }

    let mapping: MerchantMapping

    @State private var selectedCategory: String
    @State private var rawNames: [String]
    @State private var newRawName: String = ""

    init(mapping: MerchantMapping) {
        self.mapping = mapping
        _selectedCategory = State(initialValue: mapping.category)
        _rawNames = State(initialValue: mapping.rawMerchantNames)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Merchant") {
                    Text(mapping.key.capitalized)
                        .font(.headline)
                }

                Section("Raw Names") {
                    ForEach($rawNames, id: \.self) { $name in
                        TextField("Raw name", text: $name)
                    }
                    .onDelete(perform: deleteRawName)

                    HStack {
                        TextField("Add raw name", text: $newRawName)
                        Button {
                            addRawName()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newRawName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(userCategories) { category in
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
        rawNames.remove(atOffsets: offsets)
    }

    private func addRawName() {
        let trimmed = newRawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        rawNames.append(trimmed)
        newRawName = ""
    }

    private func save() {
        mapping.category = selectedCategory
        mapping.rawMerchantNames = rawNames
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MerchantMappingsView()
            .modelContainer(SampleData.preview)
    }
}
