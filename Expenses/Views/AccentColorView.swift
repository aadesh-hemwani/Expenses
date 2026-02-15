import SwiftUI

struct AccentColorView: View {
    @AppStorage("accumulatedColor") private var accentColorName = "Indigo"
    
    let accentColors: [(name: String, color: Color)] = [
        ("Indigo", .indigo),
        ("Teal", .teal),
        ("Pink", .pink),
        ("Orange", .orange),
        ("Purple", .purple),
        ("Cyan", .cyan)
    ]
    
    var body: some View {
        List {
            ForEach(accentColors, id: \.name) { item in
                Button {
                    withAnimation {
                        accentColorName = item.name
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 24, height: 24)
                        
                        Text(item.name)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if accentColorName == item.name {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .foregroundStyle(.primary) // Ensure button text is black/white
            }
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AccentColorView()
    }
}
