import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var accuracyAuthorization: CLAccuracyAuthorization = .reducedAccuracy
    @Published var isLocationServicesEnabled: Bool = false
    @Published var locationError: LocationError?
    @Published var savedLocations: [SearchLocation] = []
    @Published var recentSearches: [SearchLocation] = []
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    enum LocationError: Error, LocalizedError {
        case permissionDenied
        case locationServicesDisabled
        case unableToLocate
        case geocodingFailed
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission is required to find nearby restaurants"
            case .locationServicesDisabled:
                return "Location services are disabled. Please enable them in Settings"
            case .unableToLocate:
                return "Unable to determine your current location"
            case .geocodingFailed:
                return "Unable to convert address to location"
            case .networkError:
                return "Network error while accessing location services"
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
        loadSavedLocations()
        loadRecentSearches()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        // Update initial state
        authorizationStatus = locationManager.authorizationStatus
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        
        if #available(iOS 14.0, *) {
            accuracyAuthorization = locationManager.accuracyAuthorization
        }
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = .locationServicesDisabled
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationError = .unableToLocate
        }
    }
    
    func startLocationUpdates() {
        guard canUseLocation else {
            locationError = .permissionDenied
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestOneTimeLocation() async {
        guard canUseLocation else {
            locationError = .permissionDenied
            return
        }
        
        locationManager.requestLocation()
    }
    
    // MARK: - Location Search
    
    func searchLocations(query: String) async -> [SearchLocation] {
        guard !query.isEmpty else { return [] }
        
        // For now, return mock results. In a real implementation, 
        // this would integrate with MapKit or another geocoding service
        return [
            SearchLocation(
                id: UUID().uuidString,
                name: "\(query) - Sample Location 1",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                address: "123 Main St, San Francisco, CA",
                type: .search,
                radius: 1000,
                isUserLocation: false,
                lastUsed: nil
            ),
            SearchLocation(
                id: UUID().uuidString,
                name: "\(query) - Sample Location 2",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                address: "456 Market St, San Francisco, CA",
                type: .search,
                radius: 1000,
                isUserLocation: false,
                lastUsed: nil
            )
        ]
    }
    
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    self.locationError = .geocodingFailed
                    continuation.resume(returning: nil)
                    return
                }
                
                let coordinate = placemarks?.first?.location?.coordinate
                continuation.resume(returning: coordinate)
            }
        }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        return await withCheckedContinuation { continuation in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.postalCode
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    continuation.resume(returning: address.isEmpty ? nil : address)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Saved Locations
    
    func saveLocation(_ location: SearchLocation) {
        var updatedLocation = location
        
        // Update existing location or add new one
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations[index] = updatedLocation
        } else {
            savedLocations.append(updatedLocation)
        }
        
        persistSavedLocations()
    }
    
    func removeLocation(_ location: SearchLocation) {
        savedLocations.removeAll { $0.id == location.id }
        persistSavedLocations()
    }
    
    func addToRecentSearches(_ location: SearchLocation) {
        var updatedLocation = location
        
        // Remove if already exists
        recentSearches.removeAll { $0.id == location.id }
        
        // Add to front
        recentSearches.insert(updatedLocation, at: 0)
        
        // Keep only last 10 searches
        if recentSearches.count > 10 {
            recentSearches.removeLast(recentSearches.count - 10)
        }
        
        persistRecentSearches()
    }
    
    func clearRecentSearches() {
        recentSearches.removeAll()
        persistRecentSearches()
    }
    
    // MARK: - Computed Properties
    
    var canUseLocation: Bool {
        isLocationServicesEnabled &&
        (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }
    
    var isPreciseLocationEnabled: Bool {
        if #available(iOS 14.0, *) {
            return accuracyAuthorization == .fullAccuracy
        }
        return true
    }
    
    var permissionStatus: LocationPermissionStatus {
        LocationPermissionStatus(
            authorizationStatus: authorizationStatus,
            accuracyAuthorization: accuracyAuthorization,
            isLocationServicesEnabled: isLocationServicesEnabled
        )
    }
    
    var currentSearchLocation: SearchLocation? {
        guard let location = currentLocation else { return nil }
        return SearchLocation.currentLocation(coordinate: location.coordinate)
    }
    
    // MARK: - Persistence
    
    private func loadSavedLocations() {
        if let data = UserDefaults.standard.data(forKey: "saved_locations"),
           let locations = try? JSONDecoder().decode([SearchLocation].self, from: data) {
            savedLocations = locations
        }
    }
    
    private func persistSavedLocations() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(data, forKey: "saved_locations")
        }
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "recent_searches"),
           let searches = try? JSONDecoder().decode([SearchLocation].self, from: data) {
            recentSearches = searches
        }
    }
    
    private func persistRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "recent_searches")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationError = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        locationError = .unableToLocate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
            locationError = nil
        case .denied, .restricted:
            locationError = .permissionDenied
            currentLocation = nil
        case .notDetermined:
            break
        @unknown default:
            locationError = .unableToLocate
        }
    }
    
    @available(iOS 14.0, *)
    func locationManager(_ manager: CLLocationManager, didChangeAccuracyAuthorization authorization: CLAccuracyAuthorization) {
        accuracyAuthorization = authorization
    }
}

// MARK: - Utility Methods

extension LocationService {
    func createSearchArea(from location: SearchLocation) -> SearchArea {
        SearchArea(
            center: location.coordinate,
            radius: location.radius
        )
    }
    
    func isLocation(_ location: CLLocationCoordinate2D, withinRadius radius: Double, of center: CLLocationCoordinate2D) -> Bool {
        let distance = center.distance(to: location)
        return distance <= radius
    }
    
    func sortLocationsByDistance(_ locations: [SearchLocation], from coordinate: CLLocationCoordinate2D) -> [SearchLocation] {
        return locations.sorted { location1, location2 in
            let distance1 = coordinate.distance(to: location1.coordinate)
            let distance2 = coordinate.distance(to: location2.coordinate)
            return distance1 < distance2
        }
    }
}

// MARK: - Mock Data

extension LocationService {
    static let preview: LocationService = {
        let service = LocationService()
        service.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        service.authorizationStatus = .authorizedWhenInUse
        service.isLocationServicesEnabled = true
        service.savedLocations = SearchLocation.mockLocations
        return service
    }()
}