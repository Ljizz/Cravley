import Foundation

struct Review: Identifiable, Codable {
    let id: String
    let restaurantID: String
    let userID: String
    let userName: String
    let userProfileImageURL: String?
    let rating: Int // 1-5 stars
    let title: String?
    let content: String
    let photos: [ReviewPhoto]
    let visitDate: Date?
    let createdAt: Date
    let updatedAt: Date
    let helpful: ReviewHelpfulness
    let tags: [ReviewTag]
    let mealType: MealTime?
    let partySize: Int?
    let pricePerPerson: Double?
    let isVerified: Bool
    let verificationMethod: ReviewVerificationMethod?
    let response: RestaurantResponse?
    let isAnonymous: Bool
    let reportCount: Int
    let status: ReviewStatus
}

struct ReviewPhoto: Identifiable, Codable {
    let id: String
    let imageURL: String
    let thumbnailURL: String?
    let caption: String?
    let menuItem: String?
    let uploadedAt: Date
    let orderIndex: Int
}

struct ReviewHelpfulness: Codable {
    let helpfulCount: Int
    let notHelpfulCount: Int
    let userVotes: [String: Bool] // UserID: isHelpful
    
    var totalVotes: Int {
        helpfulCount + notHelpfulCount
    }
    
    var helpfulnessRatio: Double {
        guard totalVotes > 0 else { return 0.0 }
        return Double(helpfulCount) / Double(totalVotes)
    }
    
    var score: Int {
        helpfulCount - notHelpfulCount
    }
}

enum ReviewTag: String, Codable, CaseIterable {
    // Service
    case greatService = "great_service"
    case slowService = "slow_service"
    case friendlyStaff = "friendly_staff"
    case rudeStaff = "rude_staff"
    
    // Food Quality
    case deliciousFood = "delicious_food"
    case averageFood = "average_food"
    case poorFood = "poor_food"
    case freshIngredients = "fresh_ingredients"
    case creativeDishes = "creative_dishes"
    
    // Atmosphere
    case greatAmbiance = "great_ambiance"
    case noisyEnvironment = "noisy_environment"
    case romanticSetting = "romantic_setting"
    case familyFriendly = "family_friendly"
    case trendy = "trendy"
    case cozy = "cozy"
    
    // Value
    case goodValue = "good_value"
    case overpriced = "overpriced"
    case generousPortions = "generous_portions"
    case smallPortions = "small_portions"
    
    // Experience
    case longWait = "long_wait"
    case shortWait = "short_wait"
    case reservationRecommended = "reservation_recommended"
    case walkInFriendly = "walk_in_friendly"
    case dateNight = "date_night"
    case businessMeeting = "business_meeting"
    case celebration = "celebration"
    
    // Special
    case hiddenGem = "hidden_gem"
    case touristTrap = "tourist_trap"
    case localFavorite = "local_favorite"
    case instagramWorthy = "instagram_worthy"
    
    var displayName: String {
        switch self {
        case .greatService: return "Great Service"
        case .slowService: return "Slow Service"
        case .friendlyStaff: return "Friendly Staff"
        case .rudeStaff: return "Rude Staff"
        case .deliciousFood: return "Delicious Food"
        case .averageFood: return "Average Food"
        case .poorFood: return "Poor Food"
        case .freshIngredients: return "Fresh Ingredients"
        case .creativeDishes: return "Creative Dishes"
        case .greatAmbiance: return "Great Ambiance"
        case .noisyEnvironment: return "Noisy Environment"
        case .romanticSetting: return "Romantic Setting"
        case .familyFriendly: return "Family Friendly"
        case .trendy: return "Trendy"
        case .cozy: return "Cozy"
        case .goodValue: return "Good Value"
        case .overpriced: return "Overpriced"
        case .generousPortions: return "Generous Portions"
        case .smallPortions: return "Small Portions"
        case .longWait: return "Long Wait"
        case .shortWait: return "Short Wait"
        case .reservationRecommended: return "Reservation Recommended"
        case .walkInFriendly: return "Walk-in Friendly"
        case .dateNight: return "Date Night"
        case .businessMeeting: return "Business Meeting"
        case .celebration: return "Celebration"
        case .hiddenGem: return "Hidden Gem"
        case .touristTrap: return "Tourist Trap"
        case .localFavorite: return "Local Favorite"
        case .instagramWorthy: return "Instagram Worthy"
        }
    }
    
    var category: ReviewTagCategory {
        switch self {
        case .greatService, .slowService, .friendlyStaff, .rudeStaff:
            return .service
        case .deliciousFood, .averageFood, .poorFood, .freshIngredients, .creativeDishes:
            return .food
        case .greatAmbiance, .noisyEnvironment, .romanticSetting, .familyFriendly, .trendy, .cozy:
            return .atmosphere
        case .goodValue, .overpriced, .generousPortions, .smallPortions:
            return .value
        case .longWait, .shortWait, .reservationRecommended, .walkInFriendly, .dateNight, .businessMeeting, .celebration:
            return .experience
        case .hiddenGem, .touristTrap, .localFavorite, .instagramWorthy:
            return .special
        }
    }
    
    var isPositive: Bool {
        switch self {
        case .greatService, .friendlyStaff, .deliciousFood, .freshIngredients, .creativeDishes,
             .greatAmbiance, .romanticSetting, .familyFriendly, .trendy, .cozy, .goodValue,
             .generousPortions, .shortWait, .walkInFriendly, .dateNight, .businessMeeting,
             .celebration, .hiddenGem, .localFavorite, .instagramWorthy:
            return true
        case .slowService, .rudeStaff, .averageFood, .poorFood, .noisyEnvironment, .overpriced,
             .smallPortions, .longWait, .reservationRecommended, .touristTrap:
            return false
        }
    }
    
    var emoji: String {
        switch self {
        case .greatService: return "⭐"
        case .slowService: return "🐌"
        case .friendlyStaff: return "😊"
        case .rudeStaff: return "😠"
        case .deliciousFood: return "😋"
        case .averageFood: return "😐"
        case .poorFood: return "😞"
        case .freshIngredients: return "🌿"
        case .creativeDishes: return "🎨"
        case .greatAmbiance: return "✨"
        case .noisyEnvironment: return "🔊"
        case .romanticSetting: return "💕"
        case .familyFriendly: return "👨‍👩‍👧‍👦"
        case .trendy: return "🔥"
        case .cozy: return "🛋️"
        case .goodValue: return "💰"
        case .overpriced: return "💸"
        case .generousPortions: return "🍽️"
        case .smallPortions: return "🥄"
        case .longWait: return "⏰"
        case .shortWait: return "⚡"
        case .reservationRecommended: return "📅"
        case .walkInFriendly: return "🚶"
        case .dateNight: return "💑"
        case .businessMeeting: return "💼"
        case .celebration: return "🎉"
        case .hiddenGem: return "💎"
        case .touristTrap: return "🪤"
        case .localFavorite: return "🏠"
        case .instagramWorthy: return "📸"
        }
    }
}

enum ReviewTagCategory: String, CaseIterable {
    case service = "service"
    case food = "food"
    case atmosphere = "atmosphere"
    case value = "value"
    case experience = "experience"
    case special = "special"
    
    var displayName: String {
        switch self {
        case .service: return "Service"
        case .food: return "Food"
        case .atmosphere: return "Atmosphere"
        case .value: return "Value"
        case .experience: return "Experience"
        case .special: return "Special"
        }
    }
    
    var icon: String {
        switch self {
        case .service: return "👥"
        case .food: return "🍽️"
        case .atmosphere: return "🌟"
        case .value: return "💰"
        case .experience: return "📋"
        case .special: return "✨"
        }
    }
}

enum ReviewVerificationMethod: String, Codable {
    case receipt = "receipt"           // User uploaded receipt
    case gpsCheck = "gps_check"        // GPS verification
    case checkIn = "check_in"          // Manual check-in
    case photoMetadata = "photo_metadata" // Photo location metadata
}

enum ReviewStatus: String, Codable {
    case active = "active"
    case pending = "pending"           // Under review
    case flagged = "flagged"           // Reported by users
    case removed = "removed"           // Removed by moderation
    case hidden = "hidden"             // Hidden by user
}

struct RestaurantResponse: Codable {
    let id: String
    let restaurantID: String
    let reviewID: String
    let responderName: String
    let responderTitle: String?
    let content: String
    let createdAt: Date
    let isVerified: Bool
}

// MARK: - Extensions

extension Review {
    var formattedRating: String {
        String(repeating: "⭐", count: rating) + String(repeating: "☆", count: 5 - rating)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var isRecent: Bool {
        Date().timeIntervalSince(createdAt) < 86400 * 7 // Within last week
    }
    
    var helpfulnessScore: String {
        let ratio = helpful.helpfulnessRatio
        switch ratio {
        case 0.8...:
            return "Very Helpful"
        case 0.6..<0.8:
            return "Helpful"
        case 0.4..<0.6:
            return "Somewhat Helpful"
        default:
            return "Not Very Helpful"
        }
    }
    
    var positiveTagCount: Int {
        tags.filter { $0.isPositive }.count
    }
    
    var negativeTagCount: Int {
        tags.filter { !$0.isPositive }.count
    }
    
    var overallSentiment: ReviewSentiment {
        switch rating {
        case 4...5:
            return .positive
        case 3:
            return .neutral
        default:
            return .negative
        }
    }
}

enum ReviewSentiment {
    case positive
    case neutral
    case negative
    
    var color: String {
        switch self {
        case .positive: return "green"
        case .neutral: return "yellow"
        case .negative: return "red"
        }
    }
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .neutral: return "😐"
        case .negative: return "😞"
        }
    }
}

extension ReviewHelpfulness {
    static let empty = ReviewHelpfulness(
        helpfulCount: 0,
        notHelpfulCount: 0,
        userVotes: [:]
    )
    
    func userVoted(userID: String) -> Bool? {
        userVotes[userID]
    }
    
    func withUserVote(userID: String, isHelpful: Bool) -> ReviewHelpfulness {
        var newVotes = userVotes
        let previousVote = newVotes[userID]
        newVotes[userID] = isHelpful
        
        var newHelpfulCount = helpfulCount
        var newNotHelpfulCount = notHelpfulCount
        
        // Remove previous vote if exists
        if let previous = previousVote {
            if previous {
                newHelpfulCount -= 1
            } else {
                newNotHelpfulCount -= 1
            }
        }
        
        // Add new vote
        if isHelpful {
            newHelpfulCount += 1
        } else {
            newNotHelpfulCount += 1
        }
        
        return ReviewHelpfulness(
            helpfulCount: newHelpfulCount,
            notHelpfulCount: newNotHelpfulCount,
            userVotes: newVotes
        )
    }
}

// MARK: - Mock Data

extension Review {
    static let mockReview = Review(
        id: "review1",
        restaurantID: "rest1",
        userID: "user1",
        userName: "Sarah Chen",
        userProfileImageURL: nil,
        rating: 4,
        title: "Great food, but a bit noisy",
        content: "The pasta was absolutely delicious and the service was quick. However, the restaurant was quite loud during dinner time. Perfect for casual dining with friends, but maybe not ideal for a romantic date. The portions were generous and reasonably priced. Would definitely come back!",
        photos: [
            ReviewPhoto(
                id: "photo1",
                imageURL: "https://example.com/review-photo1.jpg",
                thumbnailURL: "https://example.com/review-photo1-thumb.jpg",
                caption: "Amazing carbonara pasta",
                menuItem: "Carbonara",
                uploadedAt: Date(),
                orderIndex: 0
            )
        ],
        visitDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        helpful: ReviewHelpfulness(
            helpfulCount: 12,
            notHelpfulCount: 2,
            userVotes: [:]
        ),
        tags: [.deliciousFood, .friendlyStaff, .noisyEnvironment, .goodValue],
        mealType: .dinner,
        partySize: 3,
        pricePerPerson: 25.50,
        isVerified: true,
        verificationMethod: .receipt,
        response: nil,
        isAnonymous: false,
        reportCount: 0,
        status: .active
    )
    
    static let mockReviews: [Review] = [
        mockReview,
        Review(
            id: "review2",
            restaurantID: "rest1",
            userID: "user2",
            userName: "Mike Johnson",
            userProfileImageURL: nil,
            rating: 5,
            title: "Perfect date night spot",
            content: "My wife and I had an amazing anniversary dinner here. The ambiance was perfect, the food was exceptional, and the service was top-notch. The sommelier's wine recommendations were spot on. Highly recommend for special occasions!",
            photos: [],
            visitDate: Calendar.current.date(byAdding: .week, value: -1, to: Date()),
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            helpful: ReviewHelpfulness(
                helpfulCount: 8,
                notHelpfulCount: 0,
                userVotes: [:]
            ),
            tags: [.deliciousFood, .greatService, .romanticSetting, .celebration],
            mealType: .dinner,
            partySize: 2,
            pricePerPerson: 85.00,
            isVerified: false,
            verificationMethod: nil,
            response: RestaurantResponse(
                id: "response1",
                restaurantID: "rest1",
                reviewID: "review2",
                responderName: "Chef Antonio",
                responderTitle: "Head Chef & Owner",
                content: "Thank you so much for the wonderful review! We're thrilled that we could make your anniversary special. We look forward to welcoming you back soon!",
                createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
                isVerified: true
            ),
            isAnonymous: false,
            reportCount: 0,
            status: .active
        ),
        Review(
            id: "review3",
            restaurantID: "rest1",
            userID: "user3",
            userName: "Anonymous",
            userProfileImageURL: nil,
            rating: 2,
            title: "Disappointing experience",
            content: "The food took forever to arrive and when it did, it was cold. The server seemed overwhelmed and barely checked on us. For the price point, I expected much better. The dessert was the only redeeming part of the meal.",
            photos: [],
            visitDate: Calendar.current.date(byAdding: .week, value: -2, to: Date()),
            createdAt: Calendar.current.date(byAdding: .week, value: -1, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .week, value: -1, to: Date()) ?? Date(),
            helpful: ReviewHelpfulness(
                helpfulCount: 3,
                notHelpfulCount: 1,
                userVotes: [:]
            ),
            tags: [.slowService, .poorFood, .longWait, .overpriced],
            mealType: .dinner,
            partySize: 4,
            pricePerPerson: 45.00,
            isVerified: true,
            verificationMethod: .gpsCheck,
            response: nil,
            isAnonymous: true,
            reportCount: 0,
            status: .active
        )
    ]
}