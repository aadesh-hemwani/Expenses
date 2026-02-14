import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var repository: ExpenseRepository
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(repository.allStats) { stat in
                            VStack(alignment: .leading, spacing: 8) {
                                // Month Name
                                Text(formatMonth(stat.id))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                
                                // Total Amount
                                Text("₹" + (NumberFormatter.localizedString(from: NSNumber(value: stat.total), number: .decimal)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                // Year
                                Text(formatYear(stat.id))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    // Helper to format "yyyy-MM" to "FEBRUARY"
    private func formatMonth(_ id: String?) -> String {
        guard let id = id else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: id) {
            formatter.dateFormat = "MMMM"
            return formatter.string(from: date).uppercased()
        }
        return ""
    }
    
    // Helper to format "yyyy-MM" to "2026"
    private func formatYear(_ id: String?) -> String {
        guard let id = id else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: id) {
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
        return ""
    }
}

#Preview {
    HistoryView()
        .environmentObject(ExpenseRepository(userId: "preview_user"))
}
