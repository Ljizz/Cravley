import Foundation
import CoreLocation
import FirebaseFirestoreSwift

struct Restaurant: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var phone: String?
    var website: String?
    var imageURL: String?
    var cuisineType: String
    var priceRange: PriceRange
    var rating: Double
    var reviewCount: Int
    var isOpen: Bool
    var openingHours: [String]
    var menuURL: String?
    var waitTimes: [WaitTime]
    var yelpID: String?
    var googlePlaceID: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var currentWaitTime: Int? {
        let now = Date()
        let recentWaitTimes = waitTimes.filter { 
            now.timeIntervalSince($0.timestamp) < 3600 // Within last hour
        }
        
        guard !recentWaitTimes.isEmpty else { return nil }
        
        let totalMinutes = recentWaitTimes.reduce(0) { $0 + $1.minutes }
        return totalMinutes / recentWaitTimes.count
    }
    
    var averageWaitTime: Int? {
        guard !waitTimes.isEmpty else { return nil }
        let totalMinutes = waitTimes.reduce(0) { $0 + $1.minutes }
        return totalMinutes / waitTimes.count
    }
}

struct WaitTime: Codable, Identifiable {
    var id = UUID()
    var minutes: Int
    var timestamp: Date
    var userID: String
    var partySize: Int
    
    init(minutes: Int, userID: String, partySize: Int = 2) {
        self.minutes = minutes
        self.userID = userID
        self.partySize = partySize
        self.timestamp = Date()
    }
}

struct RestaurantList: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var userID: String
    var restaurantIDs: [String]
    var createdAt: Date
    var isPublic: Bool
    
    init(name: String, userID: String, isPublic: Bool = false) {
        self.name = name
        self.userID = userID
        self.restaurantIDs = []
        self.createdAt = Date()
        self.isPublic = isPublic
    }
}

enum RestaurantFilter {
    case cuisine(String)
    case priceRange(PriceRange)
    case distance(Double)
    case rating(Double)
    case openNow
    case shortWait(Int)
}