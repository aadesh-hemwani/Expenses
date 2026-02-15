import SwiftUI

struct TransactionRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 16) {
            // Leading Icon
            ZStack {
                Image(systemName: expense.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(expense.color)
                    .symbolRenderingMode(.monochrome)
            }
            .frame(width: 40, height: 40)
     
            // Title & Category
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(expense.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Amount & Time
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: "indianrupeesign")
                        .font(.caption)
                        .foregroundStyle(.primary)
                    
                    Text(expense.amount.formatted(.number.precision(.fractionLength(0...2))))
                }
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                //.contentTransition(.numericText()) // numericText transition typically applies to Text views, check if it works on HStack or disable it correctly
                
                Text(expense.date, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Make entire row tappable
    }
}

#Preview {
    TransactionRow(expense: Expense.example)
        .padding()
}
