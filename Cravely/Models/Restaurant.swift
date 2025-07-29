import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let phoneNumber: String?
    let website: String?
    let priceLevel: PriceLevel
    let cuisineTypes: [String]
    let rating: Double
    let reviewCount: Int
    let photos: [String] // URLs
    let menu: Menu?
    let hours: [String: String] // Day of week to hours
    let features: [RestaurantFeature]
    let waitTimeData: WaitTimeData?
    let distance: Double? // In meters
    let isOpen: Bool
    let yelpID: String?
    let googlePlacesID: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Custom coding for CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, name, description, address, phoneNumber, website
        case priceLevel, cuisineTypes, rating, reviewCount, photos
        case menu, hours, features, waitTimeData, distance, isOpen
        case yelpID, googlePlacesID, createdAt, updatedAt
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        address = try container.decode(String.self, forKey: .address)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        priceLevel = try container.decode(PriceLevel.self, forKey: .priceLevel)
        cuisineTypes = try container.decode([String].self, forKey: .cuisineTypes)
        rating = try container.decode(Double.self, forKey: .rating)
        reviewCount = try container.decode(Int.self, forKey: .reviewCount)
        photos = try container.decode([String].self, forKey: .photos)
        menu = try container.decodeIfPresent(Menu.self, forKey: .menu)
        hours = try container.decode([String: String].self, forKey: .hours)
        features = try container.decode([RestaurantFeature].self, forKey: .features)
        waitTimeData = try container.decodeIfPresent(WaitTimeData.self, forKey: .waitTimeData)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        isOpen = try container.decode(Bool.self, forKey: .isOpen)
        yelpID = try container.decodeIfPresent(String.self, forKey: .yelpID)
        googlePlacesID = try container.decodeIfPresent(String.self, forKey: .googlePlacesID)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encode(priceLevel, forKey: .priceLevel)
        try container.encode(cuisineTypes, forKey: .cuisineTypes)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(photos, forKey: .photos)
        try container.encodeIfPresent(menu, forKey: .menu)
        try container.encode(hours, forKey: .hours)
        try container.encode(features, forKey: .features)
        try container.encodeIfPresent(waitTimeData, forKey: .waitTimeData)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encode(isOpen, forKey: .isOpen)
        try container.encodeIfPresent(yelpID, forKey: .yelpID)
        try container.encodeIfPresent(googlePlacesID, forKey: .googlePlacesID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

enum PriceLevel: String, Codable, CaseIterable {
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
    
    var emoji: String {
        switch self {
        case .budget: return "💰"
        case .moderate: return "💵"
        case .expensive: return "💸"
        case .luxury: return "👑"
        }
    }
}

enum RestaurantFeature: String, Codable, CaseIterable {
    case delivery = "delivery"
    case takeout = "takeout"
    case dineIn = "dine_in"
    case reservations = "reservations"
    case wifi = "wifi"
    case parking = "parking"
    case wheelchairAccessible = "wheelchair_accessible"
    case outdoorSeating = "outdoor_seating"
    case petFriendly = "pet_friendly"
    case liveMusic = "live_music"
    case happyHour = "happy_hour"
    case brunch = "brunch"
    case lateNight = "late_night"
    
    var displayName: String {
        switch self {
        case .delivery: return "Delivery"
        case .takeout: return "Takeout"
        case .dineIn: return "Dine In"
        case .reservations: return "Reservations"
        case .wifi: return "WiFi"
        case .parking: return "Parking"
        case .wheelchairAccessible: return "Wheelchair Accessible"
        case .outdoorSeating: return "Outdoor Seating"
        case .petFriendly: return "Pet Friendly"
        case .liveMusic: return "Live Music"
        case .happyHour: return "Happy Hour"
        case .brunch: return "Brunch"
        case .lateNight: return "Late Night"
        }
    }
    
    var icon: String {
        switch self {
        case .delivery: return "🚚"
        case .takeout: return "🥡"
        case .dineIn: return "🍽️"
        case .reservations: return "📅"
        case .wifi: return "📶"
        case .parking: return "🅿️"
        case .wheelchairAccessible: return "♿"
        case .outdoorSeating: return "🌤️"
        case .petFriendly: return "🐕"
        case .liveMusic: return "🎵"
        case .happyHour: return "🍻"
        case .brunch: return "🥞"
        case .lateNight: return "🌙"
        }
    }
}

struct Menu: Codable, Hashable {
    let sections: [MenuSection]
    let lastUpdated: Date
    let sourceURL: String?
}

struct MenuSection: Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let items: [MenuItem]
}

struct MenuItem: Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let price: Double?
    let dietary: [DietaryRestriction]
    let imageURL: String?
    let isAvailable: Bool
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case nutFree = "nut_free"
    case keto = "keto"
    case halal = "halal"
    case kosher = "kosher"
    
    var displayName: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .glutenFree: return "Gluten Free"
        case .dairyFree: return "Dairy Free"
        case .nutFree: return "Nut Free"
        case .keto: return "Keto"
        case .halal: return "Halal"
        case .kosher: return "Kosher"
        }
    }
    
    var icon: String {
        switch self {
        case .vegetarian: return "🥬"
        case .vegan: return "🌱"
        case .glutenFree: return "🌾"
        case .dairyFree: return "🥛"
        case .nutFree: return "🥜"
        case .keto: return "🥑"
        case .halal: return "☪️"
        case .kosher: return "✡️"
        }
    }
}

extension Restaurant {
    static let mockRestaurant = Restaurant(
        id: "1",
        name: "The Gourmet Kitchen",
        description: "Contemporary American cuisine with a focus on locally sourced ingredients",
        address: "123 Main St, San Francisco, CA 94102",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        phoneNumber: "(415) 555-0123",
        website: "https://thegourmetkitchen.com",
        priceLevel: .moderate,
        cuisineTypes: ["American", "Contemporary"],
        rating: 4.5,
        reviewCount: 234,
        photos: [
            "https://example.com/photo1.jpg",
            "https://example.com/photo2.jpg"
        ],
        menu: nil,
        hours: [
            "Monday": "11:00 AM - 10:00 PM",
            "Tuesday": "11:00 AM - 10:00 PM",
            "Wednesday": "11:00 AM - 10:00 PM",
            "Thursday": "11:00 AM - 11:00 PM",
            "Friday": "11:00 AM - 11:00 PM",
            "Saturday": "10:00 AM - 11:00 PM",
            "Sunday": "10:00 AM - 9:00 PM"
        ],
        features: [.dineIn, .takeout, .wifi, .parking],
        waitTimeData: nil,
        distance: 250.0,
        isOpen: true,
        yelpID: "the-gourmet-kitchen-san-francisco",
        googlePlacesID: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}