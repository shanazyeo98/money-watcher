//
//  MoneyWatcherShortcuts.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 8/7/26.
//

import AppIntents

struct MoneyWatcherShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)"
            ],
            shortTitle: "Log expense",
            systemImageName: "dollarsign.circle"
        )
    }
}
