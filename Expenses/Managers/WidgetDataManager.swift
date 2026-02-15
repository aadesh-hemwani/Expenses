import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    // HARDCODED APP GROUP ID - User must add this capability in Xcode
    private let suiteName = "group.com.adeshhemwani.Expenses"
    
    private init() {}
    
    func load() -> WidgetData? {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: "widgetData") else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
