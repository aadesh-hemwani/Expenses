import Foundation
import CoreSpotlight
import MobileCoreServices

class CoreSpotlightManager {
    static let shared = CoreSpotlightManager()
    
    private let domainIdentifier = "com.expenses.search"
    
    private init() {}
    
    func index(expense: Expense) {
        // Ensure expense has an ID to act as the Spotlight unique identifier
        guard let id = expense.id else { return }
        
        // 1. Create an Attribute Set
        // Uses UTTypeItem.identifier but fallback to old String for pre-iOS14 if needed, keeping it modern using kUTTypeItem
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: "public.content")
        
        // 2. Map Expense properties to Spotlight Attributes
        attributeSet.title = expense.title.isEmpty ? expense.category : expense.title
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹" // Hardcoding ₹ as used elsewhere, could use user locale preferred
        formatter.maximumFractionDigits = 0
        let formattedAmount = formatter.string(from: NSNumber(value: expense.amount)) ?? "₹\(Int(expense.amount))"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: expense.date)
        
        attributeSet.contentDescription = "\(formattedAmount) • \(expense.category) • \(dateString)"
        
        // Add keywords for better searchability
        var keywords = [expense.category, expense.type.rawValue, "expense", "spend"]
        if !expense.title.isEmpty && expense.title != expense.category {
            keywords.append(expense.title)
        }
        attributeSet.keywords = keywords
        
        // 3. Create the Searchable Item
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: id,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        
        // 4. Index the item
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { error in
            if let error = error {
                print("Core Spotlight indexing error for expense \(id): \(error.localizedDescription)")
            }
        }
    }
    
    func deindex(expenseId: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [expenseId]) { error in
            if let error = error {
                print("Core Spotlight deletion error for expense \(expenseId): \(error.localizedDescription)")
            }
        }
    }
    
    func deindexAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            if let error = error {
                print("Core Spotlight flush error: \(error.localizedDescription)")
            }
        }
    }
}
