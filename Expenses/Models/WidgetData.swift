import Foundation

struct WidgetData: Codable {
    let totalAmount: Double
    let monthName: String
    let dailyPoints: [Double]
    let lastUpdated: Date
}
