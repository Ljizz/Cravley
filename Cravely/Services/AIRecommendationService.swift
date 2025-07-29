import Foundation
import CoreLocation

class AIRecommendationService {
    private let openAIAPIKey = "YOUR_OPENAI_API_KEY" // Replace with actual API key
    private let baseURL = "https://api.openai.com/v1"
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()
    
    func getRecommendations(
        for user: User,
        nearLocation location: CLLocation,
        availableRestaurants: [Restaurant]
    ) async throws -> [Restaurant] {
        
        // Create context for AI recommendation
        let context = buildRecommendationContext(user: user, restaurants: availableRestaurants)
        
        // For MVP, we'll use a simplified algorithm
        // In production, this would call OpenAI's API or use a custom ML model
        return generateSimpleRecommendations(for: user, from: availableRestaurants)
    }
    
    private func generateSimpleRecommendations(for user: User, from restaurants: [Restaurant]) -> [Restaurant] {
        var scoredRestaurants: [(Restaurant, Double)] = []
        
        for restaurant in restaurants {
            var score: Double = 0
            
            // Cuisine preference matching
            if user.preferences.cuisineTypes.contains(restaurant.cuisineType) {
                score += 3.0
            }
            
            // Price range matching
            if user.preferences.priceRange == restaurant.priceRange {
                score += 2.0
            } else {
                // Penalize for being too expensive or too cheap
                let userPriceValue = priceRangeValue(user.preferences.priceRange)
                let restaurantPriceValue = priceRangeValue(restaurant.priceRange)
                let priceDifference = abs(userPriceValue - restaurantPriceValue)
                score -= Double(priceDifference) * 0.5
            }
            
            // Rating boost
            score += restaurant.rating * 0.5
            
            // Review count boost (popularity)
            score += min(log(Double(restaurant.reviewCount + 1)) * 0.3, 1.0)
            
            // Wait time penalty
            if let waitTime = restaurant.currentWaitTime {
                score -= Double(waitTime) * 0.1
            }
            
            // Open now boost
            if restaurant.isOpen {
                score += 1.0
            }
            
            scoredRestaurants.append((restaurant, score))
        }
        
        // Sort by score and return top recommendations
        return scoredRestaurants
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }
    }
    
    private func priceRangeValue(_ priceRange: PriceRange) -> Int {
        switch priceRange {
        case .budget: return 1
        case .moderate: return 2
        case .expensive: return 3
        case .luxury: return 4
        }
    }
    
    private func buildRecommendationContext(user: User, restaurants: [Restaurant]) -> String {
        var context = "User Profile:\n"
        context += "- Preferred cuisines: \(user.preferences.cuisineTypes.joined(separator: ", "))\n"
        context += "- Price range: \(user.preferences.priceRange.description)\n"
        context += "- Dietary restrictions: \(user.preferences.dietaryRestrictions.joined(separator: ", "))\n"
        context += "- Maximum distance: \(user.preferences.maxDistance) miles\n\n"
        
        context += "Available Restaurants:\n"
        for restaurant in restaurants.prefix(10) {
            context += "- \(restaurant.name): \(restaurant.cuisineType), \(restaurant.priceRange.rawValue), Rating: \(restaurant.rating)\n"
        }
        
        return context
    }
    
    // MARK: - Future OpenAI Integration
    private func getOpenAIRecommendations(context: String) async throws -> [String] {
        let prompt = """
        Based on the following user profile and available restaurants, recommend the top 5 restaurants that would best match the user's preferences. Consider cuisine type, price range, ratings, and any dietary restrictions.
        
        \(context)
        
        Provide recommendations as a numbered list with brief explanations for each choice.
        """
        
        let request = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIMessage(role: "system", content: "You are a restaurant recommendation expert."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            max_tokens: 500
        )
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidURL
        }
        
        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        httpRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: httpRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.serverError(httpResponse.statusCode)
        }
        
        let aiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return [aiResponse.choices.first?.message.content ?? ""]
    }
}

// MARK: - OpenAI Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

enum AIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noRecommendations
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noRecommendations:
            return "No recommendations available"
        }
    }
}