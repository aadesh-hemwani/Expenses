import WidgetKit
import SwiftUI
import Charts

struct MonthStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthStatsEntry {
        MonthStatsEntry(date: Date(), data: WidgetData(totalAmount: 12450.0, monthName: "FEBRUARY", dailyPoints: [1000, 2500, 3000, 5000, 7000, 8500, 10000, 12450], lastUpdated: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthStatsEntry) -> ()) {
        let data = WidgetDataManager.shared.load() ?? WidgetData(totalAmount: 0, monthName: "CURRENT", dailyPoints: [], lastUpdated: Date())
        let entry = MonthStatsEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthStatsEntry>) -> ()) {
        let data = WidgetDataManager.shared.load() ?? WidgetData(totalAmount: 0, monthName: "CURRENT", dailyPoints: [], lastUpdated: Date())
        let entry = MonthStatsEntry(date: Date(), data: data)
        
        // Refresh every 15 minutes or when app flushes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct MonthStatsEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct MonthStatsWidgetEntryView : View {
    var entry: MonthStatsProvider.Entry

    var body: some View {
        HStack(alignment: .bottom) {
            // Left Side: Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.data.monthName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(formatCurrency(entry.data.totalAmount))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
                Text("Updated \(entry.date, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right Side: Minimal Trend Graph
            if !entry.data.dailyPoints.isEmpty {
                Chart {
                    ForEach(Array(entry.data.dailyPoints.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Amount", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                        AreaMark(
                            x: .value("Day", index),
                            y: .value("Amount", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(width: 120) // Fixed width for graph
            } else {
                // Empty State
                 VStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No Data")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 120)
            }
        }
        .padding()
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}

struct MonthStatsWidget: Widget {
    let kind: String = "MonthStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthStatsProvider()) { entry in
            MonthStatsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monthly Trend")
        .description("Track your current month spending.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    MonthStatsWidget()
} timeline: {
    MonthStatsEntry(date: .now, data: WidgetData(totalAmount: 18450.50, monthName: "FEBRUARY", dailyPoints: [0, 500, 1500, 2000, 5000, 6500, 12000, 15000, 18450], lastUpdated: .now))
}
