import Foundation
import FirebaseFirestore
import SwiftUI

struct Expense: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var amount: Double
    var date: Date
    var category: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title = "note"
        case amount
        case date
        case category
    }
    
    // UI Helpers
    var icon: String {
        switch category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Shopping": return "cart.fill"
        case "Entertainment": return "tv.fill"
        case "Health": return "heart.fill"
        case "Bills": return "doc.text.fill"
        default: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch category {
        case "Food": return .orange
        case "Transport": return .blue
        case "Shopping": return .purple
        case "Entertainment": return .pink
        case "Health": return .red
        case "Bills": return .yellow
        default: return .gray
        }
    }
    static let example = Expense(id: "1", title: "Lunch", amount: 450.0, date: Date(), category: "Food")
}

