import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var repository: ExpenseRepository
    @EnvironmentObject var authManager: AuthManager
    
    // Data State
    @State private var currentMonthExpenses: [Expense] = []
    @State private var lastMonthExpenses: [Expense] = []
    @State private var isLoading = true
    
    // Constants
    private var budget: Double {
        authManager.appUser?.monthlyBudgetCap ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 1. Summary Card
                    SummaryCard(total: totalThisMonth, trend: trendPercentage)
                    
                    // 2. Budget Card
                    BudgetCard(total: totalThisMonth, budget: budget)
                    
                    // 3. Top Category Card
                    TopCategoryCard(expenses: currentMonthExpenses)
                    
                    // 4. Trends Card
                    TrendsCard(expenses: currentMonthExpenses)
                    
                    // 5. Highlights Card
                    HighlightsCard(total: totalThisMonth, budget: budget, trend: trendPercentage, expenses: currentMonthExpenses)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            // Use system grouped background color
            .background(Color(.systemGroupedBackground))
            .onAppear(perform: loadData)
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthID = formatMonth(now)
        
        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else { return }
        let lastMonthID = formatMonth(lastMonthDate)
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        // Note: fetchExpenses(forMonth:) limits might apply if repository doesn't fetch all
        // But assuming it fetches what's needed for the month
        repository.fetchExpenses(forMonth: currentMonthID) { expenses in
            currentMonthExpenses = expenses
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        repository.fetchExpenses(forMonth: lastMonthID) { expenses in
            lastMonthExpenses = expenses
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            isLoading = false
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
    
    // MARK: - Computed Metrics
    private var totalThisMonth: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var totalLastMonth: Double {
        lastMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var trendPercentage: Double {
        guard totalLastMonth > 0 else { return 0 }
        return ((totalThisMonth - totalLastMonth) / totalLastMonth) * 100
    }
}

// MARK: - 1. Summary Card
struct SummaryCard: View {
    let total: Double
    let trend: Double
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("This Month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("₹\(Int(total))")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText(value: total))
                    
                    Spacer()
                    
                    if trend != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            Text("\(abs(Int(trend)))% from last mo.")
                        }
                        .font(.caption)
                        // Prompt: "Positive -> .green, Negative -> .red"
                        .foregroundStyle(trend > 0 ? .green : .red)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(InsightCardStyle())
    }
}

// MARK: - 2. Budget Card
struct BudgetCard: View {
    let total: Double
    let budget: Double
    
    private var progress: Double {
        guard budget > 0 else { return 0 }
        return total / budget
    }
    
    private var isOverBudget: Bool {
        total > budget
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Monthly Budget")
                        .font(.headline)
                    Spacer()
                    Text("₹\(Int(budget))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .lastTextBaseline) {
                        Text("₹\(Int(total))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(isOverBudget ? .red : .primary)
                        
                        Text("spent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: min(progress, 1.0))
                        .tint(isOverBudget ? .red : .accentColor)
                    
                    if isOverBudget {
                        Text("Over budget by ₹\(Int(total - budget))")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("₹\(Int(budget - total)) remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .groupBoxStyle(InsightCardStyle())
    }
}

// MARK: - 3. Top Category Card
struct TopCategoryCard: View {
    let expenses: [Expense]
    
    private var categoryData: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (key, value) in
            (key, value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    
    private var topCategory: (name: String, amount: Double)? {
        guard let first = categoryData.first else { return nil }
        return (name: first.category, amount: first.amount)
    }
    
    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        GroupBox {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Category")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let top = topCategory {
                        Text(top.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("₹\(Int(top.amount))")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int((top.amount / totalAmount) * 100))% of spending")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    } else {
                        Text("No data")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if !categoryData.isEmpty {
                    DonutChartView(expenses: expenses, innerRadiusRatio: 0.6, angularInset: 2)
                        .frame(width: 140, height: 140)
                }
            }
        }
        .groupBoxStyle(InsightCardStyle())
    }
}

// MARK: - 4. Trends Card
struct TrendsCard: View {
    let expenses: [Expense]
    
    private var weeklyData: [(week: String, amount: Double)] {
        let calendar = Calendar.current
        var weeks: [Int: Double] = [:]
        
        for expense in expenses {
            // weekOfMonth returns 1...5 typically
            let week = calendar.component(.weekOfMonth, from: expense.date)
            weeks[week, default: 0] += expense.amount
        }
        
        return weeks.sorted(by: { $0.key < $1.key }).map { (week, amount) in
            ("W\(week)", amount)
        }
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Text("Weekly Spending")
                    .font(.headline)
                
                if !weeklyData.isEmpty {
                    Chart(weeklyData, id: \.week) { item in
                        BarMark(
                            x: .value("Week", item.week),
                            y: .value("Amount", item.amount)
                        )
                        .cornerRadius(6)
                        .foregroundStyle(.blue) // No gradient
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text("\(Int(amount) / 1000)k")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                } else {
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(height: 180, alignment: .center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .groupBoxStyle(InsightCardStyle())
    }
}

// MARK: - 5. Highlights Card
struct HighlightsCard: View {
    let total: Double
    let budget: Double
    let trend: Double
    let expenses: [Expense]
    
    private var topCategory: String? {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let stats = grouped.map { (key, value) in
            (key, value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.1 > $1.1 }
        return stats.first?.0
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Highlights")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                if total > budget {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.red)
                        Text("You exceeded your budget")
                    }
                    .font(.subheadline)
                }
                
                if trend > 0 {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.red)
                        Text("Spending increased \(Int(abs(trend)))% from last month")
                    }
                    .font(.subheadline)
                } else if trend < 0 {
                    HStack {
                        Image(systemName: "arrow.down.right")
                            .foregroundStyle(.green)
                        Text("Spending decreased \(Int(abs(trend)))% from last month")
                    }
                    .font(.subheadline)
                }
                
                if let top = topCategory {
                    HStack {
                        Image(systemName: "cart")
                            .foregroundStyle(.secondary)
                        Text("\(top) accounts for most spending")
                    }
                    .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(InsightCardStyle())
    }
}

// MARK: - Custom Style
struct InsightCardStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    InsightsView()
        .environmentObject(ExpenseRepository(userId: "preview"))
}
