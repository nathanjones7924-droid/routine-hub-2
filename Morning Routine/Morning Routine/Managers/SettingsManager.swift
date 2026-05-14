import Foundation
import SwiftUI
import Combine

/// Manages app-wide settings and preferences
@MainActor
class SettingsManager: ObservableObject {
    /// Minutes offset from sunrise (negative = before, positive = after)
    @Published var minutesBeforeSunrise: Int = -3 {
        didSet {
            saveSettings()
        }
    }

    /// Minutes offset from sunset (negative = before, positive = after)
    @Published var minutesFromSunset: Int = -3 {
        didSet {
            saveSettings()
        }
    }

    /// Theme accent hue (0...1)
    @Published var themeAccentHue: Double = 0.06 {
        didSet {
            saveSettings()
        }
    }

    /// Whether theme slider uses grayscale instead of rainbow colors
    @Published var themeUseGrayscale: Bool = false {
        didSet {
            saveSettings()
        }
    }

    /// Background hue (0...1)
    @Published var backgroundHue: Double = AppTheme.defaultBackgroundHue {
        didSet {
            saveSettings()
        }
    }

    /// Whether background slider uses grayscale
    @Published var backgroundUseGrayscale: Bool = AppTheme.defaultBackgroundUseGrayscale {
        didSet {
            saveSettings()
        }
    }

    /// Box/card background hue (0...1)
    @Published var boxBackgroundHue: Double = AppTheme.defaultBoxBackgroundHue {
        didSet {
            saveSettings()
        }
    }

    /// Whether box/card background uses grayscale
    @Published var boxBackgroundUseGrayscale: Bool = AppTheme.defaultBoxBackgroundUseGrayscale {
        didSet {
            saveSettings()
        }
    }
    
    private let minutesBeforeSunriseKey = "minutesBeforeSunrise"
    private let minutesFromSunsetKey = "minutesFromSunset"
    private let themeAccentHueKey = AppTheme.themeAccentHueKey
    private let themeUseGrayscaleKey = AppTheme.themeUseGrayscaleKey
    private let backgroundHueKey = AppTheme.backgroundHueKey
    private let backgroundUseGrayscaleKey = AppTheme.backgroundUseGrayscaleKey
    private let boxBackgroundHueKey = AppTheme.boxBackgroundHueKey
    private let boxBackgroundUseGrayscaleKey = AppTheme.boxBackgroundUseGrayscaleKey
    
    init() {
        loadSettings()
    }
    
    // MARK: - Persistence
    
    /// Save settings to UserDefaults
    private func saveSettings() {
        UserDefaults.standard.set(minutesBeforeSunrise, forKey: minutesBeforeSunriseKey)
        UserDefaults.standard.set(minutesFromSunset, forKey: minutesFromSunsetKey)
        UserDefaults.standard.set(themeAccentHue, forKey: themeAccentHueKey)
        UserDefaults.standard.set(themeUseGrayscale, forKey: themeUseGrayscaleKey)
        UserDefaults.standard.set(backgroundHue, forKey: backgroundHueKey)
        UserDefaults.standard.set(backgroundUseGrayscale, forKey: backgroundUseGrayscaleKey)
        UserDefaults.standard.set(boxBackgroundHue, forKey: boxBackgroundHueKey)
        UserDefaults.standard.set(boxBackgroundUseGrayscale, forKey: boxBackgroundUseGrayscaleKey)
        print("[SettingsManager] ⚙️ Saved settings: minutesBeforeSunrise = \(minutesBeforeSunrise), minutesFromSunset = \(minutesFromSunset), themeAccentHue = \(themeAccentHue), themeUseGrayscale = \(themeUseGrayscale), backgroundHue = \(backgroundHue), backgroundUseGrayscale = \(backgroundUseGrayscale), boxBackgroundHue = \(boxBackgroundHue), boxBackgroundUseGrayscale = \(boxBackgroundUseGrayscale)")
    }
    
    /// Load settings from UserDefaults
    private func loadSettings() {
        if let saved = UserDefaults.standard.object(forKey: minutesBeforeSunriseKey) as? Int {
            minutesBeforeSunrise = saved
        } else {
            minutesBeforeSunrise = -3
        }

        if let savedSunset = UserDefaults.standard.object(forKey: minutesFromSunsetKey) as? Int {
            minutesFromSunset = savedSunset
        } else {
            minutesFromSunset = -3
        }

        if let savedHue = UserDefaults.standard.object(forKey: themeAccentHueKey) as? Double {
            themeAccentHue = min(max(savedHue, 0), 1)
        } else {
            themeAccentHue = 0.06
        }

        if let savedGrayscale = UserDefaults.standard.object(forKey: themeUseGrayscaleKey) as? Bool {
            themeUseGrayscale = savedGrayscale
        } else {
            themeUseGrayscale = false
        }

        if let savedBackgroundHue = UserDefaults.standard.object(forKey: backgroundHueKey) as? Double {
            backgroundHue = min(max(savedBackgroundHue, 0), 1)
        } else {
            backgroundHue = AppTheme.defaultBackgroundHue
        }

        if let savedBackgroundGrayscale = UserDefaults.standard.object(forKey: backgroundUseGrayscaleKey) as? Bool {
            backgroundUseGrayscale = savedBackgroundGrayscale
        } else {
            backgroundUseGrayscale = AppTheme.defaultBackgroundUseGrayscale
        }

        if let savedBoxHue = UserDefaults.standard.object(forKey: boxBackgroundHueKey) as? Double {
            boxBackgroundHue = min(max(savedBoxHue, 0), 1)
        } else {
            boxBackgroundHue = AppTheme.defaultBoxBackgroundHue
        }

        if let savedBoxGrayscale = UserDefaults.standard.object(forKey: boxBackgroundUseGrayscaleKey) as? Bool {
            boxBackgroundUseGrayscale = savedBoxGrayscale
        } else {
            boxBackgroundUseGrayscale = AppTheme.defaultBoxBackgroundUseGrayscale
        }

        print("[SettingsManager] ⚙️ Loaded settings: minutesBeforeSunrise = \(minutesBeforeSunrise), minutesFromSunset = \(minutesFromSunset), themeAccentHue = \(themeAccentHue), themeUseGrayscale = \(themeUseGrayscale), backgroundHue = \(backgroundHue), backgroundUseGrayscale = \(backgroundUseGrayscale), boxBackgroundHue = \(boxBackgroundHue), boxBackgroundUseGrayscale = \(boxBackgroundUseGrayscale)")
    }
}
