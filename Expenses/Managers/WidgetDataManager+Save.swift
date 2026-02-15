import Foundation
import WidgetKit

extension WidgetDataManager {
    // This extension exists only in the App Target because it relies on Expense (and Firebase)
    
    func save(expenses: [Expense]) {
        // HARDCODED APP GROUP ID - Match this with the one in the main class
        let suiteName = "group.com.adeshhemwani.Expenses"
        
        // 1. Calculate Current Month Total
        let calendar = Calendar.current
        let now = Date()
        let currentMonthExpenses = expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate(expense.date, equalTo: now, toGranularity: .year)
        }
        
        let total = currentMonthExpenses.reduce(0) { $0 + $1.amount }
        
        // 2. Prepare Graph Data (Cumulative)
        let range = calendar.range(of: .day, in: .month, for: now)!
        let days = range.count
        var dailyPoints: [Double] = Array(repeating: 0.0, count: days)
        
        // Fill daily stats
        for expense in currentMonthExpenses {
            let day = calendar.component(.day, from: expense.date)
            if day >= 1 && day <= days {
                dailyPoints[day - 1] += expense.amount
            }
        }
        
        // Convert to cumulative array
        var cumulativePoints: [Double] = []
        var runningTotal: Double = 0
        
        // We only want points up to today/now to avoid a flat line for the future
        let currentDay = calendar.component(.day, from: now)
        
        for i in 0..<min(currentDay, days) {
            runningTotal += dailyPoints[i]
            cumulativePoints.append(runningTotal)
        }
        
        // 3. Month Name
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: now).uppercased()
        
        // 4. Save
        let data = WidgetData(totalAmount: total, monthName: monthName, dailyPoints: cumulativePoints, lastUpdated: now)
        
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults(suiteName: suiteName)?.set(encoded, forKey: "widgetData")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
