import Foundation

struct WaitTimeData: Codable, Hashable {
    let currentEstimate: Int? // Minutes
    let averageByTimeSlot: [TimeSlot: AverageWaitTime]
    let recentReports: [WaitTimeReport]
    let lastUpdated: Date
    let totalReports: Int
    let confidenceLevel: ConfidenceLevel
}

struct WaitTimeReport: Identifiable, Codable, Hashable {
    let id: String
    let restaurantID: String
    let userID: String?
    let reportedWaitTime: Int // Minutes
    let actualWaitTime: Int? // Minutes (if user reports back)
    let partySize: Int
    let reportedAt: Date
    let dayOfWeek: Int // 1-7, Sunday = 1
    let timeOfDay: Int // Hour in 24-hour format
    let verificationMethod: VerificationMethod
    let isAnonymous: Bool
}

struct AverageWaitTime: Codable, Hashable {
    let average: Double // Minutes
    let reportCount: Int
    let lastUpdated: Date
    let confidence: ConfidenceLevel
}

enum TimeSlot: String, Codable, CaseIterable {
    case earlyMorning = "6-9"      // 6 AM - 9 AM
    case lateMorning = "9-12"      // 9 AM - 12 PM
    case earlyAfternoon = "12-15"  // 12 PM - 3 PM
    case lateAfternoon = "15-18"   // 3 PM - 6 PM
    case earlyEvening = "18-21"    // 6 PM - 9 PM
    case lateEvening = "21-24"     // 9 PM - 12 AM
    case lateNight = "0-6"         // 12 AM - 6 AM
    
    var displayName: String {
        switch self {
        case .earlyMorning: return "6 AM - 9 AM"
        case .lateMorning: return "9 AM - 12 PM"
        case .earlyAfternoon: return "12 PM - 3 PM"
        case .lateAfternoon: return "3 PM - 6 PM"
        case .earlyEvening: return "6 PM - 9 PM"
        case .lateEvening: return "9 PM - 12 AM"
        case .lateNight: return "12 AM - 6 AM"
        }
    }
    
    static func from(hour: Int) -> TimeSlot {
        switch hour {
        case 6..<9: return .earlyMorning
        case 9..<12: return .lateMorning
        case 12..<15: return .earlyAfternoon
        case 15..<18: return .lateAfternoon
        case 18..<21: return .earlyEvening
        case 21..<24: return .lateEvening
        default: return .lateNight
        }
    }
}

enum VerificationMethod: String, Codable {
    case manual = "manual"           // User manually entered
    case checkedIn = "checked_in"    // User checked in at restaurant
    case receipt = "receipt"         // User uploaded receipt
    case gps = "gps"                // GPS verification
    case qrCode = "qr_code"         // Scanned restaurant QR code
}

enum ConfidenceLevel: String, Codable {
    case veryLow = "very_low"     // < 5 reports
    case low = "low"              // 5-15 reports
    case medium = "medium"        // 15-50 reports
    case high = "high"            // 50-100 reports
    case veryHigh = "very_high"   // 100+ reports
    
    var description: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
    
    var color: String {
        switch self {
        case .veryLow: return "red"
        case .low: return "orange"
        case .medium: return "yellow"
        case .high: return "green"
        case .veryHigh: return "blue"
        }
    }
    
    static func from(reportCount: Int) -> ConfidenceLevel {
        switch reportCount {
        case 0..<5: return .veryLow
        case 5..<15: return .low
        case 15..<50: return .medium
        case 50..<100: return .high
        default: return .veryHigh
        }
    }
}

struct WaitTimeContribution: Identifiable, Codable {
    let id: String
    let userID: String
    let reportCount: Int
    let accuracyScore: Double // 0.0 - 1.0
    let badges: [ContributorBadge]
    let lastContribution: Date
    let totalPoints: Int
}

enum ContributorBadge: String, Codable, CaseIterable {
    case firstTimer = "first_timer"
    case regular = "regular"           // 10+ reports
    case reliable = "reliable"         // High accuracy score
    case powerUser = "power_user"      // 50+ reports
    case legend = "legend"             // 100+ reports
    case earlyBird = "early_bird"      // Reports from early morning
    case nightOwl = "night_owl"        // Reports from late night
    case weekendWarrior = "weekend_warrior" // Weekend reports
    
    var displayName: String {
        switch self {
        case .firstTimer: return "First Timer"
        case .regular: return "Regular Contributor"
        case .reliable: return "Reliable Reporter"
        case .powerUser: return "Power User"
        case .legend: return "Legend"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .weekendWarrior: return "Weekend Warrior"
        }
    }
    
    var icon: String {
        switch self {
        case .firstTimer: return "🌟"
        case .regular: return "📊"
        case .reliable: return "🎯"
        case .powerUser: return "⚡"
        case .legend: return "👑"
        case .earlyBird: return "🌅"
        case .nightOwl: return "🦉"
        case .weekendWarrior: return "🎉"
        }
    }
    
    var points: Int {
        switch self {
        case .firstTimer: return 10
        case .regular: return 50
        case .reliable: return 100
        case .powerUser: return 200
        case .legend: return 500
        case .earlyBird: return 25
        case .nightOwl: return 25
        case .weekendWarrior: return 30
        }
    }
}

// MARK: - Extensions

extension WaitTimeData {
    var displayText: String {
        if let current = currentEstimate {
            let confidence = confidenceLevel.description
            return "\(current) min wait (\(confidence) confidence)"
        } else {
            return "No wait time data"
        }
    }
    
    var shortDisplayText: String {
        if let current = currentEstimate {
            return "\(current) min"
        } else {
            return "No data"
        }
    }
    
    func averageForCurrentTime() -> AverageWaitTime? {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let timeSlot = TimeSlot.from(hour: hour)
        return averageByTimeSlot[timeSlot]
    }
}

extension WaitTimeReport {
    static func create(
        restaurantID: String,
        userID: String?,
        waitTime: Int,
        partySize: Int,
        isAnonymous: Bool = false
    ) -> WaitTimeReport {
        let now = Date()
        let calendar = Calendar.current
        
        return WaitTimeReport(
            id: UUID().uuidString,
            restaurantID: restaurantID,
            userID: isAnonymous ? nil : userID,
            reportedWaitTime: waitTime,
            actualWaitTime: nil,
            partySize: partySize,
            reportedAt: now,
            dayOfWeek: calendar.component(.weekday, from: now),
            timeOfDay: calendar.component(.hour, from: now),
            verificationMethod: .manual,
            isAnonymous: isAnonymous
        )
    }
    
    var isRecent: Bool {
        Date().timeIntervalSince(reportedAt) < 3600 // Within last hour
    }
    
    var dayName: String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayOfWeek]
    }
}

// MARK: - Mock Data

extension WaitTimeData {
    static let mockData = WaitTimeData(
        currentEstimate: 15,
        averageByTimeSlot: [
            .earlyMorning: AverageWaitTime(average: 5.0, reportCount: 12, lastUpdated: Date(), confidence: .medium),
            .lateMorning: AverageWaitTime(average: 8.0, reportCount: 25, lastUpdated: Date(), confidence: .medium),
            .earlyAfternoon: AverageWaitTime(average: 12.0, reportCount: 45, lastUpdated: Date(), confidence: .high),
            .lateAfternoon: AverageWaitTime(average: 18.0, reportCount: 32, lastUpdated: Date(), confidence: .medium),
            .earlyEvening: AverageWaitTime(average: 25.0, reportCount: 67, lastUpdated: Date(), confidence: .high),
            .lateEvening: AverageWaitTime(average: 15.0, reportCount: 28, lastUpdated: Date(), confidence: .medium),
            .lateNight: AverageWaitTime(average: 3.0, reportCount: 8, lastUpdated: Date(), confidence: .low)
        ],
        recentReports: [
            WaitTimeReport(
                id: "1",
                restaurantID: "rest1",
                userID: "user1",
                reportedWaitTime: 10,
                actualWaitTime: nil,
                partySize: 2,
                reportedAt: Date().addingTimeInterval(-300), // 5 minutes ago
                dayOfWeek: Calendar.current.component(.weekday, from: Date()),
                timeOfDay: Calendar.current.component(.hour, from: Date()),
                verificationMethod: .manual,
                isAnonymous: false
            ),
            WaitTimeReport(
                id: "2",
                restaurantID: "rest1",
                userID: nil,
                reportedWaitTime: 20,
                actualWaitTime: nil,
                partySize: 4,
                reportedAt: Date().addingTimeInterval(-900), // 15 minutes ago
                dayOfWeek: Calendar.current.component(.weekday, from: Date()),
                timeOfDay: Calendar.current.component(.hour, from: Date()),
                verificationMethod: .manual,
                isAnonymous: true
            )
        ],
        lastUpdated: Date(),
        totalReports: 48,
        confidenceLevel: .medium
    )
}