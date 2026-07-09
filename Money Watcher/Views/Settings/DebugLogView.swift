import SwiftUI
import SwiftData

struct DebugLogView: View {
    @Query(sort: \DebugLog.createdAt, order: .reverse) private var logs: [DebugLog]

    var body: some View {
        List {
            if logs.isEmpty {
                Text("No debug logs yet.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(logs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(log.merchant): \(log.name)")
                            .font(.body)
                        Text("Amount: \(log.amount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(log.createdAt, format: .dateTime)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle("Debug Logs")
    }
}

#Preview {
    NavigationStack {
        DebugLogView()
            .modelContainer(SampleData.preview)
    }
}
