import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var error: UserError?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    enum UserError: Error, LocalizedError {
        case signInFailed(String)
        case signUpFailed(String)
        case profileUpdateFailed
        case networkError
        case userNotFound
        
        var errorDescription: String? {
            switch self {
            case .signInFailed(let message):
                return "Sign in failed: \(message)"
            case .signUpFailed(let message):
                return "Sign up failed: \(message)"
            case .profileUpdateFailed:
                return "Failed to update profile"
            case .networkError:
                return "Network error occurred"
            case .userNotFound:
                return "User not found"
            }
        }
    }
    
    init() {
        setupAuthStateListener()
        loadMockUser() // For preview/development
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication
    
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isSignedIn = user != nil
                if let user = user {
                    await self?.loadUserProfile(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await loadUserProfile(uid: result.user.uid)
        } catch {
            self.error = .signInFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        error = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Create user profile in Firestore
            await createUserProfile(uid: result.user.uid, email: email, displayName: displayName)
            
        } catch {
            self.error = .signUpFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            isSignedIn = false
        } catch {
            self.error = .signInFailed(error.localizedDescription)
        }
    }
    
    func resetPassword(email: String) async {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            self.error = .signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - User Profile Management
    
    private func createUserProfile(uid: String, email: String, displayName: String) async {
        let newUser = User(
            id: uid,
            email: email,
            displayName: displayName,
            profileImageURL: nil,
            preferences: .defaultPreferences,
            subscription: .freeUser,
            stats: UserStats(
                totalReviews: 0,
                totalPhotos: 0,
                totalWaitTimeReports: 0,
                restaurantsVisited: 0,
                favoriteCount: 0,
                listCount: 0,
                memberSince: Date(),
                lastReviewDate: nil,
                averageRating: nil,
                helpfulVotes: 0
            ),
            favorites: [],
            customLists: [],
            reviewHistory: [],
            waitTimeContributions: nil,
            createdAt: Date(),
            lastActiveAt: Date(),
            notificationSettings: NotificationSettings(
                pushNotifications: true,
                emailNotifications: true,
                smartAlerts: false,
                waitTimeUpdates: true,
                newReviews: true,
                weeklyDigest: true,
                restaurantNews: false,
                promoOffers: false,
                quietHours: nil
            ),
            privacySettings: PrivacySettings(
                profileVisibility: .friends,
                reviewVisibility: .everyone,
                locationSharing: true,
                analyticsOptOut: false,
                showInLeaderboards: true,
                allowFriendRequests: true
            )
        )
        
        do {
            try await saveUserProfile(newUser)
            currentUser = newUser
        } catch {
            self.error = .profileUpdateFailed
        }
    }
    
    private func loadUserProfile(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if let data = document.data() {
                // In a real implementation, decode from Firestore data
                // For now, use mock data
                currentUser = User.mockUser
            } else {
                // User profile doesn't exist, create default profile
                guard let firebaseUser = auth.currentUser else { return }
                await createUserProfile(
                    uid: uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName ?? "User"
                )
            }
        } catch {
            self.error = .userNotFound
        }
    }
    
    private func saveUserProfile(_ user: User) async throws {
        // In a real implementation, encode and save to Firestore
        // For now, just store locally
        currentUser = user
    }
    
    func updateUserProfile(_ updatedUser: User) async {
        do {
            try await saveUserProfile(updatedUser)
        } catch {
            self.error = .profileUpdateFailed
        }
    }
    
    // MARK: - Favorites Management
    
    func addToFavorites(restaurantId: String) async {
        guard var user = currentUser else { return }
        
        if !user.favorites.contains(restaurantId) {
            var updatedUser = user
            // Create new user with updated favorites
            let newFavorites = user.favorites + [restaurantId]
            let newStats = UserStats(
                totalReviews: user.stats.totalReviews,
                totalPhotos: user.stats.totalPhotos,
                totalWaitTimeReports: user.stats.totalWaitTimeReports,
                restaurantsVisited: user.stats.restaurantsVisited,
                favoriteCount: newFavorites.count,
                listCount: user.stats.listCount,
                memberSince: user.stats.memberSince,
                lastReviewDate: user.stats.lastReviewDate,
                averageRating: user.stats.averageRating,
                helpfulVotes: user.stats.helpfulVotes
            )
            
            // This is a simplified approach - in reality, we'd need proper data mutation
            currentUser = User(
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                profileImageURL: user.profileImageURL,
                preferences: user.preferences,
                subscription: user.subscription,
                stats: newStats,
                favorites: newFavorites,
                customLists: user.customLists,
                reviewHistory: user.reviewHistory,
                waitTimeContributions: user.waitTimeContributions,
                createdAt: user.createdAt,
                lastActiveAt: Date(),
                notificationSettings: user.notificationSettings,
                privacySettings: user.privacySettings
            )
            
            await updateUserProfile(currentUser!)
        }
    }
    
    func removeFromFavorites(restaurantId: String) async {
        guard var user = currentUser else { return }
        
        if user.favorites.contains(restaurantId) {
            let newFavorites = user.favorites.filter { $0 != restaurantId }
            let newStats = UserStats(
                totalReviews: user.stats.totalReviews,
                totalPhotos: user.stats.totalPhotos,
                totalWaitTimeReports: user.stats.totalWaitTimeReports,
                restaurantsVisited: user.stats.restaurantsVisited,
                favoriteCount: newFavorites.count,
                listCount: user.stats.listCount,
                memberSince: user.stats.memberSince,
                lastReviewDate: user.stats.lastReviewDate,
                averageRating: user.stats.averageRating,
                helpfulVotes: user.stats.helpfulVotes
            )
            
            currentUser = User(
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                profileImageURL: user.profileImageURL,
                preferences: user.preferences,
                subscription: user.subscription,
                stats: newStats,
                favorites: newFavorites,
                customLists: user.customLists,
                reviewHistory: user.reviewHistory,
                waitTimeContributions: user.waitTimeContributions,
                createdAt: user.createdAt,
                lastActiveAt: Date(),
                notificationSettings: user.notificationSettings,
                privacySettings: user.privacySettings
            )
            
            await updateUserProfile(currentUser!)
        }
    }
    
    func isFavorite(restaurantId: String) -> Bool {
        return currentUser?.favorites.contains(restaurantId) ?? false
    }
    
    // MARK: - Custom Lists Management
    
    func createCustomList(name: String, description: String?, emoji: String?) async {
        guard var user = currentUser else { return }
        
        let newList = RestaurantList(
            id: UUID().uuidString,
            name: name,
            description: description,
            restaurantIDs: [],
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date(),
            emoji: emoji,
            color: nil,
            shareCode: nil,
            collaborators: nil
        )
        
        let newLists = user.customLists + [newList]
        // Update user with new list - simplified approach
        await updateUserProfile(currentUser!)
    }
    
    func addToList(restaurantId: String, listId: String) async {
        // Implementation for adding restaurant to custom list
    }
    
    func removeFromList(restaurantId: String, listId: String) async {
        // Implementation for removing restaurant from custom list
    }
    
    // MARK: - Preferences Management
    
    func updatePreferences(_ preferences: UserPreferences) async {
        guard var user = currentUser else { return }
        
        // Create updated user with new preferences
        currentUser = User(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            profileImageURL: user.profileImageURL,
            preferences: preferences,
            subscription: user.subscription,
            stats: user.stats,
            favorites: user.favorites,
            customLists: user.customLists,
            reviewHistory: user.reviewHistory,
            waitTimeContributions: user.waitTimeContributions,
            createdAt: user.createdAt,
            lastActiveAt: Date(),
            notificationSettings: user.notificationSettings,
            privacySettings: user.privacySettings
        )
        
        await updateUserProfile(currentUser!)
    }
    
    // MARK: - Mock Data (for development)
    
    private func loadMockUser() {
        // For development/preview purposes
        #if DEBUG
        currentUser = User.mockUser
        isSignedIn = true
        #endif
    }
}

// MARK: - Preview Support

extension UserManager {
    static let preview: UserManager = {
        let manager = UserManager()
        manager.currentUser = User.mockUser
        manager.isSignedIn = true
        return manager
    }()
}