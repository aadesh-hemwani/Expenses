import SwiftUI

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
    
    // Appearance State (Read Only here, modifiers applied in body)
    @AppStorage("accumulatedColor") private var accentColorName = "Green"
    
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
        .tint(Theme.getAccentColor()) // Dynamic Accent Color
        .alert(item: Binding<IdentifiableString?>(
            get: { repository.errorMessage.map { IdentifiableString(value: $0) } },
            set: { _ in repository.errorMessage = nil }
        )) { error in
            Alert(title: Text("Error"), message: Text(error.value), dismissButton: .default(Text("OK")))
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
