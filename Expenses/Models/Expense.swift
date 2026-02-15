import Foundation
import FirebaseFirestore
import SwiftUI

struct Expense: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var amount: Double
    var date: Date
    var category: String
    var type: ExpenseType = .oneOff
    
    enum ExpenseType: String, Codable, CaseIterable {
        case regular = "Regular"
        case oneOff = "One-off"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title = "note"
        case amount
        case date
        case category
        case type
    }
    
    init(id: String? = nil, title: String, amount: Double, date: Date, category: String, type: ExpenseType = .oneOff) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Double.self, forKey: .amount)
        date = try container.decode(Date.self, forKey: .date)
        category = try container.decode(String.self, forKey: .category)
        type = try container.decodeIfPresent(ExpenseType.self, forKey: .type) ?? .regular
    }
    
    // Shared Category Definition
    struct Category: Hashable {
        let name: String
        let icon: String
        let color: Color
    }
    
    static let allCategories: [Category] = [
        Category(name: "Food", icon: "fork.knife", color: Theme.CategoryColors.food),
        Category(name: "Transport", icon: "car", color: Theme.CategoryColors.transport),
        Category(name: "Shopping", icon: "cart", color: Theme.CategoryColors.shopping),
        Category(name: "Entertainment", icon: "tv", color: Theme.CategoryColors.entertainment),
        Category(name: "Health", icon: "heart", color: Theme.CategoryColors.health),
        Category(name: "Bills", icon: "creditcard", color: Theme.CategoryColors.bills),
        Category(name: "Misc", icon: "square.grid.2x2", color: Theme.CategoryColors.misc)
    ]
    
    // UI Helpers
    var icon: String {
        Expense.allCategories.first(where: { $0.name == category })?.icon ?? "square.grid.2x2"
    }
    
    var color: Color {
        Expense.allCategories.first(where: { $0.name == category })?.color ?? Theme.CategoryColors.misc
    }
    static let example = Expense(id: "1", title: "Lunch", amount: 450.0, date: Date(), category: "Food", type: .regular)
}

