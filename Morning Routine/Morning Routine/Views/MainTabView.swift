import SwiftUI

/// Main tab view with Home, Routines, and Settings tabs
struct MainTabView: View {
    @EnvironmentObject var routineManager: RoutineManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTab: Tab = .home
    @State private var bannerHeight: CGFloat = 50

    private var useGrayscale: Bool {
        settingsManager.themeUseGrayscale
    }

    private var livePrimaryColor: Color {
        if useGrayscale {
            let tone = min(max(settingsManager.themeAccentHue, 0), 1)
            return Color(white: tone)
        }
        return Color(hue: settingsManager.themeAccentHue, saturation: 0.86, brightness: 0.95)
    }

    private var liveSecondaryColor: Color {
        if useGrayscale {
            let tone = min(0.85, 0.42 + (settingsManager.themeAccentHue * 0.40))
            return Color(white: tone)
        }
        return Color(hue: settingsManager.themeAccentHue, saturation: 0.46, brightness: 0.80)
    }

    private var liveBorderColor: Color {
        if useGrayscale {
            let tone = min(0.95, 0.45 + (settingsManager.themeAccentHue * 0.45))
            return Color(white: tone)
        }
        return Color(hue: settingsManager.themeAccentHue, saturation: 0.80, brightness: 0.92)
    }
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case routines = "Routines"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .routines: return "list.bullet.rectangle.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area
                TabView(selection: $selectedTab) {
                    HomeView(selectedTab: $selectedTab)
                        .tag(Tab.home)
                    
                    RoutinesListView()
                        .tag(Tab.routines)
                    
                    SettingsView()
                        .tag(Tab.settings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom tab bar
                customTabBar
            }
            .safeAreaInset(edge: .bottom) {
                AdBannerView(adUnitID: "ca-app-pub-2527367977978685/6080321324", height: $bannerHeight)
                    .frame(height: bannerHeight)
            }
        }
        .animation(.none, value: settingsManager.themeAccentHue)
        .animation(.none, value: settingsManager.themeUseGrayscale)
        .animation(.none, value: settingsManager.backgroundHue)
        .animation(.none, value: settingsManager.backgroundUseGrayscale)
        .animation(.none, value: settingsManager.boxBackgroundHue)
        .animation(.none, value: settingsManager.boxBackgroundUseGrayscale)
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, AppTheme.padding)
        .padding(.vertical, AppTheme.paddingSmall)
        .background(
            Capsule()
                .fill(AppTheme.cardBackground)
                .overlay(
                    Capsule()
                    .stroke(liveBorderColor, lineWidth: AppTheme.borderWidth)
                )
                .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: -2)
        )
        .padding(.horizontal, AppTheme.paddingLarge)
        .padding(.bottom, AppTheme.paddingSmall)
        .iPadConstrained()
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(tab.rawValue)
                    .font(AppTheme.caption)
            }
            .foregroundColor(selectedTab == tab ? livePrimaryColor : liveSecondaryColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environmentObject(RoutineManager())
        .environmentObject(AlarmManager())
        .environmentObject(TimerManager())
}
