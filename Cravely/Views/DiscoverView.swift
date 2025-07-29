import SwiftUI
import MapKit

struct DiscoverView: View {
    @EnvironmentObject var restaurantManager: RestaurantManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var isMapView = false
    @State private var selectedFilters: [RestaurantFilter] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search restaurants...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        isMapView.toggle()
                    }) {
                        Image(systemName: isMapView ? "list.bullet" : "map")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Content
                if isMapView {
                    RestaurantMapView(restaurants: filteredRestaurants, region: $region)
                } else {
                    RestaurantListView(restaurants: filteredRestaurants)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                requestLocationAndSearch()
            }
            .onChange(of: locationManager.location) { _ in
                updateRegionAndSearch()
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedFilters: $selectedFilters)
            }
        }
    }
    
    private var filteredRestaurants: [Restaurant] {
        var restaurants = restaurantManager.restaurants
        
        if !searchText.isEmpty {
            restaurants = restaurants.filter { restaurant in
                restaurant.name.localizedCaseInsensitiveContains(searchText) ||
                restaurant.cuisineType.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return restaurants
    }
    
    private func requestLocationAndSearch() {
        locationManager.requestLocation()
    }
    
    private func updateRegionAndSearch() {
        guard let location = locationManager.location else { return }
        
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        Task {
            await restaurantManager.searchRestaurants(
                near: location,
                filters: selectedFilters
            )
        }
    }
}

struct RestaurantListView: View {
    let restaurants: [Restaurant]
    @EnvironmentObject var restaurantManager: RestaurantManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        List(restaurants) { restaurant in
            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                RestaurantRowView(restaurant: restaurant)
            }
        }
        .refreshable {
            if let location = locationManager.location {
                await restaurantManager.searchRestaurants(near: location)
            }
        }
    }
}

struct RestaurantMapView: View {
    let restaurants: [Restaurant]
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: restaurants) { restaurant in
            MapAnnotation(coordinate: restaurant.coordinate) {
                RestaurantMapPin(restaurant: restaurant)
            }
        }
    }
}

struct RestaurantRowView: View {
    let restaurant: Restaurant
    @EnvironmentObject var restaurantManager: RestaurantManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        HStack {
            // Restaurant Image
            AsyncImage(url: URL(string: restaurant.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(restaurant.name)
                        .font(.headline)
                        .lineLimit(1)
                    
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
                    
                    // Price Range
                    Text(restaurant.priceRange.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Distance
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
                        Spacer()
                    }
                    .foregroundColor(waitTime > 30 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RestaurantMapPin: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 30, height: 30)
                
                Image(systemName: "fork.knife")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            Text(restaurant.name)
                .font(.caption)
                .padding(4)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    DiscoverView()
        .environmentObject(RestaurantManager())
        .environmentObject(LocationManager())
}