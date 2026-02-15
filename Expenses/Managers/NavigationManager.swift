import SwiftUI
import Combine

class NavigationManager: ObservableObject {
    @Published var selectedTab: Tabs = .home
    @Published var scrollToId: String? = nil
    @Published var showingAddExpense: Bool = false
    
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
}
