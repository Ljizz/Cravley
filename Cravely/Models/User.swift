import Foundation
import FirebaseFirestoreSwift

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var name: String
    var profileImageURL: String?
    var preferences: UserPreferences
    var createdAt: Date
    var isPremium: Bool
    
    init(email: String, name: String) {
        self.email = email
        self.name = name
        self.preferences = UserPreferences()
        self.createdAt = Date()
        self.isPremium = false
    }
}

struct UserPreferences: Codable {
    var cuisineTypes: [String]
    var dietaryRestrictions: [String]
    var priceRange: PriceRange
    var maxDistance: Double // in miles
    var notifications: NotificationPreferences
    
    init() {
        self.cuisineTypes = []
        self.dietaryRestrictions = []
        self.priceRange = .moderate
        self.maxDistance = 5.0
        self.notifications = NotificationPreferences()
    }
}

struct NotificationPreferences: Codable {
    var waitTimeAlerts: Bool
    var newRecommendations: Bool
    var favoriteRestaurantUpdates: Bool
    
    init() {
        self.waitTimeAlerts = true
        self.newRecommendations = true
        self.favoriteRestaurantUpdates = true
    }
}

enum PriceRange: String, CaseIterable, Codable {
    case budget = "$"
    case moderate = "$$"
    case expensive = "$$$"
    case luxury = "$$$$"
    
    var description: String {
        switch self {
        case .budget: return "Budget-friendly"
        case .moderate: return "Moderate"
        case .expensive: return "Expensive"
        case .luxury: return "Luxury"
        }
    }
}