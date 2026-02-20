import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // Appearance State Persisted
    @State private var monthlyBudget: Double = 0.0
    @FocusState private var isBudgetFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                // SECTION 1: IDENTITY
                Section {
                    HStack(spacing: 16) {
                        if let photoURL = authManager.user?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.user?.displayName ?? "Guest User")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(authManager.user?.email ?? "No email linked")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                
                // SECTION 3: BUDGET SETTINGS
                Section {
                    HStack {
                        Text("Monthly Budget")
                        Spacer()
                        TextField("Amount", value: $monthlyBudget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                            .focused($isBudgetFocused)
                            .onSubmit {
                                authManager.updateMonthlyBudget(amount: monthlyBudget)
                            }
                    }
                } header: {
                    Text("Budget Settings")
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isBudgetFocused = false
                            authManager.updateMonthlyBudget(amount: monthlyBudget)
                        }
                    }
                }
                
                // SECTION 3: ACCOUNT ACTIONS
                Section {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let budget = authManager.appUser?.monthlyBudgetCap {
                    monthlyBudget = budget
                }
            }
            .onChange(of: authManager.appUser) { oldUser, newUser in
                if let budget = newUser?.monthlyBudgetCap {
                    monthlyBudget = budget
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
