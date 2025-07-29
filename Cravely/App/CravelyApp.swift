import SwiftUI
import FirebaseCore

@main
struct CravelyApp: App {
    @StateObject private var locationService = LocationService()
    @StateObject private var userManager = UserManager()
    @StateObject private var restaurantService = RestaurantService()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure app appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationService)
                .environmentObject(userManager)
                .environmentObject(restaurantService)
                .onAppear {
                    // Request location permission on app launch
                    locationService.requestLocationPermission()
                }
        }
    }
    
    private func configureAppearance() {
        // Customize navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Customize tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}