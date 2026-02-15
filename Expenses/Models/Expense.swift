import Foundation
import FirebaseFirestore
import SwiftUI

struct Expense: Identifiable, Codable, Equatable {
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
        case "Transport": return "car"
        case "Shopping": return "cart"
        case "Entertainment": return "tv"
        case "Health": return "heart"
        case "Bills": return "doc.text"
        default: return "ellipsis.circle"
        }
    }
    
    var color: Color {
        switch category {
        case "Food": return Theme.CategoryColors.food
        case "Transport": return Theme.CategoryColors.transport
        case "Shopping": return Theme.CategoryColors.shopping
        case "Entertainment": return Theme.CategoryColors.entertainment
        case "Health": return Theme.CategoryColors.health
        case "Bills": return Theme.CategoryColors.bills
        default: return Theme.CategoryColors.misc
        }
    }
    static let example = Expense(id: "1", title: "Lunch", amount: 450.0, date: Date(), category: "Food")
}

