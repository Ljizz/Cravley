import SwiftUI

struct CravelyPicksView: View {
    @EnvironmentObject var restaurantManager: RestaurantManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var recommendations: [Restaurant] = []
    @State private var isLoading = false
    @State private var lastUpdated: Date?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Finding your perfect picks...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if recommendations.isEmpty {
                    EmptyRecommendationsView {
                        loadRecommendations()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Header
                            RecommendationsHeader(lastUpdated: lastUpdated)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            
                            // Recommendations
                            ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, restaurant in
                                RecommendationCard(
                                    restaurant: restaurant,
                                    rank: index + 1
                                )
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                    .refreshable {
                        await loadRecommendations()
                    }
                }
            }
            .navigationTitle("Cravely Picks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await loadRecommendations()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if recommendations.isEmpty {
                    Task {
                        await loadRecommendations()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func loadRecommendations() async {
        guard let user = authManager.currentUser,
              let location = locationManager.location else { return }
        
        isLoading = true
        
        // Ensure we have restaurant data
        if restaurantManager.restaurants.isEmpty {
            await restaurantManager.searchRestaurants(near: location)
        }
        
        // Get AI recommendations
        recommendations = await restaurantManager.getAIRecommendations(
            for: user,
            location: location
        )
        
        lastUpdated = Date()
        isLoading = false
    }
}

struct RecommendationsHeader: View {
    let lastUpdated: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Personalized for You")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Text("Based on your preferences, dining history, and current location")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let lastUpdated = lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecommendationCard: View {
    let restaurant: Restaurant
    let rank: Int
    @EnvironmentObject var restaurantManager: RestaurantManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
            VStack(alignment: .leading, spacing: 0) {
                // Header with rank
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 30, height: 30)
                        
                        Text("\(rank)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("Cravely Pick #\(rank)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await restaurantManager.toggleFavorite(restaurant)
                        }
                    }) {
                        Image(systemName: restaurantManager.isFavorite(restaurant) ? "heart.fill" : "heart")
                            .foregroundColor(restaurantManager.isFavorite(restaurant) ? .red : .gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Restaurant Image
                AsyncImage(url: URL(string: restaurant.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 200)
                .clipped()
                
                // Restaurant Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(restaurant.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(restaurant.cuisineType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        // Rating
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(restaurant.rating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Text(String(format: "%.1f", restaurant.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(restaurant.priceRange.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let distance = locationManager.distance(to: restaurant) {
                            Text(String(format: "%.1f mi", distance))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Wait Time
                    if let waitTime = restaurant.currentWaitTime {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(waitTime) min wait")
                                .font(.caption)
                        }
                        .foregroundColor(waitTime > 30 ? .red : .green)
                    }
                    
                    // Why recommended
                    RecommendationReason(restaurant: restaurant)
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecommendationReason: View {
    let restaurant: Restaurant
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        let reason = generateReason()
        
        if !reason.isEmpty {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.top, 4)
        }
    }
    
    private func generateReason() -> String {
        guard let user = authManager.currentUser else { return "" }
        
        var reasons: [String] = []
        
        // Cuisine match
        if user.preferences.cuisineTypes.contains(restaurant.cuisineType) {
            reasons.append("matches your love for \(restaurant.cuisineType)")
        }
        
        // Price range match
        if user.preferences.priceRange == restaurant.priceRange {
            reasons.append("fits your \(restaurant.priceRange.description.lowercased()) budget")
        }
        
        // High rating
        if restaurant.rating >= 4.5 {
            reasons.append("highly rated by diners")
        }
        
        // Short wait time
        if let waitTime = restaurant.currentWaitTime, waitTime <= 15 {
            reasons.append("short wait time")
        }
        
        if reasons.isEmpty {
            return "Popular in your area"
        }
        
        return "Recommended because it " + reasons.prefix(2).joined(separator: " and ")
    }
}

struct EmptyRecommendationsView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Recommendations Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Text("We're learning about your preferences!")
                Text("Try exploring restaurants and saving favorites to get personalized picks.")
            }
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal, 40)
            
            Button("Get Recommendations") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
            .foregroundColor(.white)
            .tint(.orange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CravelyPicksView()
        .environmentObject(RestaurantManager())
        .environmentObject(LocationManager())
        .environmentObject(AuthenticationManager())
}