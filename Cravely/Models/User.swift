import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String
    let profileImageURL: String?
    let preferences: UserPreferences
    let subscription: SubscriptionStatus
    let stats: UserStats
    let favorites: [String] // Restaurant IDs
    let customLists: [RestaurantList]
    let reviewHistory: [String] // Review IDs
    let waitTimeContributions: WaitTimeContribution?
    let createdAt: Date
    let lastActiveAt: Date
    let notificationSettings: NotificationSettings
    let privacySettings: PrivacySettings
}

struct UserPreferences: Codable {
    var cuisinePreferences: [String] // Cuisine types
    var pricePreferences: [PriceLevel]
    var dietaryRestrictions: [DietaryRestriction]
    var preferredFeatures: [RestaurantFeature]
    var searchRadius: Double // In meters
    var maxWaitTime: Int? // In minutes
    var preferredMealTimes: [MealTime]
    var ambiance: [AmbianceType]
    var avoidedIngredients: [String]
    var preferredPartySize: Int
    var lastUpdated: Date
}

struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let isActive: Bool
    let startDate: Date?
    let expirationDate: Date?
    let autoRenew: Bool
    let platform: SubscriptionPlatform?
    let originalTransactionID: String?
    let currentTransactionID: String?
    let trialUsed: Bool
    let trialEndDate: Date?
    let canceledAt: Date?
    let cancelReason: String?
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
    
    var yearlyPrice: Double {
        switch self {
        case .free: return 0.0
        case .premium: return 29.99
        }
    }
    
    var features: [PremiumFeature] {
        switch self {
        case .free: return []
        case .premium: return PremiumFeature.allCases
        }
    }
}

enum SubscriptionPlatform: String, Codable {
    case appStore = "app_store"
    case googlePlay = "google_play"
    case stripe = "stripe"
}

enum PremiumFeature: String, Codable, CaseIterable {
    case aiRecommendations = "ai_recommendations"
    case smartAlerts = "smart_alerts"
    case busyHourForecasts = "busy_hour_forecasts"
    case earlyAccess = "early_access"
    case advancedFilters = "advanced_filters"
    case unlimitedLists = "unlimited_lists"
    case exportData = "export_data"
    case prioritySupport = "priority_support"
    
    var displayName: String {
        switch self {
        case .aiRecommendations: return "AI-Powered Recommendations"
        case .smartAlerts: return "Smart Location Alerts"
        case .busyHourForecasts: return "Busy Hour Forecasts"
        case .earlyAccess: return "Early Access to New Features"
        case .advancedFilters: return "Advanced Search Filters"
        case .unlimitedLists: return "Unlimited Custom Lists"
        case .exportData: return "Export Your Data"
        case .prioritySupport: return "Priority Customer Support"
        }
    }
    
    var description: String {
        switch self {
        case .aiRecommendations: return "Get personalized dining suggestions based on your taste preferences"
        case .smartAlerts: return "Receive notifications about nearby restaurants and off-peak hours"
        case .busyHourForecasts: return "See predicted busy hours to plan your visit"
        case .earlyAccess: return "Be the first to try new Cravely features"
        case .advancedFilters: return "Filter by detailed criteria like ambiance, noise level, and more"
        case .unlimitedLists: return "Create unlimited custom restaurant lists"
        case .exportData: return "Export your reviews, favorites, and dining history"
        case .prioritySupport: return "Get faster response times for support requests"
        }
    }
    
    var icon: String {
        switch self {
        case .aiRecommendations: return "🤖"
        case .smartAlerts: return "🔔"
        case .busyHourForecasts: return "📊"
        case .earlyAccess: return "🚀"
        case .advancedFilters: return "🔍"
        case .unlimitedLists: return "📋"
        case .exportData: return "💾"
        case .prioritySupport: return "⭐"
        }
    }
}

struct UserStats: Codable {
    let totalReviews: Int
    let totalPhotos: Int
    let totalWaitTimeReports: Int
    let restaurantsVisited: Int
    let favoriteCount: Int
    let listCount: Int
    let memberSince: Date
    let lastReviewDate: Date?
    let averageRating: Double?
    let helpfulVotes: Int
}

struct RestaurantList: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let restaurantIDs: [String]
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    let emoji: String?
    let color: String?
    let shareCode: String?
    let collaborators: [String]? // User IDs
}

enum MealTime: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case brunch = "brunch"
    case lunch = "lunch"
    case dinner = "dinner"
    case lateNight = "late_night"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .brunch: return "Brunch"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .lateNight: return "Late Night"
        }
    }
    
    var timeRange: String {
        switch self {
        case .breakfast: return "6:00 AM - 10:00 AM"
        case .brunch: return "10:00 AM - 3:00 PM"
        case .lunch: return "11:00 AM - 4:00 PM"
        case .dinner: return "5:00 PM - 10:00 PM"
        case .lateNight: return "10:00 PM - 2:00 AM"
        }
    }
}

enum AmbianceType: String, Codable, CaseIterable {
    case casual = "casual"
    case upscale = "upscale"
    case romantic = "romantic"
    case familyFriendly = "family_friendly"
    case businessMeeting = "business_meeting"
    case lively = "lively"
    case quiet = "quiet"
    case trendy = "trendy"
    case cozy = "cozy"
    case outdoor = "outdoor"
    
    var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .upscale: return "Upscale"
        case .romantic: return "Romantic"
        case .familyFriendly: return "Family-Friendly"
        case .businessMeeting: return "Business Meeting"
        case .lively: return "Lively"
        case .quiet: return "Quiet"
        case .trendy: return "Trendy"
        case .cozy: return "Cozy"
        case .outdoor: return "Outdoor"
        }
    }
    
    var icon: String {
        switch self {
        case .casual: return "👕"
        case .upscale: return "🍸"
        case .romantic: return "❤️"
        case .familyFriendly: return "👨‍👩‍👧‍👦"
        case .businessMeeting: return "💼"
        case .lively: return "🎉"
        case .quiet: return "🤫"
        case .trendy: return "✨"
        case .cozy: return "🛋️"
        case .outdoor: return "🌿"
        }
    }
}

struct NotificationSettings: Codable {
    var pushNotifications: Bool
    var emailNotifications: Bool
    var smartAlerts: Bool
    var waitTimeUpdates: Bool
    var newReviews: Bool
    var weeklyDigest: Bool
    var restaurantNews: Bool
    var promoOffers: Bool
    var quietHours: QuietHours?
}

struct QuietHours: Codable {
    let enabled: Bool
    let startTime: String // "22:00"
    let endTime: String   // "08:00"
    let weekends: Bool    // Apply to weekends too
}

struct PrivacySettings: Codable {
    var profileVisibility: ProfileVisibility
    var reviewVisibility: ReviewVisibility
    var locationSharing: Bool
    var analyticsOptOut: Bool
    var showInLeaderboards: Bool
    var allowFriendRequests: Bool
}

enum ProfileVisibility: String, Codable {
    case everyone = "everyone"
    case friends = "friends"
    case hidden = "hidden"
}

enum ReviewVisibility: String, Codable {
    case everyone = "everyone"
    case friends = "friends"
    case anonymous = "anonymous"
}

// MARK: - Extensions

extension User {
    var isPremium: Bool {
        subscription.tier == .premium && subscription.isActive
    }
    
    var canAccessFeature(_ feature: PremiumFeature) -> Bool {
        isPremium || subscription.tier.features.contains(feature)
    }
    
    var displayTitle: String {
        if isPremium {
            return "Premium Member"
        } else if let contribution = waitTimeContributions,
                  contribution.reportCount > 50 {
            return "Community Contributor"
        } else {
            return "Food Explorer"
        }
    }
    
    var membershipBadge: String {
        if isPremium {
            return "👑"
        } else if let contribution = waitTimeContributions,
                  contribution.badges.contains(.legend) {
            return "🏆"
        } else {
            return "🍽️"
        }
    }
}

extension UserPreferences {
    static let defaultPreferences = UserPreferences(
        cuisinePreferences: [],
        pricePreferences: [.budget, .moderate],
        dietaryRestrictions: [],
        preferredFeatures: [.dineIn, .wifi],
        searchRadius: 5000, // 5km
        maxWaitTime: 30,
        preferredMealTimes: [.lunch, .dinner],
        ambiance: [.casual],
        avoidedIngredients: [],
        preferredPartySize: 2,
        lastUpdated: Date()
    )
}

extension SubscriptionStatus {
    static let freeUser = SubscriptionStatus(
        tier: .free,
        isActive: true,
        startDate: nil,
        expirationDate: nil,
        autoRenew: false,
        platform: nil,
        originalTransactionID: nil,
        currentTransactionID: nil,
        trialUsed: false,
        trialEndDate: nil,
        canceledAt: nil,
        cancelReason: nil
    )
    
    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expirationDate).day
        return days
    }
    
    var isInTrial: Bool {
        guard let trialEndDate = trialEndDate else { return false }
        return Date() < trialEndDate && isActive
    }
}

// MARK: - Mock Data

extension User {
    static let mockUser = User(
        id: "user123",
        email: "john@example.com",
        displayName: "John Doe",
        profileImageURL: nil,
        preferences: .defaultPreferences,
        subscription: .freeUser,
        stats: UserStats(
            totalReviews: 15,
            totalPhotos: 32,
            totalWaitTimeReports: 8,
            restaurantsVisited: 45,
            favoriteCount: 12,
            listCount: 3,
            memberSince: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            lastReviewDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            averageRating: 4.2,
            helpfulVotes: 28
        ),
        favorites: ["rest1", "rest2", "rest3"],
        customLists: [
            RestaurantList(
                id: "list1",
                name: "Date Night",
                description: "Perfect spots for romantic dinners",
                restaurantIDs: ["rest1", "rest4"],
                isPublic: false,
                createdAt: Date(),
                updatedAt: Date(),
                emoji: "❤️",
                color: "red",
                shareCode: nil,
                collaborators: nil
            )
        ],
        reviewHistory: ["review1", "review2"],
        waitTimeContributions: WaitTimeContribution(
            id: "contrib1",
            userID: "user123",
            reportCount: 8,
            accuracyScore: 0.85,
            badges: [.firstTimer, .reliable],
            lastContribution: Date(),
            totalPoints: 120
        ),
        createdAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
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
            quietHours: QuietHours(
                enabled: true,
                startTime: "22:00",
                endTime: "08:00",
                weekends: false
            )
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
}