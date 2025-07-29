import SwiftUI

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
                .onAppear {
                    // Initialize with mock data for playground
                    setupMockData()
                }
        }
    }
    
    private func setupMockData() {
        // Set up mock data for demonstration
        userManager.loadMockUser()
        restaurantService.loadMockRestaurants()
        locationService.setupMockLocation()
    }
}