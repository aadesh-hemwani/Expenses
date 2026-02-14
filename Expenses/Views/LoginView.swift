import SwiftUI
import GoogleSignIn
import FirebaseCore

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 40)
            
            Text("Welcome to Expenses")
                .font(.largeTitle)
                .bold()
            
            Text("Sign in to sync your data")
                .foregroundColor(.secondary)
                .padding(.bottom, 60)
            
            Button(action: {
                authManager.signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Sign in with Google")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
            
            if let error = authManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 20)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
