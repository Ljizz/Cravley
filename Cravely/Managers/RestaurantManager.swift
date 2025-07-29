import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RestaurantManager: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var favoriteRestaurants: [Restaurant] = []
    @Published var userLists: [RestaurantList] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestore = Firestore.firestore()
    private let yelpService = YelpService()
    private let aiService = AIRecommendationService()
    
    // MARK: - Restaurant Discovery
    func searchRestaurants(near location: CLLocation, radius: Double = 5.0, filters: [RestaurantFilter] = []) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Search using Yelp API
            let yelpRestaurants = try await yelpService.searchRestaurants(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radius: Int(radius * 1609.34), // Convert miles to meters
                filters: filters
            )
            
            // Convert and merge with Firebase data
            var mergedRestaurants: [Restaurant] = []
            
            for yelpRestaurant in yelpRestaurants {
                // Check if restaurant exists in Firebase
                if let firestoreRestaurant = try await getRestaurantFromFirestore(yelpID: yelpRestaurant.yelpID ?? "") {
                    mergedRestaurants.append(firestoreRestaurant)
                } else {
                    // Save to Firebase for future reference
                    try await saveRestaurantToFirestore(yelpRestaurant)
                    mergedRestaurants.append(yelpRestaurant)
                }
            }
            
            restaurants = mergedRestaurants
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func getRestaurant(by id: String) async -> Restaurant? {
        do {
            let document = try await firestore.collection("restaurants").document(id).getDocument()
            if let data = document.data() {
                return try Firestore.Decoder().decode(Restaurant.self, from: data)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return nil
    }
    
    // MARK: - Wait Times
    func submitWaitTime(for restaurantID: String, minutes: Int, partySize: Int = 2) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let waitTime = WaitTime(minutes: minutes, userID: userID, partySize: partySize)
        
        do {
            let restaurantRef = firestore.collection("restaurants").document(restaurantID)
            try await restaurantRef.updateData([
                "waitTimes": FieldValue.arrayUnion([try Firestore.Encoder().encode(waitTime)])
            ])
            
            // Update local data
            if let index = restaurants.firstIndex(where: { $0.id == restaurantID }) {
                restaurants[index].waitTimes.append(waitTime)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Favorites
    func loadFavorites() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await firestore.collection("users")
                .document(userID)
                .collection("favorites")
                .getDocuments()
            
            var favorites: [Restaurant] = []
            for document in snapshot.documents {
                if let restaurant = try? Firestore.Decoder().decode(Restaurant.self, from: document.data()) {
                    favorites.append(restaurant)
                }
            }
            favoriteRestaurants = favorites
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleFavorite(_ restaurant: Restaurant) async {
        guard let userID = Auth.auth().currentUser?.uid,
              let restaurantID = restaurant.id else { return }
        
        let favoriteRef = firestore.collection("users")
            .document(userID)
            .collection("favorites")
            .document(restaurantID)
        
        do {
            if favoriteRestaurants.contains(where: { $0.id == restaurantID }) {
                // Remove from favorites
                try await favoriteRef.delete()
                favoriteRestaurants.removeAll { $0.id == restaurantID }
            } else {
                // Add to favorites
                let data = try Firestore.Encoder().encode(restaurant)
                try await favoriteRef.setData(data)
                favoriteRestaurants.append(restaurant)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func isFavorite(_ restaurant: Restaurant) -> Bool {
        guard let restaurantID = restaurant.id else { return false }
        return favoriteRestaurants.contains { $0.id == restaurantID }
    }
    
    // MARK: - Lists
    func loadUserLists() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await firestore.collection("restaurantLists")
                .whereField("userID", isEqualTo: userID)
                .getDocuments()
            
            var lists: [RestaurantList] = []
            for document in snapshot.documents {
                if let list = try? Firestore.Decoder().decode(RestaurantList.self, from: document.data()) {
                    lists.append(list)
                }
            }
            userLists = lists
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createList(name: String, isPublic: Bool = false) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let list = RestaurantList(name: name, userID: userID, isPublic: isPublic)
        
        do {
            let data = try Firestore.Encoder().encode(list)
            try await firestore.collection("restaurantLists").addDocument(data: data)
            userLists.append(list)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addRestaurantToList(_ restaurant: Restaurant, listID: String) async {
        guard let restaurantID = restaurant.id else { return }
        
        do {
            let listRef = firestore.collection("restaurantLists").document(listID)
            try await listRef.updateData([
                "restaurantIDs": FieldValue.arrayUnion([restaurantID])
            ])
            
            // Update local data
            if let index = userLists.firstIndex(where: { $0.id == listID }) {
                userLists[index].restaurantIDs.append(restaurantID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - AI Recommendations
    func getAIRecommendations(for user: User, location: CLLocation) async -> [Restaurant] {
        do {
            return try await aiService.getRecommendations(
                for: user,
                nearLocation: location,
                availableRestaurants: restaurants
            )
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Private Methods
    private func getRestaurantFromFirestore(yelpID: String) async throws -> Restaurant? {
        let snapshot = try await firestore.collection("restaurants")
            .whereField("yelpID", isEqualTo: yelpID)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        return try Firestore.Decoder().decode(Restaurant.self, from: document.data())
    }
    
    private func saveRestaurantToFirestore(_ restaurant: Restaurant) async throws {
        let data = try Firestore.Encoder().encode(restaurant)
        try await firestore.collection("restaurants").addDocument(data: data)
    }
}