import SwiftUI

// Tab enum for navigation
enum Tab: String, CaseIterable {
    case home = "Home"
    case history = "History"
    case insights = "Insights"
    case profile = "Profile"
}

struct ContentView: View {
    @StateObject private var repository: ExpenseRepository
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddExpense = false
    @State private var selectedTab: Tab = .home
    
    // Appearance State (Read Only here, modifiers applied in body)
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("accumulatedColor") private var accentColorName = "Indigo"
    
    init(userId: String) {
        _repository = StateObject(wrappedValue: ExpenseRepository(userId: userId))
        
        // Standard Appearance - Fully Transparent
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil // No blur
        appearance.shadowColor = .clear // No shadow
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Tab Bar Appearance - Liquid Glass
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial) // Heavier glass
        tabAppearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ExpenseListView()
                    // Restore the "plus" button to the native toolbar
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                showingAddExpense = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(Tab.home)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(Tab.history)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
                .tag(Tab.insights)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(Tab.profile)
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
                .environmentObject(repository)
        }
        .environmentObject(repository)
        .tint(getAccentColor()) // Dynamic Accent Color
        .preferredColorScheme(isDarkMode ? .dark : .light) // Force Dark/Light Mode
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
