import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var repository: ExpenseRepository
    
    // Grouping Helper
    struct YearGroup: Identifiable {
        let id: String
        let months: [MonthlyStats]
    }
    
    // Computed property to group stats by year
    var groupedStats: [YearGroup] {
        let grouped = Dictionary(grouping: repository.allStats) { stat in
            // Assuming stat.id is "yyyy-MM", prefix(4) gives year
            String((stat.id ?? "").prefix(4))
        }
        
        // Sort years descending
        return grouped.map { YearGroup(id: $0.key, months: $0.value.sorted(by: { ($0.id ?? "") > ($1.id ?? "") })) }
            .sorted { $0.id > $1.id }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedStats) { group in
                    Section(header: Text(group.id)) {
                        ForEach(group.months) { stat in
                            NavigationLink(destination: MonthDetailView(monthID: stat.id ?? "", totalAmount: stat.total)) {
                                HStack {
                                    Text(formatMonth(stat.id))
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 2) {
                                        Image(systemName: "indianrupeesign")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text(NumberFormatter.localizedString(from: NSNumber(value: stat.total), number: .decimal))
                                    }
                                    .fontWeight(.semibold)
                                    .foregroundStyle(stat.total > 0 ? .primary : .secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            repository.refreshStats()
        }
    }
    
    // Helper to format "yyyy-MM" to "February"
    private func formatMonth(_ id: String?) -> String {
        guard let id = id else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: id) {
            formatter.dateFormat = "MMMM"
            return formatter.string(from: date) // Title case default involves no transformation usually or .capitalized
        }
        return ""
    }
}

#Preview {
    HistoryView()
        .environmentObject(ExpenseRepository(userId: "preview_user"))
}
