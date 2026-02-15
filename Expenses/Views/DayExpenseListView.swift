import SwiftUI

struct DayExpenseListView: View {
    let date: Date
    let expenses: [Expense]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(expenses) { expense in
                        HStack(spacing: 16) {
                            // Leading Icon
                            ZStack {
                                Image(systemName: expense.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(expense.color)
                                    .symbolRenderingMode(.hierarchical)
                            }
                            
                            // Title & Category
                            VStack(alignment: .leading, spacing: 4) {
                                Text(expense.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(expense.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // Amount & Time
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("₹" + expense.amount.formatted(.number.precision(.fractionLength(0...2))))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text(expense.date, format: .dateTime.hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
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
    }
}
