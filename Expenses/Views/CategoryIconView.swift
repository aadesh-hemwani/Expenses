import SwiftUI

struct CategoryIconView: View {
    let icon: String
    let color: Color
    var size: CGFloat = 36
    var cornerRadius: CGFloat = 10
    var iconSize: CGFloat = 18
    
    var body: some View {
        ZStack {
            // Background box: black but slightly lighter, similar to iOS Settings app
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(white: 0.12))
            
            // Border highlight: subtle top reflection and gradient for realism
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
