import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var restaurantService: RestaurantService
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Discovery Feed
            DiscoveryView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "location.fill" : "location")
                    Text("Discover")
                }
                .tag(0)
            
            // Search
            SearchView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    Text("Search")
                }
                .tag(1)
            
            // Favorites
            FavoritesView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "heart.fill" : "heart")
                    Text("Favorites")
                }
                .tag(2)
            
            // Profile
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(Color("PrimaryColor"))
        .onAppear {
            setupTabBar()
        }
    }
    
    private func setupTabBar() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Customize tab bar item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationService.preview)
        .environmentObject(UserManager.preview)
        .environmentObject(RestaurantService.preview)
}

// MARK: - Tab Views

struct DiscoveryView: View {
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var restaurantService: RestaurantService
    
    @State private var showingMapView = false
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with location and filters
                HeaderView(showingMapView: $showingMapView, showingFilters: $showingFilters)
                
                // Restaurant list
                RestaurantListView()
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilters) {
                FilterView()
            }
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBarView(text: $searchText, isSearching: $isSearching)
                
                if searchText.isEmpty {
                    // Recent searches and suggestions
                    RecentSearchesView()
                } else {
                    // Search results
                    SearchResultsView(query: searchText)
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FavoritesView: View {
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        NavigationView {
            VStack {
                if userManager.currentUser?.favorites.isEmpty ?? true {
                    // Empty state
                    EmptyFavoritesView()
                } else {
                    // Favorites list
                    FavoriteRestaurantsView()
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        NavigationView {
            VStack {
                if userManager.currentUser != nil {
                    // User profile
                    UserProfileView()
                } else {
                    // Sign in view
                    SignInView()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Placeholder Views

struct HeaderView: View {
    @Binding var showingMapView: Bool
    @Binding var showingFilters: Bool
    
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
            
            Button(action: { showingFilters = true }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
            }
            
            Button(action: { showingMapView.toggle() }) {
                Image(systemName: showingMapView ? "list.bullet" : "map")
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
                        Label(LocationUtils.formatDistance(distance), systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let waitTime = restaurant.waitTimeData?.currentEstimate {
                        Label("\(waitTime) min wait", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Additional Placeholder Views

struct SearchBarView: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search restaurants, cuisines...", text: $text)
                .onTapGesture {
                    isSearching = true
                }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct RecentSearchesView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Searches")
                .font(.headline)
                .padding(.horizontal)
            
            // Placeholder content
            Text("No recent searches")
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

struct SearchResultsView: View {
    let query: String
    
    var body: some View {
        Text("Search results for: \(query)")
            .padding()
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
        }
        .padding()
    }
}

struct FavoriteRestaurantsView: View {
    var body: some View {
        Text("Favorite restaurants will appear here")
            .padding()
    }
}

struct FilterView: View {
    var body: some View {
        NavigationView {
            Text("Filter options")
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct UserProfileView: View {
    var body: some View {
        Text("User profile content")
            .padding()
    }
}

struct SignInView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Welcome to Cravely")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Sign in to save favorites, write reviews, and get personalized recommendations")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Sign In") {
                // Handle sign in
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}