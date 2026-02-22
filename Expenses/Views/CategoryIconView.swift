import SwiftUI

struct CategoryIconView: View {
    let icon: String
    let color: Color
    var size: CGFloat = 36
    var cornerRadius: CGFloat = 10
    var iconSize: CGFloat = 18
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background box
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(colorScheme == .light ? color : Color(white: 0.12))
            
            if colorScheme == .light {
                // Subtle reflection gradient
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            if colorScheme == .dark {
                // Border highlight: subtle top reflection and gradient for realism
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(colorScheme == .light ? .white : color)
        }
        .frame(width: size, height: size)
    }
}
