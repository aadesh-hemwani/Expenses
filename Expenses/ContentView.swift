import SwiftUI
import CoreSpotlight

// Tab enum for navigation
enum Tabs: String, CaseIterable {
    case home = "Home"
    case history = "History"
    case insights = "Insights"
    case profile = "Profile"
    case add = "Add"
}

struct ContentView: View {
    @StateObject private var repository: ExpenseRepository
    @EnvironmentObject var authManager: AuthManager
    // Removed local state: @State private var showingAddExpense = false
    @StateObject private var navigationManager = NavigationManager()
    @State private var sheetDetent: PresentationDetent = .medium
    
    // Spotlight State
    @State private var spotlightExpense: Expense?
    @State private var showingSpotlightExpense: Bool = false
    
    // Appearance State (Read Only here, modifiers applied in body)
    init(userId: String) {
        _repository = StateObject(wrappedValue: ExpenseRepository(userId: userId))
        
    }
    
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {

            Tab("Home", systemImage: "house", value: .home) {
                ExpenseListView()
            }
            
            Tab("History", systemImage: "calendar", value: .history) {
                HistoryView()
            }
            
            Tab("Insights", systemImage: "chart.line.uptrend.xyaxis", value: .insights) {
                InsightsView()
            }
            
            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                ProfileView()
            }
            
            Tab("Add", systemImage: "plus", value: .add, role: TabRole.search) {
                Color.clear
            }
            
        }
        .onChange(of: navigationManager.selectedTab) { oldValue, newValue in
            if newValue == .add {
                navigationManager.showingAddExpense = true
                navigationManager.selectedTab = oldValue
            }
        }
        .sheet(isPresented: $navigationManager.showingAddExpense) {
            AddExpenseView(sheetDetent: $sheetDetent)
                .environmentObject(repository)
                .presentationDetents([.medium, .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
        }
        .onOpenURL { url in
            navigationManager.handleDeepLink(url: url)
        }
        .environmentObject(repository)
        .environmentObject(navigationManager)
        .alert(item: Binding<IdentifiableString?>(
            get: { repository.errorMessage.map { IdentifiableString(value: $0) } },
            set: { _ in repository.errorMessage = nil }
        )) { error in
            Alert(title: Text("Error"), message: Text(error.value), dismissButton: .default(Text("OK")))
        }
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                navigationManager.handleSpotlight(identifier: identifier)
            }
        }
        .onChange(of: navigationManager.spotlightExpenseId) { _, newValue in
            if let id = newValue {
                // Find expense in loaded list. If not there, we'd ideally fetch it, 
                // but for now we look in the primary loaded expenses
                if let matched = repository.expenses.first(where: { $0.id == id }) {
                    spotlightExpense = matched
                    showingSpotlightExpense = true
                }
                // Reset so we can trigger again if needed
                navigationManager.spotlightExpenseId = nil
            }
        }
        .sheet(isPresented: $showingSpotlightExpense) {
            if let expense = spotlightExpense {
                AddExpenseView(expenseToEdit: expense)
                    .environmentObject(repository)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    struct IdentifiableString: Identifiable {
        let id = UUID()
        let value: String
    }
    
    // Helper to map stored string to Color

}

#Preview {
    ContentView(userId: "mockUserId")
        .environmentObject(AuthManager())
}
