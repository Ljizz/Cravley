import SwiftUI
import Foundation
import CoreLocation
import Combine

// MARK: - Main App Entry Point
@main
struct CravelyApp: App {
    @StateObject private var locationService = LocationService()
    @StateObject private var userManager = UserManager()
    @StateObject private var restaurantService = RestaurantService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationService)
                .environmentObject(userManager)
                .environmentObject(restaurantService)
        }
    }
}

// MARK: - Constants
struct AppConstants {
    static let appName = "Cravely"
    static let appVersion = "1.0.0"
    static let defaultSearchRadius: Double = 5000 // 5km
}

// MARK: - Extensions
extension Color {
    static let primaryColor = Color.blue
    static let secondaryColor = Color.gray
    static let shortWaitColor = Color.green
    static let mediumWaitColor = Color.orange
    static let longWaitColor = Color.red
}

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

// MARK: - Data Models

// Restaurant Model
struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let address: String
    let latitude: Double
    let longitude: Double
    let phoneNumber: String?
    let website: String?
    let priceLevel: PriceLevel
    let cuisineTypes: [String]
    let rating: Double
    let reviewCount: Int
    let photos: [String]
    let features: [RestaurantFeature]
    let waitTimeData: WaitTimeData?
    let distance: Double?
    let isOpen: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
}

enum RestaurantFeature: String, Codable, CaseIterable {
    case delivery = "delivery"
    case takeout = "takeout"
    case dineIn = "dine_in"
    case wifi = "wifi"
    case parking = "parking"
    case outdoorSeating = "outdoor_seating"
    
    var displayName: String {
        switch self {
        case .delivery: return "Delivery"
        case .takeout: return "Takeout"
        case .dineIn: return "Dine In"
        case .wifi: return "WiFi"
        case .parking: return "Parking"
        case .outdoorSeating: return "Outdoor Seating"
        }
    }
    
    var icon: String {
        switch self {
        case .delivery: return "🚚"
        case .takeout: return "🥡"
        case .dineIn: return "🍽️"
        case .wifi: return "📶"
        case .parking: return "🅿️"
        case .outdoorSeating: return "🌤️"
        }
    }
}

// Wait Time Model
struct WaitTimeData: Codable, Hashable {
    let currentEstimate: Int? // Minutes
    let lastUpdated: Date
    let totalReports: Int
    let confidenceLevel: ConfidenceLevel
    
    var displayText: String {
        if let current = currentEstimate {
            return "\(current) min wait"
        } else {
            return "No wait data"
        }
    }
    
    var waitColor: Color {
        guard let estimate = currentEstimate else { return .gray }
        switch estimate {
        case 0...15: return .shortWaitColor
        case 16...30: return .mediumWaitColor
        default: return .longWaitColor
        }
    }
}

enum ConfidenceLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var description: String {
        switch self {
        case .low: return "Low confidence"
        case .medium: return "Medium confidence"
        case .high: return "High confidence"
        }
    }
}

// User Model
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String
    let profileImageURL: String?
    let preferences: UserPreferences
    let subscription: SubscriptionStatus
    let favorites: [String] // Restaurant IDs
    let createdAt: Date
    
    var isPremium: Bool {
        subscription.tier == .premium && subscription.isActive
    }
}

struct UserPreferences: Codable {
    var cuisinePreferences: [String]
    var pricePreferences: [PriceLevel]
    var searchRadius: Double
    var maxWaitTime: Int?
    
    static let defaultPreferences = UserPreferences(
        cuisinePreferences: [],
        pricePreferences: [.budget, .moderate],
        searchRadius: 5000,
        maxWaitTime: 30
    )
}

struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let isActive: Bool
    let startDate: Date?
    let expirationDate: Date?
    
    static let freeUser = SubscriptionStatus(
        tier: .free,
        isActive: true,
        startDate: nil,
        expirationDate: nil
    )
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
    
    var monthlyPrice: Double {
        switch self {
        case .free: return 0.0
        case .premium: return 3.99
        }
    }
}

// Review Model
struct Review: Identifiable, Codable {
    let id: String
    let restaurantID: String
    let userID: String
    let userName: String
    let rating: Int // 1-5 stars
    let title: String?
    let content: String
    let photos: [String]
    let createdAt: Date
    let isVerified: Bool
    
    var formattedRating: String {
        String(repeating: "⭐", count: rating) + String(repeating: "☆", count: 5 - rating)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Services

// Location Service
@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationServicesEnabled: Bool = false
    @Published var locationError: LocationError?
    
    private let locationManager = CLLocationManager()
    
    enum LocationError: Error, LocalizedError {
        case permissionDenied
        case locationServicesDisabled
        case unableToLocate
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission is required to find nearby restaurants"
            case .locationServicesDisabled:
                return "Location services are disabled"
            case .unableToLocate:
                return "Unable to determine your current location"
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
        setupMockLocation() // For demo purposes
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    func setupMockLocation() {
        // Mock location for demo (San Francisco)
        currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
    
    func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = .locationServicesDisabled
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationError = .unableToLocate
        }
    }
    
    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationError = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = .unableToLocate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
            locationError = nil
        case .denied, .restricted:
            locationError = .permissionDenied
            currentLocation = nil
        case .notDetermined:
            break
        @unknown default:
            locationError = .unableToLocate
        }
    }
}

// Restaurant Service
@MainActor
class RestaurantService: ObservableObject {
    @Published var nearbyRestaurants: [Restaurant] = []
    @Published var searchResults: [Restaurant] = []
    @Published var isLoading = false
    @Published var error: RestaurantError?
    
    enum RestaurantError: Error, LocalizedError {
        case networkError
        case locationRequired
        case noResults
        
        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Network connection error"
            case .locationRequired:
                return "Location access required to find nearby restaurants"
            case .noResults:
                return "No restaurants found in this area"
            }
        }
    }
    
    init() {
        loadMockRestaurants()
    }
    
    func loadMockRestaurants() {
        nearbyRestaurants = [
            Restaurant(
                id: "1",
                name: "The Gourmet Kitchen",
                description: "Contemporary American cuisine with locally sourced ingredients",
                address: "123 Main St, San Francisco, CA 94102",
                latitude: 37.7749,
                longitude: -122.4194,
                phoneNumber: "(415) 555-0123",
                website: "https://thegourmetkitchen.com",
                priceLevel: .moderate,
                cuisineTypes: ["American", "Contemporary"],
                rating: 4.5,
                reviewCount: 234,
                photos: ["https://picsum.photos/400/300?random=1"],
                features: [.dineIn, .takeout, .wifi, .parking],
                waitTimeData: WaitTimeData(
                    currentEstimate: 15,
                    lastUpdated: Date(),
                    totalReports: 48,
                    confidenceLevel: .medium
                ),
                distance: 250.0,
                isOpen: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Restaurant(
                id: "2",
                name: "Pasta Paradise",
                description: "Authentic Italian pasta and pizza",
                address: "456 Oak St, San Francisco, CA 94102",
                latitude: 37.7849,
                longitude: -122.4094,
                phoneNumber: "(415) 555-0456",
                website: "https://pastaparadise.com",
                priceLevel: .moderate,
                cuisineTypes: ["Italian"],
                rating: 4.3,
                reviewCount: 189,
                photos: ["https://picsum.photos/400/300?random=2"],
                features: [.dineIn, .takeout, .delivery],
                waitTimeData: WaitTimeData(
                    currentEstimate: 25,
                    lastUpdated: Date(),
                    totalReports: 32,
                    confidenceLevel: .medium
                ),
                distance: 400.0,
                isOpen: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Restaurant(
                id: "3",
                name: "Sushi Zen",
                description: "Fresh sushi and Japanese cuisine",
                address: "789 Pine St, San Francisco, CA 94102",
                latitude: 37.7649,
                longitude: -122.4294,
                phoneNumber: "(415) 555-0789",
                website: "https://sushizen.com",
                priceLevel: .expensive,
                cuisineTypes: ["Japanese", "Sushi"],
                rating: 4.7,
                reviewCount: 156,
                photos: ["https://picsum.photos/400/300?random=3"],
                features: [.dineIn, .takeout],
                waitTimeData: WaitTimeData(
                    currentEstimate: 45,
                    lastUpdated: Date(),
                    totalReports: 67,
                    confidenceLevel: .high
                ),
                distance: 800.0,
                isOpen: true,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    func fetchNearbyRestaurants(location: CLLocation) async {
        isLoading = true
        error = nil
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func searchRestaurants(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        // Filter existing restaurants based on search query
        let results = nearbyRestaurants.filter { restaurant in
            restaurant.name.localizedCaseInsensitiveContains(query) ||
            restaurant.cuisineTypes.contains { $0.localizedCaseInsensitiveContains(query) }
        }
        
        await MainActor.run {
            self.searchResults = results
            self.isLoading = false
        }
    }
}

// User Manager
@MainActor
class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var error: UserError?
    
    enum UserError: Error, LocalizedError {
        case signInFailed(String)
        case profileUpdateFailed
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .signInFailed(let message):
                return "Sign in failed: \(message)"
            case .profileUpdateFailed:
                return "Failed to update profile"
            case .networkError:
                return "Network error occurred"
            }
        }
    }
    
    init() {
        loadMockUser()
    }
    
    func loadMockUser() {
        currentUser = User(
            id: "user123",
            email: "john@example.com",
            displayName: "John Doe",
            profileImageURL: nil,
            preferences: .defaultPreferences,
            subscription: .freeUser,
            favorites: ["1", "3"],
            createdAt: Date()
        )
        isSignedIn = true
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        // Simulate sign in
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            self.loadMockUser()
            self.isLoading = false
        }
    }
    
    func signOut() {
        currentUser = nil
        isSignedIn = false
    }
    
    func isFavorite(restaurantId: String) -> Bool {
        return currentUser?.favorites.contains(restaurantId) ?? false
    }
    
    func toggleFavorite(restaurantId: String) {
        guard var user = currentUser else { return }
        
        var newFavorites = user.favorites
        if newFavorites.contains(restaurantId) {
            newFavorites.removeAll { $0 == restaurantId }
        } else {
            newFavorites.append(restaurantId)
        }
        
        // Create new user with updated favorites
        currentUser = User(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            profileImageURL: user.profileImageURL,
            preferences: user.preferences,
            subscription: user.subscription,
            favorites: newFavorites,
            createdAt: user.createdAt
        )
    }
}

// MARK: - Views

struct ContentView: View {
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var restaurantService: RestaurantService
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoveryView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "location.fill" : "location")
                    Text("Discover")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    Text("Search")
                }
                .tag(1)
            
            FavoritesView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "heart.fill" : "heart")
                    Text("Favorites")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.primaryColor)
    }
}

struct DiscoveryView: View {
    @EnvironmentObject private var restaurantService: RestaurantService
    @EnvironmentObject private var locationService: LocationService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView()
                RestaurantListView()
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Current Location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("San Francisco, CA")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
            }
            
            Button(action: {}) {
                Image(systemName: "map")
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct RestaurantListView: View {
    @EnvironmentObject private var restaurantService: RestaurantService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(restaurantService.nearbyRestaurants) { restaurant in
                    RestaurantCardView(restaurant: restaurant)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct RestaurantCardView: View {
    let restaurant: Restaurant
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Restaurant image
            AsyncImage(url: URL(string: restaurant.photos.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(12)
            .overlay(
                // Favorite button
                Button(action: {
                    userManager.toggleFavorite(restaurantId: restaurant.id)
                }) {
                    Image(systemName: userManager.isFavorite(restaurantId: restaurant.id) ? "heart.fill" : "heart")
                        .foregroundColor(userManager.isFavorite(restaurantId: restaurant.id) ? .red : .white)
                        .font(.title3)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(12),
                alignment: .topTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                // Name and rating
                HStack {
                    Text(restaurant.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("(\(restaurant.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Cuisine and price
                HStack {
                    Text(restaurant.cuisineTypes.prefix(2).joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(restaurant.priceLevel.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Distance and wait time
                HStack {
                    if let distance = restaurant.distance {
                        Label(formatDistance(distance), systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let waitTimeData = restaurant.waitTimeData {
                        Label(waitTimeData.displayText, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(waitTimeData.waitColor)
                    }
                }
                
                // Features
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(restaurant.features, id: \.self) { feature in
                            HStack(spacing: 4) {
                                Text(feature.icon)
                                    .font(.caption)
                                Text(feature.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""
    @EnvironmentObject private var restaurantService: RestaurantService
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBarView(text: $searchText)
                    .onChange(of: searchText) { newValue in
                        Task {
                            await restaurantService.searchRestaurants(query: newValue)
                        }
                    }
                
                if searchText.isEmpty {
                    RecentSearchesView()
                } else {
                    SearchResultsView()
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search restaurants, cuisines...", text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct RecentSearchesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Cuisines")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(["Italian", "Japanese", "Mexican", "Chinese", "American", "Thai"], id: \.self) { cuisine in
                    Button(action: {}) {
                        Text(cuisine)
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SearchResultsView: View {
    @EnvironmentObject private var restaurantService: RestaurantService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(restaurantService.searchResults) { restaurant in
                    RestaurantCardView(restaurant: restaurant)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct FavoritesView: View {
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var restaurantService: RestaurantService
    
    var favoriteRestaurants: [Restaurant] {
        guard let user = userManager.currentUser else { return [] }
        return restaurantService.nearbyRestaurants.filter { restaurant in
            user.favorites.contains(restaurant.id)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if favoriteRestaurants.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteRestaurants) { restaurant in
                                RestaurantCardView(restaurant: restaurant)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start exploring and save your favorite restaurants")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct ProfileView: View {
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = userManager.currentUser {
                    UserProfileView(user: user)
                } else {
                    SignInView()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct UserProfileView: View {
    let user: User
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile Header
            VStack(spacing: 12) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(user.displayName.prefix(1)))
                            .font(.title)
                            .fontWeight(.semibold)
                    )
                
                Text(user.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Subscription status
                HStack {
                    Image(systemName: user.isPremium ? "crown.fill" : "person.circle")
                        .foregroundColor(user.isPremium ? .yellow : .gray)
                    Text(user.subscription.tier.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            
            // Stats
            HStack(spacing: 32) {
                StatView(title: "Favorites", value: "\(user.favorites.count)")
                StatView(title: "Reviews", value: "0")
                StatView(title: "Check-ins", value: "0")
            }
            
            // Menu Options
            VStack(spacing: 0) {
                MenuRowView(icon: "gear", title: "Settings", action: {})
                MenuRowView(icon: "crown", title: "Upgrade to Premium", action: {})
                MenuRowView(icon: "questionmark.circle", title: "Help & Support", action: {})
                MenuRowView(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", action: {
                    userManager.signOut()
                })
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MenuRowView: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primaryColor)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryColor)
                
                Text("Welcome to Cravely")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Sign in to save favorites, write reviews, and get personalized recommendations")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Sign In") {
                    Task {
                        await userManager.signIn(email: email, password: password)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty)
            }
            .padding(.horizontal)
            
            if userManager.isLoading {
                ProgressView()
            }
            
            if let error = userManager.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
    }
}