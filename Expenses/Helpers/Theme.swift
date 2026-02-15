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
        static let green = Color(.systemGreen)
        static let red = Color(.systemRed)
        static let amber = Color(.systemOrange)
        static let pink = Color(.systemPink)
        static let purple = Color(.systemPurple)
        static let cyan = Color(.systemTeal)
    }

    struct CategoryColors {
        static let food = Color(.systemOrange)
        static let transport = Color(.systemBlue)
        static let shopping = Color(.systemPurple)
        static let entertainment = Color(.systemIndigo)
        static let health = Color(.systemRed)
        static let bills = Color(.systemTeal)
        static let misc = Color(.secondaryLabel)
    }
}
