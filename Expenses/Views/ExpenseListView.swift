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
    private var currentMonthTotal: Double {
        let currentMonthExpenses = filteredExpenses.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        return currentMonthExpenses.reduce(0) { $0 + $1.amount }
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
                // Transactions
                ForEach(groupedExpenses) { group in
                    Section {
                        ForEach(group.expenses) { expense in
                            Button {
                                expenseToEdit = expense
                            } label: {
                                TransactionRow(expense: expense)
                            }
                            .buttonStyle(TransactionRowButtonStyle())
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
            .safeAreaInset(edge: .top, spacing: -90) {
                headerView()
            }
            .animation(.easeInOut, value: repository.expenses)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $selectedFilter.animation()) {
                            Text("All").tag(Optional<Expense.ExpenseType>.none)
                            ForEach(Expense.ExpenseType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(Optional(type))
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(selectedFilter == nil ? Color.primary : Color.accentColor)
                    }
                }
            }
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

    @ViewBuilder
    private func headerView() -> some View {
        let displayCornerRadius = UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0
        
        VStack(alignment: .center, spacing: 12) {
            Text(currentMonthYear)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Image(systemName: "indianrupeesign")
                    .font(.system(size: 28, weight: .thin))
                    .foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(formattedTotal.whole)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.primary)
                    .modifier(AnimatableNumberModifier(number: currentMonthTotal))
                    .animation(.easeInOut, value: currentMonthTotal)
                }
            }
            
            if let percentage = repository.monthOverMonthPercentage {
                HStack(spacing: 4) {
                    Image(systemName: percentage > 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(Int(percentage)))% vs last month today")
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(percentage > 0 ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                )
                .foregroundStyle(percentage > 0 ? Color.red : Color.green)
                .onTapGesture {
                    navigationManager.navigate(to: .insights, scrollTo: "MonthComparison")
                }.glassEffect(.clear)
            }
        }
        .padding(.bottom, 10)
        .padding(.top, 70)
        .frame(maxWidth: .infinity)
        .glassEffect(.clear, in: UnevenRoundedRectangle(topLeadingRadius: displayCornerRadius, bottomLeadingRadius: 30, bottomTrailingRadius: 30, topTrailingRadius: displayCornerRadius))
        .ignoresSafeArea(edges: .top)
    }
}

struct AnimatableNumberModifier: ViewModifier, Animatable {
    var number: Double
    
    var animatableData: Double {
        get { number }
        set { number = newValue }
    }
    
    func body(content: Content) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let totalString = formatter.string(from: NSNumber(value: number)) ?? "0.00"
        let parts = totalString.split(separator: ".")
        let whole = parts.count > 0 ? String(parts[0]) : "0"
        let fraction = parts.count > 1 ? "." + String(parts[1]) : ".00"
        
        return HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(whole)
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text(fraction)
                .font(.system(size: 46, weight: .thin))
                .foregroundStyle(.secondary)
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
