import SwiftData
import Foundation

@MainActor
enum SampleData {
    static var preview: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Category.self, Transaction.self,
            configurations: config
        )
        let ctx = container.mainContext

        let food      = Category(name: "Groceries",  colorName: "green",  budgetAmount: 500)
        let dining    = Category(name: "Dining Out", colorName: "orange", budgetAmount: 200)
        let shopping  = Category(name: "Shopping",   colorName: "blue",   budgetAmount: 300)
        let transport = Category(name: "Transport",  colorName: "purple", budgetAmount: 150)
        [food, dining, shopping, transport].forEach { ctx.insert($0) }

        let txns: [(Double, String, Int, Category)] = [
            (82.50,  "Weekly shop",         0, food),
            (124.00, "Supermarket run",     3, food),
            (45.00,  "Dinner with friends", 1, dining),
            (28.00,  "Lunch",               5, dining),
            (199.00, "New shoes",           2, shopping),
            (35.00,  "Bus pass",            4, transport),
        ]
//        for (amount, desc, daysAgo, cat) in txns {
//            let t = Transaction(
//                amount: amount,
//                desc: desc,
//                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
//                category: cat
//            )
//            ctx.insert(t)
//        }

        return container
    }()
}
