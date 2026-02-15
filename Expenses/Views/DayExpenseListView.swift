import SwiftUI

struct DayExpenseListView: View {
    let date: Date
    let expenses: [Expense]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var repository: ExpenseRepository
    @State private var expenseToEdit: Expense?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(expenses) { expense in
                        TransactionRow(expense: expense)
                            .onTapGesture {
                                expenseToEdit = expense
                            }
                    }
                    .onDelete(perform: deleteExpenses)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            }
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseView(expenseToEdit: expense)
                    .environmentObject(repository)
            }
        }
    
    private func deleteExpenses(at offsets: IndexSet) {
        offsets.forEach { index in
            let expenseToDelete = expenses[index]
            repository.delete(expense: expenseToDelete)
        }
    }
}
