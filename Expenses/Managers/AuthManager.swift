import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import SwiftUI
import Combine
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var appUser: AppUser?
    @Published var errorMessage: String?
    
    private lazy var db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    
    init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || FirebaseApp.app() == nil {
            return
        }
        
        self.user = Auth.auth().currentUser
        if let user = self.user {
            fetchUser(userId: user.uid)
        }
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                self?.user = result?.user
                if let userId = result?.user.uid {
                    self?.fetchUser(userId: userId)
                    // If new user or updating info, could do it here
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.appUser = nil
            self.userListener?.remove()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func fetchUser(userId: String) {
        userListener?.remove()
        
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching user: \(error!)")
                    return
                }
                
                guard let self = self else { return }
                
                do {
                    self.appUser = try document.data(as: AppUser.self)
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
    }
    
    func updateMonthlyBudget(amount: Double) {
        guard let userId = user?.uid else { return }
        
        db.collection("users").document(userId).setData(["monthlyBudgetCap": amount], merge: true) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to update budget: \(error.localizedDescription)"
            }
        }
    }
}
