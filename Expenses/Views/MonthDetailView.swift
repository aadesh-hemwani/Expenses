import SwiftUI
import Charts

struct MonthDetailView: View {
    let monthID: String // "yyyy-MM"
    let totalAmount: Double
    @EnvironmentObject var repository: ExpenseRepository
    @State private var expenses: [Expense] = []
    @State private var isLoading = true
    @State private var selectedDay: IdentifiableDate?
    @State private var expenseToEdit: Expense?
    @State private var selectedFilter: Expense.ExpenseType? = nil // nil = All
    
    // Calendar Grid Columns
    // Calendar Grid Columns
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    let weekDays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        List {
            // MARK: - Filter Section
            Section {
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
            
            // MARK: - Calendar Section
            Section {
                VStack(spacing: 12) {
                    // Weekday Header
                    HStack(spacing: 0) {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Days Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        // Offset for first day
                        ForEach(0..<firstDayOffset, id: \.self) { _ in
                            Color.clear
                        }
                        
                        // Days
                        ForEach(daysInMonth, id: \.date) { day in
                            VStack(spacing: 4) {
                                Text("\(day.dayNumber)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(isToday(day.date) ? .blue : .primary)
                                
                                if let amount = expensesByDay[day.dayNumber], amount > 0 {
                                    Text("₹\(Int(amount))")
                                        .font(.caption2)
                                        .foregroundStyle(amount > dailyAverage * 1.5 ? .primary : .secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } else {
                                    Text(" ") // Spacer to keep alignment
                                        .font(.caption2)
                                }
                            }
                            .frame(height: 50)
                            .contentShape(Rectangle()) // Make entire area tappable
                            .onTapGesture {
                                if let amount = expensesByDay[day.dayNumber], amount > 0 {
                                    selectedDay = IdentifiableDate(date: day.date)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            } header: {
                 Text("Calendar")
                    .font(.headline)
                    .foregroundStyle(.secondary) // Section header style
                    .textCase(nil)
            }

            // MARK: - Chart Section
            Section {
                VStack(spacing: 0) {
                    if !filteredExpenses.isEmpty {
                        DonutChartView(
                            expenses: filteredExpenses,
                            innerRadiusRatio: 0.7,
                            angularInset: 4,
                            showCenterText: true,
                            centerTextTitle: "Total Spending",
                            centerTextFont: .title2
                        )
                        .frame(height: 250)
                        .padding(.vertical, 20)
                    } else if isLoading {
                        ProgressView()
                            .frame(height: 250)
                    } else {
                        Text("No expenses found")
                            .foregroundStyle(.secondary)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            } header: {
                Text("Spending")
                    .font(.headline)
                    .foregroundStyle(.secondary) // Fixed .label to .secondary
                    .textCase(nil)
            }
            
            // MARK: - Category List
            Section {
                ForEach(categoryData) { item in
                    HStack(spacing: 16) {
                        // Circular Indicator
                        Circle()
                            .fill(categoryColor(for: item.category))
                            .frame(width: 10, height: 10)
                        
                        // Category Name
                        Text(item.category)
                            .font(.body)
                            .foregroundStyle(.primary) // Fixed .label to .primary
                        
                        Spacer()
                        
                        // Amount
                        Text("₹" + item.amount.formatted(.number.precision(.fractionLength(0...2))))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary) // Fixed .label to .primary
                        
                        // Chevron (implicit in NavigationLink, but adding Spacer creates look)
                        // List rows automatically have selection highlight
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Breakdown")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
            
            // MARK: - Transaction History
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
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(formatMonthTitle(monthID))
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedDay) { dateWrapper in
             DayExpenseListView(date: dateWrapper.date, expenses: expensesForDay(dateWrapper.date))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $expenseToEdit) { expense in
            AddExpenseView(expenseToEdit: expense)
                .environmentObject(repository)
        }
        .task {
            repository.fetchExpenses(forMonth: monthID) { fetchedExpenses in
                self.expenses = fetchedExpenses
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private func expensesForDay(_ date: Date) -> [Expense] {
        let calendar = Calendar.current
        return filteredExpenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    private var dateFromID: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: monthID) ?? Date()
    }
    
    private var daysInMonth: [(date: Date, dayNumber: Int)] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: dateFromID) else { return [] }
        
        // Ensure we start from the correct month's first day
        let components = calendar.dateComponents([.year, .month], from: dateFromID)
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        return range.compactMap { day -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            return (date, day)
        }
    }
    
    private var firstDayOffset: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: dateFromID)
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        // weekday returns 1 for Sunday, so subtract 1 to get 0-indexed offset (0=Sun, 1=Mon...)
        return calendar.component(.weekday, from: startOfMonth) - 1
    }
    
    private var expensesByDay: [Int: Double] {
        let calendar = Calendar.current
        var dict: [Int: Double] = [:]
        for expense in filteredExpenses {
            let day = calendar.component(.day, from: expense.date)
            dict[day, default: 0] += expense.amount
        }
        return dict
    }
    
    private var dailyAverage: Double {
        guard !expensesByDay.isEmpty else { return 0 }
        let total = expensesByDay.values.reduce(0, +)
        return total / Double(expensesByDay.count)
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func formatMonthTitle(_ id: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: id) {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return id
    }
    
    struct CategoryData: Identifiable {
        let id = UUID()
        let category: String
        let amount: Double
    }
    
    private var categoryData: [CategoryData] {
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        return grouped.map { CategoryData(category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Food": return .orange
        case "Transport": return .blue
        case "Shopping": return .purple
        case "Entertainment": return .pink
        case "Health": return .red
        case "Bills": return .yellow
        case "Other": return .gray
        default: return .blue
        }
    }
    
    // MARK: - Transaction Grouping
    
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
                formatter.dateFormat = "dd MMM" // Shorter date format for section headers inside a month view
                return formatter.string(from: date)
            }
        }
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
    
    private func deleteExpenses(at offsets: IndexSet, in group: TransactionGroup) {
        offsets.forEach { index in
            let expenseToDelete = group.expenses[index]
            repository.delete(expense: expenseToDelete)
            
            // Locally remove for immediate UI feedback (optional, since repository updates published expenses)
            if let index = expenses.firstIndex(where: { $0.id == expenseToDelete.id }) {
                expenses.remove(at: index)
            }
        }
    }
    
    private var filteredExpenses: [Expense] {
        guard let filter = selectedFilter else { return expenses }
        return expenses.filter { $0.type == filter }
    }
}

#Preview {
    NavigationStack {
        MonthDetailView(monthID: "2026-02", totalAmount: 5000)
            .environmentObject(ExpenseRepository(userId: "preview_user"))
    }
}
