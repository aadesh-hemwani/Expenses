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
    @State private var showingAddExpense = false
    @State private var selectedTab: Tabs = .history
    
    // Appearance State (Read Only here, modifiers applied in body)
    @AppStorage("accumulatedColor") private var accentColorName = "Indigo"
    
    init(userId: String) {
        _repository = StateObject(wrappedValue: ExpenseRepository(userId: userId))
        
//        // Standard Appearance - Fully Transparent
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithTransparentBackground()
//        appearance.backgroundEffect = nil // No blur
//        appearance.shadowColor = .clear // No shadow
//        
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().compactAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {

            Tab("Home", systemImage: "house", value: .home) {
                ExpenseListView()
            }
            
            Tab("History", systemImage: "calendar", value: .history) {
                HistoryView()
            }
            
            Tab("Insights", systemImage: "chart.bar", value: .insights) {
                InsightsView()
            }
            
            Tab("Profile", systemImage: "person", value: .profile) {
                ProfileView()
            }
            
            Tab("Add", systemImage: "plus", value: .add, role: TabRole.search) {
                Color.clear
            }
            
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .add {
                showingAddExpense = true
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
                .environmentObject(repository)
        }
        .environmentObject(repository)
//        .tint(getAccentColor()) // Dynamic Accent Color
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
    private func getAccentColor() -> Color {
        switch accentColorName {
        case "Indigo": return .indigo
        case "Teal": return .teal
        case "Pink": return .pink
        case "Orange": return .orange
        case "Purple": return .purple
        case "Cyan": return .cyan
        default: return .indigo
        }
    }
}

#Preview {
    ContentView(userId: "mockUserId")
        .environmentObject(AuthManager())
}
