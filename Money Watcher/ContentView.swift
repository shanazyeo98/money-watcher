import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            AddTransactionButton()
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationStack {
                TransactionHistoryView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            AddTransactionButton()
                        }
                    }
                
            }
            .tabItem {
                Label("Transactions", systemImage: "list.bullet.rectangle.portrait")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, Transaction.self], inMemory: true)
}
