import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var monthlyBudgetCap: Double?
    var displayName: String?
    var email: String?
    var photoURL: String?
    var createdAt: Date?
    var isAdmin: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case monthlyBudgetCap
        case displayName
        case email
        case photoURL
        case createdAt
        case isAdmin
    }
}
