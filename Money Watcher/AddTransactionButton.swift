//
//  AddTransactionButton.swift
//  Money Watcher
//
//  Created by Shanaz Yeo on 7/7/26.
//

import SwiftUI

struct AddTransactionButton: View {
    @State private var showingAddTransaction = false
    
    var body: some View {
        Button {
            showingAddTransaction = true
        } label: {
            Image(systemName: "plus")
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }
}
