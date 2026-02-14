import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

@main
struct ExpensesApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let user = authManager.user {
                    ContentView(userId: user.uid)
                        .environmentObject(authManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
