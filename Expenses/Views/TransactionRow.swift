import SwiftUI

struct TransactionRow: View {
    let expense: Expense
    
    private var parsedData: (displayTitle: String, subCategory: String?) {
        let components = expense.title.components(separatedBy: "-")
        if components.count > 1 {
            let subCat = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            // Re-join the rest in case there were multiple hyphens (e.g., "Lunch - subway - extra")
            let title = components.dropFirst().joined(separator: "-").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Capitalize first letter for neatness
            let capitalizedTitle = title.prefix(1).capitalized + title.dropFirst()
            return (displayTitle: capitalizedTitle, subCategory: subCat.prefix(1).capitalized + subCat.dropFirst())
        }
        
        // No hyphen, use default
        let title = expense.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let capitalizedDefault = title.prefix(1).capitalized + title.dropFirst()
        return (displayTitle: capitalizedDefault, subCategory: nil)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Leading Icon
            CategoryIconView(icon: expense.icon, color: expense.color, size: 40, cornerRadius: 10, iconSize: 22)
            .frame(width: 40, height: 40)
     
            // Title & Category
            VStack(alignment: .leading, spacing: 4) {
                Text(parsedData.displayTitle)
                    .font(.body)
                    .fontWeight(.semibold) // Made slightly bolder for hierarchy
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(expense.category)
                        
                    if let subCat = parsedData.subCategory {
                        Text("•")
                        Text(subCat)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
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

// Add custom button style for the scale effect
struct TransactionRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .background(Color.clear) // Ensure it can be pressed
    }
}

#Preview {
    TransactionRow(expense: Expense.example)
        .padding()
}
