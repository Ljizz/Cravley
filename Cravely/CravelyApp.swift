import SwiftUI
import Firebase

@main
struct CravelyApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var restaurantManager = RestaurantManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(locationManager)
                .environmentObject(restaurantManager)
        }
    }
}