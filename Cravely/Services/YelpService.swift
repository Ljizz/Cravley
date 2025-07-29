import Foundation
import CoreLocation

class YelpService {
    private let apiKey = "YOUR_YELP_API_KEY" // Replace with actual API key
    private let baseURL = "https://api.yelp.com/v3"
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()
    
    func searchRestaurants(
        latitude: Double,
        longitude: Double,
        radius: Int = 8000, // meters
        limit: Int = 20,
        filters: [RestaurantFilter] = []
    ) async throws -> [Restaurant] {
        
        var queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "categories", value: "restaurants")
        ]
        
        // Apply filters
        for filter in filters {
            switch filter {
            case .cuisine(let cuisine):
                let existingCategories = queryItems.first(where: { $0.name == "categories" })?.value ?? ""
                queryItems.removeAll { $0.name == "categories" }
                queryItems.append(URLQueryItem(name: "categories", value: "\(existingCategories),\(cuisine.lowercased())"))
                
            case .priceRange(let priceRange):
                let priceValue: String
                switch priceRange {
                case .budget: priceValue = "1"
                case .moderate: priceValue = "2"
                case .expensive: priceValue = "3"
                case .luxury: priceValue = "4"
                }
                queryItems.append(URLQueryItem(name: "price", value: priceValue))
                
            case .rating(let rating):
                // Yelp doesn't support minimum rating in search, we'll filter after
                break
                
            case .openNow:
                queryItems.append(URLQueryItem(name: "open_now", value: "true"))
                
            default:
                break
            }
        }
        
        guard let url = buildURL(endpoint: "/businesses/search", queryItems: queryItems) else {
            throw YelpError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YelpError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw YelpError.serverError(httpResponse.statusCode)
        }
        
        let yelpResponse = try JSONDecoder().decode(YelpSearchResponse.self, from: data)
        return yelpResponse.businesses.compactMap { convertToRestaurant($0) }
    }
    
    func getBusinessDetails(businessID: String) async throws -> YelpBusiness {
        guard let url = buildURL(endpoint: "/businesses/\(businessID)") else {
            throw YelpError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YelpError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw YelpError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(YelpBusiness.self, from: data)
    }
    
    private func buildURL(endpoint: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
    
    private func convertToRestaurant(_ business: YelpBusiness) -> Restaurant? {
        guard let coordinates = business.coordinates else { return nil }
        
        return Restaurant(
            id: nil, // Firebase will generate
            name: business.name,
            address: business.location?.display_address?.joined(separator: ", ") ?? "",
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            phone: business.phone,
            website: business.url,
            imageURL: business.image_url,
            cuisineType: business.categories?.first?.title ?? "",
            priceRange: convertPriceRange(business.price),
            rating: business.rating ?? 0,
            reviewCount: business.review_count ?? 0,
            isOpen: business.is_closed == false,
            openingHours: business.hours?.first?.open?.map { "\($0.day): \($0.start)-\($0.end)" } ?? [],
            menuURL: nil,
            waitTimes: [],
            yelpID: business.id,
            googlePlaceID: nil
        )
    }
    
    private func convertPriceRange(_ price: String?) -> PriceRange {
        switch price {
        case "$": return .budget
        case "$$": return .moderate
        case "$$$": return .expensive
        case "$$$$": return .luxury
        default: return .moderate
        }
    }
}

// MARK: - Yelp API Models
struct YelpSearchResponse: Codable {
    let businesses: [YelpBusiness]
    let total: Int
}

struct YelpBusiness: Codable {
    let id: String
    let name: String
    let image_url: String?
    let is_closed: Bool?
    let url: String?
    let review_count: Int?
    let categories: [YelpCategory]?
    let rating: Double?
    let coordinates: YelpCoordinates?
    let price: String?
    let location: YelpLocation?
    let phone: String?
    let distance: Double?
    let hours: [YelpHours]?
}

struct YelpCategory: Codable {
    let alias: String
    let title: String
}

struct YelpCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct YelpLocation: Codable {
    let address1: String?
    let address2: String?
    let address3: String?
    let city: String?
    let zip_code: String?
    let country: String?
    let state: String?
    let display_address: [String]?
}

struct YelpHours: Codable {
    let open: [YelpOpenHours]?
    let hours_type: String?
    let is_open_now: Bool?
}

struct YelpOpenHours: Codable {
    let is_overnight: Bool
    let start: String
    let end: String
    let day: Int
}

enum YelpError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noData:
            return "No data received"
        }
    }
}