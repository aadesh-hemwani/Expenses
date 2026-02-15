import Foundation

extension Optional where Wrapped == Date {
    var identifiableDate: IdentifiableDate? {
        guard let self = self else { return nil }
        return IdentifiableDate(date: self)
    }
}

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}
