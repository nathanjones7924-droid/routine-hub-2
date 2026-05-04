import SwiftUI

/// App-wide theme constants for consistent styling - Dark Mode
struct AppTheme {
    // MARK: - Colors
    
    /// Primary warm reddish-orange color
    static let primaryColor = Color("AccentColor")
    
    /// Darker background color
    static let darkBackground = Color(red: 0.08, green: 0.08, blue: 0.10)
    
    /// Slightly lighter dark for cards
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.14)
    
    /// Even lighter dark for elevated elements
    static let elevatedBackground = Color(red: 0.16, green: 0.16, blue: 0.18)
    
    /// Primary text color (orange)
    static let primaryText = Color(red: 0.95, green: 0.55, blue: 0.25)
    
    /// Secondary text color (lighter orange)
    static let secondaryText = Color(red: 0.75, green: 0.50, blue: 0.35)
    
    /// Border/outline color (orangeish-red) - thicker
    static let borderColor = Color(red: 0.95, green: 0.50, blue: 0.20)
    
    /// Border line width
    static let borderWidth: CGFloat = 2
    
    /// Accent glow color
    static let accentGlow = Color(red: 0.91, green: 0.36, blue: 0.15).opacity(0.3)
    
    /// Background gradient colors (dark)
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.06, blue: 0.08),
            Color(red: 0.10, green: 0.08, blue: 0.10)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
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
