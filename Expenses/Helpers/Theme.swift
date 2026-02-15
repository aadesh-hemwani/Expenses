import SwiftUI

struct Theme {
    static func getAccentColor() -> Color {
        let colorName = UserDefaults.standard.string(forKey: "accumulatedColor") ?? "Green"
        switch colorName {
        case "Green": return Accents.green
        case "Red": return Accents.red
        case "Amber": return Accents.amber
        case "Pink": return Accents.pink
        case "Purple": return Accents.purple
        case "Cyan": return Accents.cyan
        default: return Accents.green // Default to Green
        }
    }
    struct Accents {
        static let green = Color(red: 0.0, green: 0.8, blue: 0.4) // Emerald Green
        static let red = Color(red: 1.0, green: 0.23, blue: 0.19) // Ruby Red
        static let amber = Color(red: 1.0, green: 0.75, blue: 0.0) // Golden Amber
        static let pink = Color(red: 1.0, green: 0.2, blue: 0.6) // Raspberry
        static let purple = Color(red: 0.6, green: 0.3, blue: 0.9) // Electric Purple
        static let cyan = Color(red: 0.2, green: 0.8, blue: 1.0) // Sky Blue
    }

    struct CategoryColors {
        static let food = Color.orange
        static let transport = Color.blue
        static let shopping = Color.purple
        static let entertainment = Color.indigo
        static let health = Color.red
        static let bills = Color.teal
        static let misc = Color(UIColor.secondaryLabel)
    }
}
