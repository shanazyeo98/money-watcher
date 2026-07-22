//
//  AddTransactionButton.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 7/7/26.
//

import SwiftUI

struct AddTransactionButton: View {
    var defaultTravel: Travel? = nil

    @State private var showingAddTransaction = false

    var body: some View {
        Button {
            showingAddTransaction = true
        } label: {
            Image(systemName: "plus")
        }
        .sheet(isPresented: $showingAddTransaction) {
            TransactionFormView(defaultTravel: defaultTravel)
        }
    }
}
