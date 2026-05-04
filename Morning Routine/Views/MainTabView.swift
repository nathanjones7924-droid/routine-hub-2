import SwiftUI

/// Main tab view with Home, Routines, and Settings tabs
struct MainTabView: View {
    @EnvironmentObject var routineManager: RoutineManager
    @State private var selectedTab: Tab = .home
    
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
                
                // Ad banner below tab bar
                AdBannerView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                    .frame(height: 50)
                    .padding(.bottom, AppTheme.paddingSmall)
            }
        }
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
                        .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                )
                .shadow(color: AppTheme.cardShadow, radius: 10, x: 0, y: -2)
        )
        .padding(.horizontal, AppTheme.paddingLarge)
        .padding(.bottom, AppTheme.paddingSmall)
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
            .foregroundColor(selectedTab == tab ? AppTheme.primaryColor : AppTheme.secondaryText)
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
