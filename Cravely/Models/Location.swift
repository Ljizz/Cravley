import Foundation
import CoreLocation

struct SearchLocation: Identifiable, Codable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let type: LocationType
    let radius: Double // In meters
    let isUserLocation: Bool
    let lastUsed: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, type, radius, isUserLocation, lastUsed
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        type = try container.decode(LocationType.self, forKey: .type)
        radius = try container.decode(Double.self, forKey: .radius)
        isUserLocation = try container.decode(Bool.self, forKey: .isUserLocation)
        lastUsed = try container.decodeIfPresent(Date.self, forKey: .lastUsed)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encode(type, forKey: .type)
        try container.encode(radius, forKey: .radius)
        try container.encode(isUserLocation, forKey: .isUserLocation)
        try container.encodeIfPresent(lastUsed, forKey: .lastUsed)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

enum LocationType: String, Codable, CaseIterable {
    case currentLocation = "current"
    case home = "home"
    case work = "work"
    case saved = "saved"
    case recent = "recent"
    case search = "search"
    
    var displayName: String {
        switch self {
        case .currentLocation: return "Current Location"
        case .home: return "Home"
        case .work: return "Work"
        case .saved: return "Saved Location"
        case .recent: return "Recent Search"
        case .search: return "Search Result"
        }
    }
    
    var icon: String {
        switch self {
        case .currentLocation: return "📍"
        case .home: return "🏠"
        case .work: return "🏢"
        case .saved: return "⭐"
        case .recent: return "🕒"
        case .search: return "🔍"
        }
    }
}

struct LocationPermissionStatus {
    let authorizationStatus: CLAuthorizationStatus
    let accuracyAuthorization: CLAccuracyAuthorization
    let isLocationServicesEnabled: Bool
    
    var canUseLocation: Bool {
        isLocationServicesEnabled && 
        (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }
    
    var isPreciseLocationEnabled: Bool {
        accuracyAuthorization == .fullAccuracy
    }
    
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission not requested"
        case .denied:
            return "Location access denied"
        case .restricted:
            return "Location access restricted"
        case .authorizedWhenInUse:
            return "Location access granted while using app"
        case .authorizedAlways:
            return "Location access always granted"
        @unknown default:
            return "Unknown location permission status"
        }
    }
}

struct SearchArea: Codable {
    let center: CLLocationCoordinate2D
    let radius: Double // In meters
    let bounds: LocationBounds?
    
    enum CodingKeys: String, CodingKey {
        case radius, bounds
        case latitude, longitude
    }
    
    init(center: CLLocationCoordinate2D, radius: Double, bounds: LocationBounds? = nil) {
        self.center = center
        self.radius = radius
        self.bounds = bounds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        radius = try container.decode(Double.self, forKey: .radius)
        bounds = try container.decodeIfPresent(LocationBounds.self, forKey: .bounds)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(radius, forKey: .radius)
        try container.encodeIfPresent(bounds, forKey: .bounds)
        try container.encode(center.latitude, forKey: .latitude)
        try container.encode(center.longitude, forKey: .longitude)
    }
}

struct LocationBounds: Codable {
    let northeast: CLLocationCoordinate2D
    let southwest: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case northeastLatitude, northeastLongitude
        case southwestLatitude, southwestLongitude
    }
    
    init(northeast: CLLocationCoordinate2D, southwest: CLLocationCoordinate2D) {
        self.northeast = northeast
        self.southwest = southwest
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let neLat = try container.decode(Double.self, forKey: .northeastLatitude)
        let neLng = try container.decode(Double.self, forKey: .northeastLongitude)
        northeast = CLLocationCoordinate2D(latitude: neLat, longitude: neLng)
        
        let swLat = try container.decode(Double.self, forKey: .southwestLatitude)
        let swLng = try container.decode(Double.self, forKey: .southwestLongitude)
        southwest = CLLocationCoordinate2D(latitude: swLat, longitude: swLng)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(northeast.latitude, forKey: .northeastLatitude)
        try container.encode(northeast.longitude, forKey: .northeastLongitude)
        try container.encode(southwest.latitude, forKey: .southwestLatitude)
        try container.encode(southwest.longitude, forKey: .southwestLongitude)
    }
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= southwest.latitude &&
               coordinate.latitude <= northeast.latitude &&
               coordinate.longitude >= southwest.longitude &&
               coordinate.longitude <= northeast.longitude
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
    
    var formattedString: String {
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
}

extension SearchLocation {
    static func currentLocation(coordinate: CLLocationCoordinate2D) -> SearchLocation {
        SearchLocation(
            id: "current",
            name: "Current Location",
            coordinate: coordinate,
            address: nil,
            type: .currentLocation,
            radius: 1000,
            isUserLocation: true,
            lastUsed: Date()
        )
    }
    
    static let mockLocations: [SearchLocation] = [
        SearchLocation(
            id: "home",
            name: "Home",
            coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            address: "456 Oak St, San Francisco, CA",
            type: .home,
            radius: 500,
            isUserLocation: false,
            lastUsed: Date()
        ),
        SearchLocation(
            id: "work",
            name: "Work",
            coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4194),
            address: "123 Market St, San Francisco, CA",
            type: .work,
            radius: 800,
            isUserLocation: false,
            lastUsed: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        ),
        SearchLocation(
            id: "saved1",
            name: "Mission District",
            coordinate: CLLocationCoordinate2D(latitude: 37.7599, longitude: -122.4148),
            address: "Mission District, San Francisco, CA",
            type: .saved,
            radius: 1500,
            isUserLocation: false,
            lastUsed: Calendar.current.date(byAdding: .week, value: -1, to: Date())
        )
    ]
}

// MARK: - Location Utilities

struct LocationUtils {
    static func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else if meters < 10000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return String(format: "%.0f km", meters / 1000)
        }
    }
    
    static func formatWalkTime(_ meters: Double) -> String {
        let walkingSpeedMPS = 1.4 // Average walking speed in meters per second
        let seconds = meters / walkingSpeedMPS
        
        if seconds < 60 {
            return "< 1 min walk"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes) min walk"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m walk"
            } else {
                return "\(hours)h walk"
            }
        }
    }
    
    static func formatDriveTime(_ meters: Double) -> String {
        // Assume average city driving speed of 25 mph (11.2 m/s)
        let citySpeedMPS = 11.2
        let seconds = meters / citySpeedMPS
        
        if seconds < 60 {
            return "< 1 min drive"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes) min drive"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m drive"
            } else {
                return "\(hours)h drive"
            }
        }
    }
    
    static func searchRadiusOptions() -> [Double] {
        return [500, 1000, 2000, 5000, 10000, 25000] // In meters
    }
    
    static func formatSearchRadius(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return "\(Int(meters / 1000)) km"
        }
    }
}

// MARK: - Geofencing

struct GeofenceRegion: Identifiable, Codable {
    let id: String
    let name: String
    let center: CLLocationCoordinate2D
    let radius: Double
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, radius, isActive, createdAt
        case latitude, longitude
    }
    
    init(id: String, name: String, center: CLLocationCoordinate2D, radius: Double, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.center = center
        self.radius = radius
        self.isActive = isActive
        self.createdAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        radius = try container.decode(Double.self, forKey: .radius)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(radius, forKey: .radius)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(center.latitude, forKey: .latitude)
        try container.encode(center.longitude, forKey: .longitude)
    }
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return center.distance(to: coordinate) <= radius
    }
    
    var clRegion: CLCircularRegion {
        let region = CLCircularRegion(center: center, radius: radius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        return region
    }
}