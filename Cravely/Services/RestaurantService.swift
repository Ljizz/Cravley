import Foundation
import CoreLocation
import Combine

@MainActor
class RestaurantService: ObservableObject {
    @Published var nearbyRestaurants: [Restaurant] = []
    @Published var searchResults: [Restaurant] = []
    @Published var isLoading = false
    @Published var error: RestaurantError?
    
    private var cancellables = Set<AnyCancellable>()
    
    enum RestaurantError: Error, LocalizedError {
        case networkError
        case apiError(String)
        case locationRequired
        case noResults
        
        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Network connection error"
            case .apiError(let message):
                return message
            case .locationRequired:
                return "Location access required to find nearby restaurants"
            case .noResults:
                return "No restaurants found in this area"
            }
        }
    }
    
    init() {
        loadMockData()
    }
    
    // MARK: - Public Methods
    
    func fetchNearbyRestaurants(location: CLLocation, radius: Double = 5000) async {
        isLoading = true
        error = nil
        
        do {
            // Simulate API call delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // In a real implementation, this would call Yelp/Google Places API
            let restaurants = generateMockRestaurants(near: location, radius: radius)
            
            await MainActor.run {
                self.nearbyRestaurants = restaurants
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .networkError
                self.isLoading = false
            }
        }
    }
    
    func searchRestaurants(query: String, location: CLLocation? = nil) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Simulate API call delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // In a real implementation, this would search via API
            let restaurants = generateSearchResults(for: query, location: location)
            
            await MainActor.run {
                self.searchResults = restaurants
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .networkError
                self.isLoading = false
            }
        }
    }
    
    func getRestaurant(id: String) async -> Restaurant? {
        // In a real implementation, this would fetch from API
        return nearbyRestaurants.first { $0.id == id } ?? 
               searchResults.first { $0.id == id }
    }
    
    func refreshNearbyRestaurants(location: CLLocation) async {
        await fetchNearbyRestaurants(location: location)
    }
    
    // MARK: - Filtering and Sorting
    
    func filterRestaurants(
        _ restaurants: [Restaurant],
        cuisines: [String] = [],
        priceRange: [PriceLevel] = [],
        features: [RestaurantFeature] = [],
        maxDistance: Double? = nil,
        maxWaitTime: Int? = nil
    ) -> [Restaurant] {
        var filtered = restaurants
        
        // Filter by cuisine
        if !cuisines.isEmpty {
            filtered = filtered.filter { restaurant in
                !Set(restaurant.cuisineTypes).isDisjoint(with: Set(cuisines))
            }
        }
        
        // Filter by price range
        if !priceRange.isEmpty {
            filtered = filtered.filter { priceRange.contains($0.priceLevel) }
        }
        
        // Filter by features
        if !features.isEmpty {
            filtered = filtered.filter { restaurant in
                !Set(restaurant.features).isDisjoint(with: Set(features))
            }
        }
        
        // Filter by distance
        if let maxDistance = maxDistance {
            filtered = filtered.filter { restaurant in
                guard let distance = restaurant.distance else { return true }
                return distance <= maxDistance
            }
        }
        
        // Filter by wait time
        if let maxWaitTime = maxWaitTime {
            filtered = filtered.filter { restaurant in
                guard let waitTime = restaurant.waitTimeData?.currentEstimate else { return true }
                return waitTime <= maxWaitTime
            }
        }
        
        return filtered
    }
    
    func sortRestaurants(
        _ restaurants: [Restaurant],
        by sortOption: RestaurantSortOption
    ) -> [Restaurant] {
        switch sortOption {
        case .distance:
            return restaurants.sorted { 
                ($0.distance ?? Double.infinity) < ($1.distance ?? Double.infinity)
            }
        case .rating:
            return restaurants.sorted { $0.rating > $1.rating }
        case .reviewCount:
            return restaurants.sorted { $0.reviewCount > $1.reviewCount }
        case .waitTime:
            return restaurants.sorted {
                ($0.waitTimeData?.currentEstimate ?? Int.max) < ($1.waitTimeData?.currentEstimate ?? Int.max)
            }
        case .priceLevel:
            return restaurants.sorted { $0.priceLevel.rawValue < $1.priceLevel.rawValue }
        case .alphabetical:
            return restaurants.sorted { $0.name < $1.name }
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func loadMockData() {
        nearbyRestaurants = [
            Restaurant.mockRestaurant,
            generateMockRestaurant(
                id: "rest2",
                name: "Pasta Paradise",
                cuisine: ["Italian"],
                rating: 4.3,
                priceLevel: .moderate,
                distance: 400,
                waitTime: 25
            ),
            generateMockRestaurant(
                id: "rest3",
                name: "Sushi Zen",
                cuisine: ["Japanese", "Sushi"],
                rating: 4.7,
                priceLevel: .expensive,
                distance: 800,
                waitTime: 45
            ),
            generateMockRestaurant(
                id: "rest4",
                name: "Burger Barn",
                cuisine: ["American", "Burgers"],
                rating: 4.1,
                priceLevel: .budget,
                distance: 150,
                waitTime: 10
            ),
            generateMockRestaurant(
                id: "rest5",
                name: "Thai Garden",
                cuisine: ["Thai", "Asian"],
                rating: 4.5,
                priceLevel: .moderate,
                distance: 600,
                waitTime: 20
            )
        ]
    }
    
    private func generateMockRestaurants(near location: CLLocation, radius: Double) -> [Restaurant] {
        // Generate mock restaurants based on location
        return nearbyRestaurants.map { restaurant in
            var updatedRestaurant = restaurant
            // Update distance based on location
            let distance = location.coordinate.distance(to: restaurant.coordinate)
            // Update restaurant with new distance (this would require Restaurant to be mutable)
            return restaurant
        }
    }
    
    private func generateSearchResults(for query: String, location: CLLocation?) -> [Restaurant] {
        // Filter existing restaurants based on search query
        return nearbyRestaurants.filter { restaurant in
            restaurant.name.localizedCaseInsensitiveContains(query) ||
            restaurant.cuisineTypes.contains { $0.localizedCaseInsensitiveContains(query) } ||
            restaurant.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func generateMockRestaurant(
        id: String,
        name: String,
        cuisine: [String],
        rating: Double,
        priceLevel: PriceLevel,
        distance: Double,
        waitTime: Int?
    ) -> Restaurant {
        let waitTimeData = waitTime.map { time in
            WaitTimeData(
                currentEstimate: time,
                averageByTimeSlot: [:],
                recentReports: [],
                lastUpdated: Date(),
                totalReports: Int.random(in: 10...50),
                confidenceLevel: .medium
            )
        }
        
        return Restaurant(
            id: id,
            name: name,
            description: "A great place to dine with excellent food and service.",
            address: "\(Int.random(in: 100...999)) \(["Main", "Market", "Oak", "Pine"].randomElement()!) St, San Francisco, CA",
            coordinate: CLLocationCoordinate2D(
                latitude: 37.7749 + Double.random(in: -0.05...0.05),
                longitude: -122.4194 + Double.random(in: -0.05...0.05)
            ),
            phoneNumber: "(415) 555-\(String(format: "%04d", Int.random(in: 0...9999)))",
            website: "https://\(name.lowercased().replacingOccurrences(of: " ", with: "")).com",
            priceLevel: priceLevel,
            cuisineTypes: cuisine,
            rating: rating,
            reviewCount: Int.random(in: 50...500),
            photos: [
                "https://picsum.photos/400/300?random=\(id)1",
                "https://picsum.photos/400/300?random=\(id)2"
            ],
            menu: nil,
            hours: [
                "Monday": "11:00 AM - 9:00 PM",
                "Tuesday": "11:00 AM - 9:00 PM",
                "Wednesday": "11:00 AM - 9:00 PM",
                "Thursday": "11:00 AM - 10:00 PM",
                "Friday": "11:00 AM - 10:00 PM",
                "Saturday": "10:00 AM - 10:00 PM",
                "Sunday": "10:00 AM - 9:00 PM"
            ],
            features: RestaurantFeature.allCases.shuffled().prefix(Int.random(in: 2...5)).map { $0 },
            waitTimeData: waitTimeData,
            distance: distance,
            isOpen: Bool.random(),
            yelpID: nil,
            googlePlacesID: nil,
            createdAt: Date().addingTimeInterval(-Double.random(in: 0...86400*30)),
            updatedAt: Date()
        )
    }
}

enum RestaurantSortOption: String, CaseIterable {
    case distance = "distance"
    case rating = "rating"
    case reviewCount = "review_count"
    case waitTime = "wait_time"
    case priceLevel = "price_level"
    case alphabetical = "alphabetical"
    
    var displayName: String {
        switch self {
        case .distance: return "Distance"
        case .rating: return "Rating"
        case .reviewCount: return "Most Reviewed"
        case .waitTime: return "Wait Time"
        case .priceLevel: return "Price"
        case .alphabetical: return "Name"
        }
    }
    
    var icon: String {
        switch self {
        case .distance: return "location"
        case .rating: return "star"
        case .reviewCount: return "bubble.left.and.bubble.right"
        case .waitTime: return "clock"
        case .priceLevel: return "dollarsign.circle"
        case .alphabetical: return "textformat.abc"
        }
    }
}

// MARK: - Preview Support

extension RestaurantService {
    static let preview: RestaurantService = {
        let service = RestaurantService()
        return service
    }()
}