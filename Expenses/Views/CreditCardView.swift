import SwiftUI

struct CreditCardView: View {
    var totalAmount: Double
    var name: String
    
    // Computed formatter to separate whole and fraction parts
    private var formattedTotal: (whole: String, fraction: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let totalString = formatter.string(from: NSNumber(value: totalAmount)) ?? "0.00"
        let parts = totalString.split(separator: ".")
        
        if parts.count == 2 {
            return (String(parts[0]), "." + String(parts[1]))
        } else {
            return (totalString, ".00")
        }
    }
    
    var body: some View {
        ZStack {
            // Dark Card Background with Mesh/Gradient logic
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1c1c1e"), Color(hex: "2c2c2e")], // Dark gray gradient
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Subtle mesh pattern simulation using gradients
                    ZStack {
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .topTrailing,
                            startRadius: 0,
                            endRadius: 200
                        )
                        RadialGradient(
                            colors: [.blue.opacity(0.2), .clear],
                            center: .bottomLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                         RadialGradient(
                            colors: [.orange.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
            
            VStack(alignment: .leading) {
                // Top Row: Chip + Contactless
                HStack {
                    // Simulated Chip
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.8), .yellow.opacity(0.4), .yellow.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 45, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    // Contactless Icon
                    Image(systemName: "wave.3.right")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.6))
                        .rotationEffect(.degrees(-90))
                }
                .padding(.bottom, 20)
                
                // Label
                Text("CURRENT SPENDINGS")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .tracking(1)
                
                // Amount
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("₹")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(.white)
                    
                    Text(formattedTotal.whole)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(formattedTotal.fraction)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
                
                // Card Number Simulation
                Text("•••• •••• •••• 4029") // Static for now, consistent with design
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(2)
                
                Spacer()
                
                // Bottom Row: Holder Name + Percentage/Badge
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACCOUNT HOLDER")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .tracking(1)
                        
                        Text(name.uppercased())
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .tracking(1)
                    }
                    
                    Spacer()
                    
                    // Trend Badge (Visual only for now)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text("325%")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.pink.opacity(0.15))
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
        .frame(height: 220) // Credit card ratio-ish
    }
}

// Hex Color Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CreditCardView(totalAmount: 44644.60, name: "Aadesh Hemwani")
        .padding()
        .background(Color.black)
}
