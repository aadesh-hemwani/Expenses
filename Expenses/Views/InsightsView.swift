import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var repository: ExpenseRepository
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationManager: NavigationManager
    
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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) { // Increased vertical spacing (16 -> 24)
                        // 1. Summary Card
                        SummaryCard(total: totalThisMonth, trend: trendPercentage)
                        
                        // 2. Budget Card
                        BudgetCard(total: totalThisMonth, budget: budget)
                        
                        // 3. Top Category Card
                        TopCategoryCard(expenses: currentMonthExpenses)
                        
                        // 4. Trends Card (Weekly)
                        TrendsCard(expenses: currentMonthExpenses)
                        
                        // 5. Month Comparison Card
                        MonthComparisonCard(currentExpenses: currentMonthExpenses, lastMonthExpenses: lastMonthExpenses)
                            .id("MonthComparison")

                        // 6. Type Distribution Card
                         TypeDistributionCard(expenses: currentMonthExpenses)

                        // 7. Highlights Card - Updated style
                         HighlightsCard(total: totalThisMonth, budget: budget, trend: trendPercentage, expenses: currentMonthExpenses)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
                .onChange(of: navigationManager.scrollToId) { _, newValue in
                    if let id = newValue {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .center)
                        }
                        navigationManager.scrollToId = nil
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground)) // Native background
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("This Month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("₹\(Int(total))")
                    .font(.largeTitle) // Increased size
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: total))
                
                if trend != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
                            .fontWeight(.semibold)
                        Text("\(abs(Int(trend)))% from last month")
                    }
                    .font(.subheadline)
                    .foregroundStyle(trend > 0 ? Color(.systemRed) : Color(.systemGreen)) // Red for spending increase
                } else {
                    Text("No change from last month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Budget")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .lastTextBaseline) {
                    Text("₹\(Int(total))")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(isOverBudget ? Color(.systemRed) : .primary)
                    
                    Text("of ₹\(Int(budget))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                
                ProgressView(value: min(progress, 1.0))
                    .tint(isOverBudget ? Color(.systemRed) : Theme.getAccentColor()) // Use Theme color for normal state
                    .scaleEffect(x: 1, y: 1.5, anchor: .center) // Slightly thicker track
            }
            
            HStack {
                if isOverBudget {
                    Text("Over budget by ₹\(Int(total - budget))")
                        .foregroundStyle(Color(.systemRed))
                } else {
                    Text("₹\(Int(budget - total)) remaining")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .font(.footnote)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Top Category")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let top = topCategory {
                    Text(top.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("₹\(Int(top.amount))")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text("\(Int((top.amount / totalAmount) * 100))% of spending")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                } else {
                    Text("No data")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            Spacer()
            
            if !categoryData.isEmpty {
                DonutChartView(expenses: expenses, innerRadiusRatio: 0.65, angularInset: 4, showCenterText: false)
                    .frame(width: 120, height: 120) // Smaller donut
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - 4. Trends Card
// MARK: - 4. Trends Card
struct TrendsCard: View {
    let expenses: [Expense]
    @EnvironmentObject var repository: ExpenseRepository
    
    @State private var selectedTimeFrame: TimeFrame = .daily
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        
        var id: String { rawValue }
    }
    
    // Daily: 1..31
    private var dailyData: [(day: String, amount: Double)] {
        let calendar = Calendar.current
        var days: [Int: Double] = [:]
        
        // Initialize all days up to today (or end of month) with 0?
        // Let's just show days that have expenses or all days in month?
        // Better to show trends, so let's sparse map it first.
        
        for expense in expenses {
            let day = calendar.component(.day, from: expense.date)
            days[day, default: 0] += expense.amount
        }
        
        return days.sorted(by: { $0.key < $1.key }).map { (day, amount) in
            ("\(day)", amount)
        }
    }
    
    // Weekly: W1..W5
    private var weeklyData: [(week: String, amount: Double)] {
        let calendar = Calendar.current
        var weeks: [Int: Double] = [:]
        
        for expense in expenses {
            let week = calendar.component(.weekOfMonth, from: expense.date)
            weeks[week, default: 0] += expense.amount
        }
        
        return weeks.sorted(by: { $0.key < $1.key }).map { (week, amount) in
            ("W\(week)", amount)
        }
    }
    
    // Monthly: Jan..Dec (from repository.allStats)
    private var monthlyData: [(month: String, amount: Double)] {
        // Take last 6 months
        let stats = repository.allStats.prefix(6).reversed()
        
        return stats.map { stat in
            let monthID = stat.id ?? ""
            let components = monthID.split(separator: "-")
            var label = monthID
            if components.count == 2 {
                // components[1] is month number
                if let monthInt = Int(components[1]) {
                    let formatter = DateFormatter()
                    label = formatter.shortMonthSymbols[monthInt - 1]
                }
            }
            return (label, stat.total)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Spending Trends")
                    .font(.headline)
                Spacer()
            }
            
            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(TimeFrame.allCases) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
            
            Group {
                switch selectedTimeFrame {
                case .daily:
                    if !dailyData.isEmpty {
                        Chart(dailyData, id: \.day) { item in
                            BarMark(
                                x: .value("Day", item.day),
                                y: .value("Amount", item.amount)
                            )
                            .cornerRadius(4)
                            .foregroundStyle(Theme.getAccentColor())
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 10))
                        }
                    } else {
                        NoDataView()
                    }
                case .weekly:
                    if !weeklyData.isEmpty {
                        Chart(weeklyData, id: \.week) { item in
                            BarMark(
                                x: .value("Week", item.week),
                                y: .value("Amount", item.amount)
                            )
                            .cornerRadius(6)
                            .foregroundStyle(Theme.getAccentColor())
                        }
                    } else {
                        NoDataView()
                    }
                case .monthly:
                    if !monthlyData.isEmpty {
                        Chart(monthlyData, id: \.month) { item in
                            BarMark(
                                x: .value("Month", item.month),
                                y: .value("Amount", item.amount)
                            )
                            .cornerRadius(6)
                            .foregroundStyle(Theme.getAccentColor())
                        }
                    } else {
                        NoDataView()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("\(Int(amount) / 1000)k")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct NoDataView: View {
    var body: some View {
        Text("No data available")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(height: 200, alignment: .center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - 5. Highlights Card (Updated Style)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
                .padding(.bottom, 4)
            
            if total > budget {
                HighlightRow(icon: "exclamationmark.circle", color: .red, text: "You exceeded your budget")
            }
            
            if trend > 0 {
                HighlightRow(icon: "arrow.up.right", color: Color(.systemRed), text: "Spending increased \(Int(abs(trend)))%")
            } else if trend < 0 {
                HighlightRow(icon: "arrow.down.right", color: Color(.systemGreen), text: "Spending decreased \(Int(abs(trend)))%")
            }
            
            if let top = topCategory {
                HighlightRow(icon: "cart", color: .secondary, text: "\(top) accounts for most spending")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - 6. Month Comparison Card
struct MonthComparisonCard: View {
    let currentExpenses: [Expense]
    let lastMonthExpenses: [Expense]
    
    private var comparisonData: [(day: Int, amount: Double, type: String)] {
        let calendar = Calendar.current
        var data: [(day: Int, amount: Double, type: String)] = []
        
        // Helper to calculate cumulative
        func getCumulative(expenses: [Expense], type: String) -> [(Int, Double, String)] {
            var dailyMap: [Int: Double] = [:]
            for expense in expenses {
                let day = calendar.component(.day, from: expense.date)
                dailyMap[day, default: 0] += expense.amount
            }
            
            var result: [(Int, Double, String)] = []
            var currentTotal: Double = 0
            
            // Iterate 1...31
            for day in 1...31 {
                if let amount = dailyMap[day] {
                    currentTotal += amount
                    result.append((day, currentTotal, type))
                } else if !result.isEmpty {
                     // Carry forward previous total for days with no expenses
                     // But only if we have started tracking (don't pre-fill 0s if month hasn't started?)
                     // Actually for cumulative graph, we usually start at 0 and go up.
                     // But if data is sparse, line chart interpolates.
                     // Better to have a point for every day so the line is stepped or continuous correctly.
                     result.append((day, currentTotal, type))
                }
            }
            return result
        }
        
        let currentMonthData = getCumulative(expenses: currentExpenses, type: "Current")
        let lastMonthData = getCumulative(expenses: lastMonthExpenses, type: "Last Month")
        
        // Filter current month data to not exceed today?
        // Or just show what we have.
        // Let's limit current month to today's day to avoid flat line into future
        let today = calendar.component(.day, from: Date())
        let filteredCurrent = currentMonthData.filter { $0.0 <= today }
        
        return filteredCurrent + lastMonthData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Month Comparison")
                .font(.headline)
            
            Chart(comparisonData, id: \.day) { item in
                LineMark(
                    x: .value("Day", item.day),
                    y: .value("Cumulative", item.amount)
                )
                .foregroundStyle(by: .value("Type", item.type))
                .lineStyle(StrokeStyle(lineWidth: 3, dash: item.type == "Last Month" ? [5, 5] : []))
            }
            .chartForegroundStyleScale([
                "Current": Theme.getAccentColor(),
                "Last Month": Color(.secondaryLabel)
            ])
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 10))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("\(Int(amount) / 1000)k")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            
            HStack {
                Circle()
                    .fill(Theme.getAccentColor())
                    .frame(width: 8, height: 8)
                Text("Current")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Circle()
                    .fill(Color(.secondaryLabel))
                    .frame(width: 8, height: 8)
                Text("Last Month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct HighlightRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}


// MARK: - 7. Type Distribution Card
struct TypeDistributionCard: View {
    let expenses: [Expense]
    
    private var regularTotal: Double {
        expenses.filter { $0.type == .regular }.reduce(0) { $0 + $1.amount }
    }
    
    private var oneOffTotal: Double {
        expenses.filter { $0.type == .oneOff }.reduce(0) { $0 + $1.amount }
    }
    
    private var total: Double {
        regularTotal + oneOffTotal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Structure")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Charts
                Chart {
                    if total > 0 {
                        SectorMark(
                            angle: .value("Amount", regularTotal),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Theme.getAccentColor())
                        .cornerRadius(4)
                        
                        SectorMark(
                            angle: .value("Amount", oneOffTotal),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.orange)
                        .cornerRadius(4)
                    } else {
                        // Placeholder if no data
                        SectorMark(
                            angle: .value("Amount", 1),
                            innerRadius: .ratio(0.6),
                            angularInset: 0
                        )
                        .foregroundStyle(Color(.systemGray5))
                    }
                }
                .frame(width: 100, height: 100)
                
                // Legend / Data
                VStack(alignment: .leading, spacing: 12) {
                    // Regular
                    HStack {
                         Circle().fill(Theme.getAccentColor()).frame(width: 8, height: 8)
                         VStack(alignment: .leading, spacing: 2) {
                             Text("Regular")
                                 .font(.caption)
                                 .foregroundStyle(.secondary)
                             Text("₹\(Int(regularTotal))")
                                 .font(.headline)
                         }
                    }
                    
                    // One-off
                    HStack {
                         Circle().fill(Color.orange).frame(width: 8, height: 8)
                         VStack(alignment: .leading, spacing: 2) {
                             Text("One-off")
                                 .font(.caption)
                                 .foregroundStyle(.secondary)
                             Text("₹\(Int(oneOffTotal))")
                                 .font(.headline)
                         }
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    InsightsView()
        .environmentObject(ExpenseRepository(userId: "preview"))
        .environmentObject(AuthManager())
        .environmentObject(NavigationManager())
}
