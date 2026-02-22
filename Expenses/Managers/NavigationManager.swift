import SwiftUI
import Combine

class NavigationManager: ObservableObject {
    @Published var selectedTab: Tabs = .home
    @Published var scrollToId: String? = nil
    @Published var showingAddExpense: Bool = false
    @Published var spotlightExpenseId: String? = nil
    
    func navigate(to tab: Tabs, scrollTo id: String? = nil) {
        selectedTab = tab
        if let id = id {
            // Slight delay to ensure tab switch happens first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scrollToId = id
            }
        }
    }
    
    func handleDeepLink(url: URL) {
        if url.scheme == "expenses" && url.host == "add" {
            showingAddExpense = true
        }
    }
    func handleSpotlight(identifier: String) {
        // When a user taps a spotlight item, we capture the ID.
        // We will show the History view and present the AddExpenseView in edit mode,
        // or just directly present the AddExpenseView over the current view.
        spotlightExpenseId = identifier
    }
}
