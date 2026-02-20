import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Refresh hourly
        let currentDate = Date()

        let entry = SimpleEntry(date: currentDate)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct AddExpensesWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Link(destination: URL(string: "expenses://add")!) {
            ZStack {
                ContainerRelativeShape()
                    .fill(Color(UIColor.systemBackground))
                
                VStack {
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Circle().fill(Color.green)) // Or accent color
                    
                    Text("Add Expense")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}



// Ensure this structure matches your Bundle ID + Widget Extension name in Xcode
struct AddExpensesWidget: Widget {
    let kind: String = "AddExpensesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AddExpensesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Add")
        .description("Quickly add a new expense.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    AddExpensesWidget()
} timeline: {
    SimpleEntry(date: .now)
}
