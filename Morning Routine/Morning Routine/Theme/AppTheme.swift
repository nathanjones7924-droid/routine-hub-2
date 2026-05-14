import SwiftUI
#if os(iOS)
import UIKit
#endif

/// App-wide theme constants for consistent styling - Dark Mode
struct AppTheme {
    // MARK: - Colors

    static let defaultThemeAccentHue = 0.06
    static let defaultThemeUseGrayscale = false
    static let defaultBackgroundHue = 0.08
    static let defaultBackgroundUseGrayscale = true
    static let defaultBoxBackgroundHue = 0.08
    static let defaultBoxBackgroundUseGrayscale = true

    /// UserDefaults key for the app accent hue
    static let themeAccentHueKey = "themeAccentHue"
    static let themeUseGrayscaleKey = "themeUseGrayscale"
    static let backgroundHueKey = "backgroundHue"
    static let backgroundUseGrayscaleKey = "backgroundUseGrayscale"
    static let boxBackgroundHueKey = "boxBackgroundHue"
    static let boxBackgroundUseGrayscaleKey = "boxBackgroundUseGrayscale"

    /// Current accent hue (0...1)
    static var themeAccentHue: Double {
        let stored = UserDefaults.standard.object(forKey: themeAccentHueKey) as? Double ?? defaultThemeAccentHue
        return min(max(stored, 0), 1)
    }

    static var themeUseGrayscale: Bool {
        UserDefaults.standard.object(forKey: themeUseGrayscaleKey) as? Bool ?? defaultThemeUseGrayscale
    }

    static var backgroundHue: Double {
        let stored = UserDefaults.standard.object(forKey: backgroundHueKey) as? Double ?? defaultBackgroundHue
        return min(max(stored, 0), 1)
    }

    static var backgroundUseGrayscale: Bool {
        UserDefaults.standard.object(forKey: backgroundUseGrayscaleKey) as? Bool ?? defaultBackgroundUseGrayscale
    }

    static var boxBackgroundHue: Double {
        let stored = UserDefaults.standard.object(forKey: boxBackgroundHueKey) as? Double ?? defaultBoxBackgroundHue
        return min(max(stored, 0), 1)
    }

    static var boxBackgroundUseGrayscale: Bool {
        UserDefaults.standard.object(forKey: boxBackgroundUseGrayscaleKey) as? Bool ?? defaultBoxBackgroundUseGrayscale
    }

    static func boxPreviewColor(hue: Double, useGrayscale: Bool) -> Color {
        let normalizedHue = min(max(hue, 0), 1)
        if useGrayscale {
            return Color(white: normalizedHue)
        }
        return Color(hue: normalizedHue, saturation: 0.45, brightness: 0.25)
    }

    static func boxSliderColors(useGrayscale: Bool) -> [Color] {
        if useGrayscale {
            return [
                Color(white: 0.0),
                Color(white: 1.0)
            ]
        }

        return stride(from: 0.0, through: 1.0, by: 0.1).map {
            boxPreviewColor(hue: $0, useGrayscale: false)
        }
    }
    
    /// Primary warm reddish-orange color
    static var primaryColor: Color {
        if themeUseGrayscale {
            let tone = min(max(themeAccentHue, 0), 1)
            return Color(white: tone)
        }
        return Color(hue: themeAccentHue, saturation: 0.86, brightness: 0.95)
    }
    
    /// Darker background color
    static let darkBackground = Color(red: 0.08, green: 0.08, blue: 0.10)
    
    /// Slightly lighter dark for cards
    static var cardBackground: Color {
        if boxBackgroundUseGrayscale {
            let tone = boxBackgroundHue
            return Color(white: tone)
        }
        return boxPreviewColor(hue: boxBackgroundHue, useGrayscale: false)
    }
    
    /// Even lighter dark for elevated elements
    static var elevatedBackground: Color {
        if boxBackgroundUseGrayscale {
            let tone = min(1.0, boxBackgroundHue + 0.08)
            return Color(white: tone)
        }
        return Color(hue: boxBackgroundHue, saturation: 0.38, brightness: 0.32)
    }
    
    /// Primary text color (orange)
    static var primaryText: Color {
        accessibleThemeColor(on: cardBackground, minimumContrast: 4.5)
    }
    
    /// Secondary text color (lighter orange)
    static var secondaryText: Color {
        secondaryAccessibleThemeColor(on: cardBackground)
    }
    
    /// Border/outline color (orangeish-red) - thicker
    static var borderColor: Color {
        if themeUseGrayscale {
            let tone = min(0.95, 0.45 + (themeAccentHue * 0.45))
            return Color(white: tone)
        }
        return Color(hue: themeAccentHue, saturation: 0.80, brightness: 0.92)
    }

    static var controlAccentColor: Color {
        #if os(iOS)
        return isLightColor(cardBackground) ? .black : accessibleThemeColor(on: cardBackground, minimumContrast: 3.0)
        #else
        return accessibleThemeColor(on: cardBackground, minimumContrast: 3.0)
        #endif
    }

    static var controlTextColor: Color {
        accessibleThemeColor(on: cardBackground, minimumContrast: 4.5)
    }

    static var navigationBarBackgroundColor: Color {
        if backgroundUseGrayscale {
            return Color(white: backgroundHue)
        }
        return Color(hue: backgroundHue, saturation: 0.95, brightness: 0.75)
    }

    static var navigationBarAccentColor: Color {
        accessibleThemeColor(on: navigationBarBackgroundColor, minimumContrast: 3.0)
    }

    static var navigationBarTextColor: Color {
        accessibleThemeColor(on: navigationBarBackgroundColor, minimumContrast: 4.5)
    }

    static var backgroundTextColor: Color {
        accessibleThemeColor(on: navigationBarBackgroundColor, minimumContrast: 4.5)
    }

    static var controlColorScheme: ColorScheme {
#if os(iOS)
        return isLightColor(cardBackground) ? .light : .dark
#else
        return .dark
#endif
    }

    private static func accessibleThemeColor(on background: Color, minimumContrast: Double) -> Color {
#if os(iOS)
        let foreground = UIColor(primaryColor)
        let backgroundColor = UIColor(background)
        if contrastRatio(between: foreground, and: backgroundColor) >= minimumContrast {
            return primaryColor
        }

        if themeUseGrayscale {
            return isLightColor(background) ? Color(white: 0.08) : Color(white: 0.92)
        }

        let brightness = isLightColor(background) ? 0.34 : 0.96
        let saturation = isLightColor(background) ? 0.82 : 0.72
        return Color(hue: themeAccentHue, saturation: saturation, brightness: brightness)
#else
        return primaryColor
#endif
    }

    private static func secondaryAccessibleThemeColor(on background: Color) -> Color {
#if os(iOS)
        if themeUseGrayscale {
            return isLightColor(background) ? Color(white: 0.28) : Color(white: 0.72)
        }

        if isLightColor(background) {
            return Color(hue: themeAccentHue, saturation: 0.55, brightness: 0.42)
        }

        return Color(hue: themeAccentHue, saturation: 0.46, brightness: 0.80)
#else
        return primaryColor
#endif
    }

#if os(iOS)
    private static func isLightColor(_ color: Color) -> Bool {
        relativeLuminance(of: UIColor(color)) > 0.6
    }

    private static func contrastRatio(between first: UIColor, and second: UIColor) -> Double {
        let firstLuminance = relativeLuminance(of: first)
        let secondLuminance = relativeLuminance(of: second)
        let lighter = max(firstLuminance, secondLuminance)
        let darker = min(firstLuminance, secondLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(of color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        func adjust(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            if value <= 0.03928 {
                return value / 12.92
            }
            return pow((value + 0.055) / 1.055, 2.4)
        }

        let adjustedRed = adjust(red)
        let adjustedGreen = adjust(green)
        let adjustedBlue = adjust(blue)
        return (0.2126 * adjustedRed) + (0.7152 * adjustedGreen) + (0.0722 * adjustedBlue)
    }
#endif
    
    /// Border line width
    static let borderWidth: CGFloat = 2
    
    /// Accent glow color
    static var accentGlow: Color {
        primaryColor.opacity(0.3)
    }
    
    /// Background gradient colors (user-customizable)
    static var backgroundGradient: LinearGradient {
        if backgroundUseGrayscale {
            let topTone = backgroundHue
            let bottomTone = min(1.0, topTone + (topTone * 0.12))
            return LinearGradient(
                colors: [
                    Color(white: topTone),
                    Color(white: bottomTone)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [
                Color(hue: backgroundHue, saturation: 0.95, brightness: 0.75),
                Color(hue: backgroundHue, saturation: 0.88, brightness: 0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Red filter overlay color for action execution
    static let redFilterColor = Color.red.opacity(0.35)
    
    // MARK: - Dimensions
    
    /// Standard corner radius for cards and buttons
    static let cornerRadius: CGFloat = 16
    
    /// Smaller corner radius for compact elements
    static let cornerRadiusSmall: CGFloat = 10
    
    /// Large corner radius for sheets and modals
    static let cornerRadiusLarge: CGFloat = 24
    
    /// Standard padding
    static let padding: CGFloat = 16
    
    /// Small padding
    static let paddingSmall: CGFloat = 8
    
    /// Large padding
    static let paddingLarge: CGFloat = 24

        /// Max readable width for iPad layouts
        static var contentMaxWidth: CGFloat? {
    #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 720 : nil
    #else
        return nil
    #endif
        }
    
    // MARK: - Shadows
    
    /// Standard card shadow (subtle glow)
    static let cardShadow = Color.black.opacity(0.4)
    static let cardShadowRadius: CGFloat = 10
    static let cardShadowY: CGFloat = 4
    
    // MARK: - Fonts
    
    /// Large title font
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    
    /// Title font
    static let title = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    /// Headline font
    static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    /// Body font
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    
    /// Caption font
    static let caption = Font.system(size: 14, weight: .regular, design: .rounded)
    
    /// Timer display font
    static let timerFont = Font.system(size: 72, weight: .bold, design: .rounded)
}

// MARK: - View Extensions

extension View {
    /// Constrain content width on iPad for better readability
    func iPadConstrained() -> some View {
        self
            .frame(maxWidth: AppTheme.contentMaxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Apply card styling with border
    func cardStyle() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
            .shadow(
                color: AppTheme.cardShadow,
                radius: AppTheme.cardShadowRadius,
                x: 0,
                y: AppTheme.cardShadowY
            )
    }
    
    /// Apply primary button styling
    func primaryButtonStyle() -> some View {
        self
            .font(AppTheme.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryColor)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
    }
    
    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self
            .font(AppTheme.headline)
            .foregroundColor(AppTheme.primaryColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.elevatedBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
    }
}

struct AppThemeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer(minLength: 12)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    configuration.isOn.toggle()
                }
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(trackFillColor(isOn: configuration.isOn))
                        .overlay(
                            Capsule()
                                .stroke(trackStrokeColor(isOn: configuration.isOn), lineWidth: 2)
                        )

                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .stroke(trackStrokeColor(isOn: configuration.isOn).opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                        .padding(3)
                }
                .frame(width: 52, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(configuration.isOn ? "On" : "Off")
            .accessibilityAddTraits(.isButton)
        }
    }

    private func trackFillColor(isOn: Bool) -> Color {
        if isOn {
            return AppTheme.controlAccentColor
        }
        return AppTheme.controlTextColor.opacity(0.18)
    }

    private func trackStrokeColor(isOn: Bool) -> Color {
        if isOn {
            return AppTheme.controlAccentColor
        }
        return AppTheme.controlTextColor
    }
}

// MARK: - Custom Button Style

struct WarmButtonStyle: ButtonStyle {
    var isPrimary: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPrimary ? AppTheme.primaryColor : AppTheme.elevatedBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
