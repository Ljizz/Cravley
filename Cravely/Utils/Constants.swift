import Foundation
import SwiftUI

// MARK: - App Constants

struct AppConstants {
    static let appName = "Cravely"
    static let appVersion = "1.0.0"
    static let supportEmail = "support@cravely.app"
    static let privacyPolicyURL = "https://cravely.app/privacy"
    static let termsOfServiceURL = "https://cravely.app/terms"
    
    // App Store
    static let appStoreID = "123456789"
    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"
    
    // Social Media
    static let twitterHandle = "@CravelyApp"
    static let instagramHandle = "@cravelyapp"
    
    // API
    static let baseAPIURL = "https://api.cravely.app/v1"
    static let yelpAPIURL = "https://api.yelp.com/v3"
    static let googlePlacesAPIURL = "https://maps.googleapis.com/maps/api/place"
}

// MARK: - Subscription Constants

struct SubscriptionConstants {
    static let premiumMonthlyProductID = "cravely_premium_monthly"
    static let premiumYearlyProductID = "cravely_premium_yearly"
    
    static let premiumMonthlyPrice = 3.99
    static let premiumYearlyPrice = 29.99
    static let premiumYearlySavings = (premiumMonthlyPrice * 12) - premiumYearlyPrice
    
    static let trialPeriodDays = 7
    static let maxFreeListsCount = 3
    static let maxFreeCustomFilters = 5
}

// MARK: - Location Constants

struct LocationConstants {
    static let defaultSearchRadius: Double = 5000 // 5km
    static let maxSearchRadius: Double = 50000 // 50km
    static let minSearchRadius: Double = 100 // 100m
    
    static let locationUpdateInterval: TimeInterval = 30 // seconds
    static let significantLocationChangeDistance: Double = 100 // meters
    
    // Default coordinates (San Francisco)
    static let defaultLatitude: Double = 37.7749
    static let defaultLongitude: Double = -122.4194
}

// MARK: - UI Constants

struct UIConstants {
    // Spacing
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    static let extraLargeSpacing: CGFloat = 32
    
    // Corner Radius
    static let smallCornerRadius: CGFloat = 8
    static let mediumCornerRadius: CGFloat = 12
    static let largeCornerRadius: CGFloat = 16
    static let extraLargeCornerRadius: CGFloat = 24
    
    // Shadows
    static let smallShadowRadius: CGFloat = 4
    static let mediumShadowRadius: CGFloat = 8
    static let largeShadowRadius: CGFloat = 16
    
    // Animation
    static let fastAnimationDuration: Double = 0.2
    static let mediumAnimationDuration: Double = 0.3
    static let slowAnimationDuration: Double = 0.5
    
    // Images
    static let restaurantImageHeight: CGFloat = 200
    static let profileImageSize: CGFloat = 60
    static let smallIconSize: CGFloat = 16
    static let mediumIconSize: CGFloat = 24
    static let largeIconSize: CGFloat = 32
}

// MARK: - Colors

extension Color {
    // Primary Colors
    static let primaryColor = Color("PrimaryColor")
    static let secondaryColor = Color("SecondaryColor")
    static let accentColor = Color("AccentColor")
    
    // Semantic Colors
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let infoColor = Color.blue
    
    // Grayscale
    static let lightGray = Color(.systemGray6)
    static let mediumGray = Color(.systemGray4)
    static let darkGray = Color(.systemGray2)
    
    // Wait Time Colors
    static let shortWaitColor = Color.green
    static let mediumWaitColor = Color.orange
    static let longWaitColor = Color.red
    
    // Rating Colors
    static let excellentRatingColor = Color.green
    static let goodRatingColor = Color.blue
    static let averageRatingColor = Color.orange
    static let poorRatingColor = Color.red
    
    // Subscription Colors
    static let premiumGold = Color.yellow
    static let premiumGradientStart = Color.purple
    static let premiumGradientEnd = Color.blue
}

// MARK: - Fonts

extension Font {
    // Custom font scales
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    
    static let headline = Font.headline.weight(.semibold)
    static let subheadline = Font.subheadline.weight(.medium)
    static let body = Font.body
    static let callout = Font.callout
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
    
    // Custom fonts for specific use cases
    static let restaurantName = Font.title2.weight(.semibold)
    static let restaurantCuisine = Font.subheadline.weight(.medium)
    static let rating = Font.caption.weight(.semibold)
    static let distance = Font.caption
    static let waitTime = Font.caption.weight(.medium)
    static let price = Font.subheadline.weight(.semibold)
}

// MARK: - Validation Constants

struct ValidationConstants {
    // User Input
    static let minPasswordLength = 8
    static let maxPasswordLength = 128
    static let minDisplayNameLength = 2
    static let maxDisplayNameLength = 50
    static let maxReviewLength = 1000
    static let maxReviewTitleLength = 100
    
    // Restaurant Data
    static let maxRestaurantNameLength = 100
    static let maxMenuItemNameLength = 80
    static let maxMenuItemDescriptionLength = 200
    
    // Wait Time
    static let minWaitTime = 0
    static let maxWaitTime = 120 // 2 hours
    static let waitTimeStaleThreshold: TimeInterval = 3600 // 1 hour
    
    // Rating
    static let minRating = 1
    static let maxRating = 5
}

// MARK: - Network Constants

struct NetworkConstants {
    static let requestTimeoutInterval: TimeInterval = 30
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 1
    
    // Cache
    static let imageCacheMaxSize = 100 * 1024 * 1024 // 100MB
    static let imageCacheMaxAge: TimeInterval = 7 * 24 * 3600 // 7 days
    static let dataCacheMaxAge: TimeInterval = 24 * 3600 // 24 hours
}

// MARK: - Analytics Constants

struct AnalyticsConstants {
    // Events
    static let restaurantViewed = "restaurant_viewed"
    static let searchPerformed = "search_performed"
    static let filterApplied = "filter_applied"
    static let favoriteAdded = "favorite_added"
    static let reviewSubmitted = "review_submitted"
    static let waitTimeReported = "wait_time_reported"
    static let premiumUpgrade = "premium_upgrade"
    static let locationPermissionGranted = "location_permission_granted"
    
    // User Properties
    static let userSubscriptionTier = "subscription_tier"
    static let userLocationEnabled = "location_enabled"
    static let userReviewCount = "review_count"
    static let userFavoriteCount = "favorite_count"
}

// MARK: - Feature Flags

struct FeatureFlags {
    static let enablePremiumFeatures = true
    static let enableWaitTimeReporting = true
    static let enableSocialFeatures = false
    static let enableAIRecommendations = true
    static let enableApplePayIntegration = true
    static let enableOfflineMode = false
    static let enableBetaFeatures = false
    
    #if DEBUG
    static let enableDebugFeatures = true
    static let showMockData = true
    #else
    static let enableDebugFeatures = false
    static let showMockData = false
    #endif
}

// MARK: - UserDefaults Keys

struct UserDefaultsKeys {
    static let hasCompletedOnboarding = "has_completed_onboarding"
    static let preferredSearchRadius = "preferred_search_radius"
    static let lastKnownLocation = "last_known_location"
    static let appLaunchCount = "app_launch_count"
    static let lastAppVersion = "last_app_version"
    static let hasRatedApp = "has_rated_app"
    static let notificationPermissionAsked = "notification_permission_asked"
    static let lastReviewPromptDate = "last_review_prompt_date"
    static let selectedSortOption = "selected_sort_option"
    static let enabledFilters = "enabled_filters"
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let locationPermissionChanged = Notification.Name("locationPermissionChanged")
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    static let restaurantDataUpdated = Notification.Name("restaurantDataUpdated")
    static let reviewSubmitted = Notification.Name("reviewSubmitted")
    static let waitTimeReported = Notification.Name("waitTimeReported")
    static let favoriteUpdated = Notification.Name("favoriteUpdated")
}