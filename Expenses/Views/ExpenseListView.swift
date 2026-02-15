import SwiftUI
import FirebaseAuth
import FirebaseAuth

struct ExpenseListView: View {
    @EnvironmentObject var repository: ExpenseRepository
    @EnvironmentObject var authManager: AuthManager
    
    // Computed property for current month and year
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date()).uppercased()
    }
    
    // Computed property for total expenses of current month
    // Now using cached stats from Firestore via Repository
    private var currentMonthTotal: Double {
        return repository.currentMonthTotalAmount
    }
    
    // Format currency parts
    private var formattedTotal: (whole: String, fraction: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let totalString = formatter.string(from: NSNumber(value: currentMonthTotal)) ?? "0.00"
        let parts = totalString.split(separator: ".")
        
        if parts.count == 2 {
            return (String(parts[0]), "." + String(parts[1]))
        } else {
            return (totalString, ".00")
        }
    }
    
    // Grouping Logic
    struct TransactionGroup: Identifiable {
        let id = UUID()
        let date: Date
        let expenses: [Expense]
        
        var title: String {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd MMM yyyy"
                return formatter.string(from: date)
            }
        }
    }
    
    private var groupedExpenses: [TransactionGroup] {
        let grouped = Dictionary(grouping: repository.expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
        return grouped.map { (key, value) in
            TransactionGroup(date: key, expenses: value)
        }
        .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Header Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentMonthYear)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text("₹\(formattedTotal.whole)")
                                .font(.system(size: 40, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Text(formattedTotal.fraction)
                                .font(.system(size: 24, weight: .regular, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                        .contentTransition(.numericText())
                        
                        if let percentage = repository.monthOverMonthPercentage {
                            HStack(spacing: 4) {
                                Image(systemName: percentage > 0 ? "arrow.up.right" : "arrow.down.right")
                                Text("\(abs(Int(percentage)))% vs same time last month")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            // Red for increase (spending more), Green for decrease (spending less)
                            .foregroundStyle(percentage > 0 ? .red : .green)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // Transactions
                ForEach(groupedExpenses) { group in
                    Section {
                        ForEach(group.expenses) { expense in
                            HStack(spacing: 16) {
                                // Leading Icon
                                ZStack {
                                    Circle()
                                        .fill(expense.color.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: expense.icon)
                                        .font(.system(size: 18))
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
                        .onDelete { offsets in
                            deleteExpenses(at: offsets, in: group)
                        }
                    } header: {
                        Text(group.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .textCase(nil) // Prevent uppercase default
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Helper to delete from specific group
    private func deleteExpenses(at offsets: IndexSet, in group: TransactionGroup) {
        offsets.forEach { index in
            let expenseToDelete = group.expenses[index]
            repository.delete(expense: expenseToDelete)
        }
    }
}

#Preview {
    NavigationView {
        ExpenseListView()
            .environmentObject(ExpenseRepository(userId: "preview_user"))
            .environmentObject(AuthManager())
    }
}
