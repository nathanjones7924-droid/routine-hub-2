import Foundation
import CoreLocation
import Combine
import MapKit

/// Manages user location and sunrise/sunset calculation
@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var sunriseTime: Date?
    @Published var errorMessage: String?
    @Published var cityName: String?
    
    /// The last date for which sunrise was calculated (to detect day changes)
    private var lastSunriseCalculationDate: Date?
    
    /// Timer for checking if a new day has started
    private var midnightCheckTimer: Timer?
    
    /// Reference to settings manager for minutes before sunrise preference
    weak var settingsManager: SettingsManager?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
        
        // If permission already granted, request location
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
        
        // Start timer to check for day changes and recalculate sunrise
        startDailyUpdateTimer()
        
        // Listen for app becoming active to check for day changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndRecalculateSunriseIfNeeded()
            }
        }
    }
    
    deinit {
        midnightCheckTimer?.invalidate()
    }
    
    /// Start a timer that checks periodically if we need to recalculate sunrise for a new day
    private func startDailyUpdateTimer() {
        midnightCheckTimer?.invalidate()
        
        // Check every minute to see if we've crossed into a new day
        midnightCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndRecalculateSunriseIfNeeded()
            }
        }
        
        // Add to common run loop to ensure it runs even during user interaction
        if let timer = midnightCheckTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    /// Check if we need to recalculate sunrise for a new day
    func checkAndRecalculateSunriseIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we have a location and if the day has changed
        guard let location = userLocation else {
            print("[LocationManager] No location available for sunrise recalculation")
            return
        }
        
        if let lastDate = lastSunriseCalculationDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay < today {
                print("[LocationManager] 🌅 New day detected! Recalculating sunrise time...")
                recalculateSunrise(for: location)
            }
        } else {
            // No previous calculation, calculate now
            print("[LocationManager] 🌅 First sunrise calculation of the day...")
            recalculateSunrise(for: location)
        }
    }
    
    /// Recalculate sunrise time for current location
    private func recalculateSunrise(for coordinate: CLLocationCoordinate2D) {
        if let newSunrise = calculateSunrise(for: coordinate) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .medium
            print("[LocationManager] 🌅 Updated sunrise time: \(formatter.string(from: newSunrise))")
            
            sunriseTime = newSunrise
            lastSunriseCalculationDate = Date()
        }
    }
    
    /// Request location permissions from the user
    func requestLocationPermission() {
        print("[LocationManager] requestLocationPermission() called")
        print("[LocationManager] Current authorization status: \(authorizationStatus.rawValue)")
        
        // Only request permission if not already granted
        if authorizationStatus == .notDetermined {
            print("[LocationManager] ⚠️ IMPORTANT: The Apple location permission popup requires NSLocationWhenInUseUsageDescription in Info.plist")
            print("[LocationManager] Please add the following to your Info.plist:")
            print("[LocationManager]   <key>NSLocationWhenInUseUsageDescription</key>")
            print("[LocationManager]   <string>We need your location to calculate sunrise time for your alarm.</string>")
            print("[LocationManager] Calling locationManager.requestWhenInUseAuthorization()...")
            locationManager.requestWhenInUseAuthorization()
            print("[LocationManager] requestWhenInUseAuthorization() completed")
            print("[LocationManager] Apple permission popup should appear now")
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("[LocationManager] Permission already granted, requesting current location...")
            getCurrentLocation()
        } else {
            print("[LocationManager] Permission denied or restricted")
        }
    }
    
    /// Get current location
    func getCurrentLocation() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else {
            errorMessage = "Location permission not granted"
        }
    }
    
    /// Check current authorization status
    private func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// Calculate sunrise time for given coordinates
    func calculateSunrise(for coordinate: CLLocationCoordinate2D) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        var components = DateComponents()
        components.year = calendar.component(.year, from: now)
        components.month = calendar.component(.month, from: now)
        components.day = calendar.component(.day, from: now)
        components.timeZone = TimeZone.autoupdatingCurrent
        
        guard let today = calendar.date(from: components) else { return nil }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Use Solar framework or simple calculation
        // For now, we'll use a basic approximation
        let sunrise = calculateSunriseApproximation(for: today, location: location)
        return sunrise
    }
    
    /// Simple sunrise calculation (approximation)
    private func calculateSunriseApproximation(for date: Date, location: CLLocation) -> Date? {
        let calendar = Calendar.current
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let timeZoneOffset = TimeZone.current.secondsFromGMT() / 3600
        
        // Day of year
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Approximate sunrise calculation
        let B = (Double(dayOfYear) - 81.0) * 360.0 / 365.0
        let B_rad = B * .pi / 180.0
        
        let eot = 9.87 * sin(2 * B_rad) - 7.53 * cos(B_rad) - 1.5 * sin(B_rad)
        let decl = 23.44 * sin(B_rad)
        let decl_rad = decl * .pi / 180.0
        
        let lat_rad = latitude * .pi / 180.0
        let cosH = -tan(lat_rad) * tan(decl_rad)
        
        guard cosH >= -1 && cosH <= 1 else {
            // Polar sunrise/sunset not occurring
            return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date)
        }
        
        let H = acos(cosH) * 180.0 / .pi
        let sunriseHours = (720.0 - 4.0 * (longitude + H) - eot + Double(timeZoneOffset) * 60.0) / 60.0
        
        let hours = Int(sunriseHours)
        let minutes = Int((sunriseHours - Double(hours)) * 60)
        
        let sunriseTime = calendar.date(bySettingHour: max(0, min(23, hours)), minute: max(0, min(59, minutes)), second: 0, of: date)
        
        // Debug logging
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let sunriseString = sunriseTime.map { formatter.string(from: $0) } ?? "Unknown"
        print("[LocationManager] 📊 SUNRISE CALCULATION DEBUG:")
        print("[LocationManager]    Latitude: \(latitude)")
        print("[LocationManager]    Longitude: \(longitude)")
        print("[LocationManager]    Day of year: \(dayOfYear)")
        print("[LocationManager]    Timezone offset: \(timeZoneOffset) hours")
        print("[LocationManager]    Calculated sunrise hours: \(String(format: "%.2f", sunriseHours))")
        print("[LocationManager]    Sunrise time: \(sunriseString)")
        
        return sunriseTime
    }
    
    /// Reverse geocode location to get city name
    private func reverseGeocodeLocation(_ location: CLLocation, capturedSunriseTime: Date?) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let latString = String(format: "%.4f", lat)
        let lonString = String(format: "%.4f", lon)
        let locationString = "(\(latString), \(lonString))"
        
        // Format sunrise time
        let sunriseFormatter = DateFormatter()
        sunriseFormatter.timeStyle = .short
        sunriseFormatter.dateStyle = .none
        let sunriseString = capturedSunriseTime.map { sunriseFormatter.string(from: $0) } ?? "Unknown"
        
        // Use MKLocalSearch to get city name
        Task {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = "location"
            searchRequest.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
            
            let search = MKLocalSearch(request: searchRequest)
            do {
                let response = try await search.start()
                await MainActor.run {
                    if let item = response.mapItems.first {
                        // Use item.name or construct from address description
                        let cityName = item.name ?? "Unknown City"
                        self.cityName = cityName
                        
                        print("🏙️ [LocationManager] City: \(cityName)")
                        print("🌍 [LocationManager] Coordinates: \(locationString)")
                        print("📍 [LocationManager] Latitude: \(lat), Longitude: \(lon)")
                        print("🌅 [LocationManager] Sunrise time: \(sunriseString)")
                    } else {
                        self.cityName = locationString
                        print("🌍 [LocationManager] Location: \(locationString)")
                        print("📍 [LocationManager] Latitude: \(lat), Longitude: \(lon)")
                        print("🌅 [LocationManager] Sunrise time: \(sunriseString)")
                    }
                }
            } catch {
                await MainActor.run {
                    self.cityName = locationString
                    print("🌍 [LocationManager] Location: \(locationString) (search failed: \(error.localizedDescription))")
                    print("📍 [LocationManager] Latitude: \(lat), Longitude: \(lon)")
                    print("🌅 [LocationManager] Sunrise time: \(sunriseString)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[LocationManager] didUpdateLocations called with \(locations.count) location(s)")
        guard let location = locations.last else {
            print("[LocationManager] ERROR: locations.last is nil")
            return
        }
        print("[LocationManager] Latest location: lat=\(location.coordinate.latitude), lon=\(location.coordinate.longitude)")
        userLocation = location.coordinate
        
        // Calculate sunrise time
        let calculatedSunrise = calculateSunrise(for: location.coordinate)
        sunriseTime = calculatedSunrise
        lastSunriseCalculationDate = Date()
        print("[LocationManager] Sunrise calculated: \(calculatedSunrise?.formatted() ?? "nil")")
        
        // Reverse geocode to get city name using MapKit
        reverseGeocodeLocation(location, capturedSunriseTime: calculatedSunrise)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] didFailWithError called")
        print("[LocationManager] Error: \(error.localizedDescription)")
        print("[LocationManager] Error code: \((error as NSError).code)")
        errorMessage = error.localizedDescription
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("[LocationManager] didChangeAuthorization called")
        print("[LocationManager] New status: \(status.rawValue) (0=notDetermined, 1=restricted, 2=denied, 3=authorizedAlways, 4=authorizedWhenInUse)")
        authorizationStatus = status
        
        // If permission was just granted, request location
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("[LocationManager] Permission GRANTED! Requesting current location...")
            locationManager.requestLocation()
        } else {
            print("[LocationManager] Permission NOT granted (status: \(status))")
        }
    }
}
