import SwiftUI
import FirebaseAuth
import FirebaseAuth

struct ExpenseListView: View {
    @EnvironmentObject var repository: ExpenseRepository
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    // Computed property for current month and year
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
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
    
    @State private var expenseToEdit: Expense?
    @State private var selectedFilter: Expense.ExpenseType? = nil // nil = All
    
    private var filteredExpenses: [Expense] {
        if let filter = selectedFilter {
            return repository.expenses.filter { $0.type == filter }
        }
        return repository.expenses
    }
    
    private var groupedExpenses: [TransactionGroup] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
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
                // Header Section
                // Header Section
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentMonthYear)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(.secondaryLabel))

                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text("₹" + formattedTotal.whole)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(Color(.label))
                            
                            Text(formattedTotal.fraction)
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        .contentTransition(.numericText())
                        
                        // Segregated Totals
                        HStack(spacing: 12) {
                            let regularTotal = repository.expenses.filter { $0.type == .regular && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.reduce(0) { $0 + $1.amount }
                            let oneOffTotal = repository.expenses.filter { $0.type == .oneOff && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.reduce(0) { $0 + $1.amount }
                            
                            HStack(spacing: 4) {
                                Circle().fill(Theme.getAccentColor()).frame(width: 6, height: 6)
                                Text("Regular: ₹\(Int(regularTotal))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Circle().fill(Color.orange).frame(width: 6, height: 6)
                                Text("One-off: ₹\(Int(oneOffTotal))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.bottom, 4)
                        .contentTransition(.numericText())
                        
                        if let percentage = repository.monthOverMonthPercentage {
                            HStack(spacing: 4) {
                                Image(systemName: percentage > 0 ? "arrow.up" : "arrow.down")
                                Text("\(abs(Int(percentage)))% compared to last month")
                            }
                            .font(.subheadline)
                            // Red for negative impact (spending increase), Green for positive impact (spending decrease)
                            .foregroundStyle(percentage > 0 ? Color(.systemRed) : Color(.systemGreen))
                            .onTapGesture {
                                navigationManager.navigate(to: .insights, scrollTo: "MonthComparison")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .listRowBackground(Color.clear)
                    // Filter
                    Picker("Filter by Type", selection: $selectedFilter) {
                        Text("All").tag(Optional<Expense.ExpenseType>.none)
                        ForEach(Expense.ExpenseType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.palette)
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 0, trailing: 20))
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)    
                }
                
                // Transactions
                ForEach(groupedExpenses) { group in
                    Section {
                        ForEach(group.expenses) { expense in
                            TransactionRow(expense: expense)
                                .onTapGesture {
                                    expenseToEdit = expense
                                }
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
            .animation(.default, value: repository.expenses)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseView(expenseToEdit: expense)
                    .environmentObject(repository)
            }
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
            .environmentObject(NavigationManager())
    }
}
