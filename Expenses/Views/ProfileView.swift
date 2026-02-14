import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // Appearance State Persisted
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("accumulatedColor") private var accentColorName = "Indigo" // Renamed to avoid reserved word conflict
    
    let accentColors: [(name: String, color: Color)] = [
        ("Indigo", .indigo),
        ("Teal", .teal),
        ("Pink", .pink),
        ("Orange", .orange),
        ("Purple", .purple),
        ("Cyan", .cyan)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    HStack {
                        Text("Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // User Card
                    VStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            if let photoURL = authManager.user?.photoURL {
                                AsyncImage(url: photoURL) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill") // Fallback
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                            
                            Circle()
                                .fill(Color.green)
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                                .offset(x: 0, y: 0)
                        }
                        
                        VStack(spacing: 4) {
                            Text(authManager.user?.displayName ?? "Guest User")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(authManager.user?.email ?? "No email linked")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Fake Admin Dashboard Button
                        Button(action: {}) {
                            Text("Admin Dashboard")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color("AccentColor").opacity(0.1)) // Dynamic accent
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                        
                        // Google Verified Badge
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Google Verified")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    
                    // Appearance Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .font(.title2)
                                .foregroundColor(.indigo)
                                .frame(width: 40, height: 40)
                                .background(Color.indigo.opacity(0.1))
                                .cornerRadius(10)
                            
                            Text("Appearance")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        // Dark Mode Toggle
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 32, height: 32)
                                .background(Color.yellow.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text("Dark Mode")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Adjust the appearance to reduce glare.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isDarkMode)
                                .labelsHidden()
                        }
                        
                        Divider()
                        
                        // Accent Color Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACCENT COLOR • \(accentColorName.uppercased())")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                ForEach(accentColors, id: \.name) { item in
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .opacity(accentColorName == item.name ? 1 : 0)
                                        )
                                        .onTapGesture {
                                            withAnimation {
                                                accentColorName = item.name
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    
                    // Sign Out Button (Optional but useful)
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
