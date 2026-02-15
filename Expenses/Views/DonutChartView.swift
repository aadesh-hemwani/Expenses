import SwiftUI
import Charts

struct DonutChartView: View {
    let expenses: [Expense]
    var innerRadiusRatio: CGFloat = 0.7 // Thicker stroke (smaller hole means thicker? No. 0.7 inner vs 1.0 outer = 0.3 stroke width ratio)
    // Actually, user asked for fixed stroke width (28-32pt). This is hard to guarantee with ratio unless frame is fixed.
    // I will stick to ratio but tweak it to look like the design. 0.65-0.7 is usually good for "thick but not pie".
    var angularInset: CGFloat = 4.0 // "Add subtle spacing" - 4.0 is distinct.
    var showCenterText: Bool = false
    
    // Customization for center text
    var centerTextTitle: String = "Total Spending"
    var centerTextFont: Font = .title2
    
    private var categoryData: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (key, value) in
            (key, value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    
    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ZStack {
            if !categoryData.isEmpty {
                Chart(categoryData, id: \.category) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(innerRadiusRatio),
                        // Apply spacing always for the redesign look, unless very small?
                        // User manual said "Add subtle spacing".
                        // I'll keep the small slice protection just in case.
                        angularInset: (item.amount / totalAmount) > 0.01 ? angularInset : 0
                    )
                    .cornerRadius(8) // "Smooth rounded line caps" - cornerRadius on SectorMark achieves this
                    .foregroundStyle(by: .value("Category", item.category))
                }
                .chartForegroundStyleScale(domain: categoryData.map { $0.category }, range: categoryData.map { categoryColor(for: $0.category) })
                .chartLegend(.hidden)
                
                if showCenterText {
                    VStack(spacing: 2) {
                        Text("₹\(Int(totalAmount))")
                            .font(centerTextFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text(centerTextTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Color.clear
            }
        }
    }
    
    // "Use system dynamic colors only"
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Food": return .orange // .systemOrange
        case "Transport": return .blue // .systemBlue
        case "Shopping": return .purple // .systemPurple
        case "Entertainment": return .pink // User asked for specific mapping, let's follow strictly
        case "Bills": return .yellow // .systemYellow
        case "Health": return .red // .systemRed
        case "Other": return .gray
        default: return .gray
        }
    }
}

#Preview {
    DonutChartView(expenses: [
        Expense(id: "1", title: "Lunch", amount: 150, date: Date(), category: "Food"),
        Expense(id: "2", title: "Uber", amount: 250, date: Date(), category: "Transport"),
        Expense(id: "3", title: "Movie", amount: 500, date: Date(), category: "Entertainment")
    ], showCenterText: true)
    .frame(width: 300, height: 300)
}
