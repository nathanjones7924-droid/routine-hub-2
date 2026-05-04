import Foundation
import SwiftUI
import Combine

/// Manages app-wide settings and preferences
@MainActor
class SettingsManager: ObservableObject {
    /// Minutes offset from sunrise (negative = before, positive = after)
    @Published var minutesBeforeSunrise: Int = -5 {
        didSet {
            saveSettings()
        }
    }
    
    private let minutesBeforeSunriseKey = "minutesBeforeSunrise"
    
    init() {
        loadSettings()
    }
    
    // MARK: - Persistence
    
    /// Save settings to UserDefaults
    private func saveSettings() {
        UserDefaults.standard.set(minutesBeforeSunrise, forKey: minutesBeforeSunriseKey)
        print("[SettingsManager] ⚙️ Saved settings: minutesBeforeSunrise = \(minutesBeforeSunrise)")
    }
    
    /// Load settings from UserDefaults
    private func loadSettings() {
        if let saved = UserDefaults.standard.object(forKey: minutesBeforeSunriseKey) as? Int {
            minutesBeforeSunrise = saved
        } else {
            minutesBeforeSunrise = -5
        }
        print("[SettingsManager] ⚙️ Loaded settings: minutesBeforeSunrise = \(minutesBeforeSunrise)")
    }
}
