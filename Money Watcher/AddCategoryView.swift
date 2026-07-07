import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var category: Category?

    @State private var name = ""
    @State private var budgetText = ""
    @State private var selectedColor = "blue"

    private var isEditing: Bool { category != nil }

    private var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let value = Double(budgetText) else { return false }
        return value >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Groceries", text: $name)
                }

                Section("Monthly Budget") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $budgetText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Colour") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 5),
                        spacing: 16
                    ) {
                        ForEach(Category.colorOptions, id: \.self) { colorName in
                            colorSwatch(colorName)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    @ViewBuilder
    private func colorSwatch(_ colorName: String) -> some View {
        ZStack {
            Circle()
                .fill(Category.color(for: colorName))
                .frame(width: 40, height: 40)
            if selectedColor == colorName {
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
        }
        .onTapGesture { selectedColor = colorName }
    }

    private func populateIfEditing() {
        guard let category else { return }
        name = category.name
        budgetText = String(category.budgetAmount)
        selectedColor = category.colorName
    }

    private func save() {
        guard isValid, let amount = Double(budgetText) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let category {
            category.name = trimmed
            category.colorName = selectedColor
            category.budgetAmount = amount
        } else {
            modelContext.insert(Category(name: trimmed, colorName: selectedColor, budgetAmount: amount))
        }
        dismiss()
    }
}
