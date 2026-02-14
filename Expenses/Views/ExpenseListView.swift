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
        VStack(spacing: 0) {
            // Custom Header
            VStack(alignment: .leading, spacing: 16) {
                Text(currentMonthYear)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(2)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                CreditCardView(
                    totalAmount: currentMonthTotal,
                    name: authManager.user?.displayName ?? "Guest User"
                )
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
            .background(Color.clear) // Clear background for card to stand out
            
            // Transaction List
            List {
                ForEach(groupedExpenses) { group in
                    Section(header: Text(group.title)) {
                        ForEach(group.expenses) { expense in
                            HStack(spacing: 12) {
                                // Category Icon
                                ZStack {
                                    Circle()
                                        .fill(expense.color.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: expense.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(expense.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.title)
                                        .font(.headline)
                                    Text(expense.category)
                                        .font(.caption) // Smaller font for category
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    // Amount with Rupee
                                    Text("₹" + expense.amount.formatted(.number.precision(.fractionLength(0...2))))
                                        .font(.headline)
                                        .fontWeight(.bold) // Bold amount
                                    
                                    // Time
                                    Text(expense.date, format: .dateTime.hour().minute())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            deleteExpenses(at: offsets, in: group)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("") // Remove default large title to use custom header
        .navigationBarTitleDisplayMode(.inline)
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
