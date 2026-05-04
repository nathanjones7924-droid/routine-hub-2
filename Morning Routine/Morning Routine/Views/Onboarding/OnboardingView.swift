import SwiftUI
import Combine

/// Onboarding view shown to first-time users
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(AppTheme.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    createRoutinePage.tag(1)
                    alarmPage.tag(2)
                    timerPage.tag(3)
                    selectRoutinePage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? AppTheme.primaryColor : AppTheme.borderColor)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.vertical, AppTheme.padding)
                
                // Navigation buttons
                HStack(spacing: AppTheme.padding) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(AppTheme.body)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.primaryColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(AppTheme.primaryColor, lineWidth: 2)
                            )
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        if currentPage < totalPages - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                            if currentPage < totalPages - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(AppTheme.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryColor)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                }
                .padding(.horizontal, AppTheme.paddingLarge)
                .padding(.bottom, AppTheme.paddingLarge)
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App icon mockup
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .shadow(color: .orange.opacity(0.4), radius: 20)
                
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            Text("Welcome to\nRoutine Hub")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Build structured routines that keep you on track and help build healthy habits")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Page 2: Create Routine
    
    private var createRoutinePage: some View {
        VStack(spacing: 16) {
            Text("Create Your Routines")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            
            Text("Go to Routines tab and tap the Add button")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            // Mock routine creation UI
            VStack(spacing: 12) {
                // Mock Add button
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Routine")
                        .font(AppTheme.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white)
                .padding()
                .background(AppTheme.primaryColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                
                // Arrow pointing to it
                Image(systemName: "arrow.up")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.primaryColor)
                
                Text("Tap here to create a routine")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.primaryColor)
                    .fontWeight(.semibold)
                
                // Mock routine card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Morning Workout")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        Image(systemName: "alarm.fill")
                            .foregroundColor(AppTheme.primaryColor)
                        Text("6:00 AM")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.primaryColor)
                    }
                    
                    HStack(spacing: 16) {
                        Label("3 actions", systemImage: "checkmark.circle")
                        Label("15 min", systemImage: "clock")
                    }
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.borderColor, lineWidth: 1)
                )
            }
            .padding()
            .background(AppTheme.elevatedBackground.opacity(0.5))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    // MARK: - Page 3: Alarm Settings
    
    private var alarmPage: some View {
        VStack(spacing: 16) {
            Text("Set Wake-Up Alarms")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            
            Text("Enable alarms and choose your wake time")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            // Mock alarm settings
            VStack(spacing: 16) {
                // Alarm toggle
                HStack {
                    Text("Alarm")
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.primaryText)
                    Spacer()
                    
                    // Mock toggle ON
                    ZStack {
                        Capsule()
                            .fill(AppTheme.primaryColor)
                            .frame(width: 50, height: 30)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 26, height: 26)
                            .offset(x: 10)
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                
                // Time picker mockup
                VStack(spacing: 8) {
                    Text("7:00 AM")
                        .font(.system(size: 48, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.primaryColor)
                    
                    Text("Alarm Time")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                
                // Sunrise option
                HStack(spacing: 12) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wake Up with the Sun")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryText)
                        Text("Alarm 5 min before sunrise")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            }
            .padding()
            .background(AppTheme.elevatedBackground.opacity(0.5))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    // MARK: - Page 4: Timer
    
    private var timerPage: some View {
        VStack(spacing: 16) {
            Text("Follow the Guided Timer")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            
            Text("Each action has a countdown timer")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            // Mock timer UI
            VStack(spacing: 20) {
                // Current action
                Text("Brush Teeth")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                // Timer circle
                ZStack {
                    Circle()
                        .stroke(AppTheme.borderColor, lineWidth: 8)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AppTheme.primaryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("1:24")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primaryText)
                        Text("remaining")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == 0 ? AppTheme.primaryColor : AppTheme.borderColor)
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text("Action 1 of 3")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
                
                // Play/Pause button
                HStack(spacing: 20) {
                    Circle()
                        .fill(AppTheme.cardBackground)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "backward.fill")
                                .foregroundColor(AppTheme.secondaryText)
                        )
                    
                    Circle()
                        .fill(AppTheme.primaryColor)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "pause.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                    
                    Circle()
                        .fill(AppTheme.cardBackground)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "forward.fill")
                                .foregroundColor(AppTheme.secondaryText)
                        )
                }
            }
            .padding()
            .background(AppTheme.elevatedBackground.opacity(0.5))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    // MARK: - Page 5: Select Routines
    
    private var selectRoutinePage: some View {
        VStack(spacing: 16) {
            Text("Select Your Routines")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            
            Text("Tap the circle to select which routines are active")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Mock routine list
            VStack(spacing: 12) {
                // Selected routine
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(AppTheme.primaryColor, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(AppTheme.primaryColor)
                            .frame(width: 16, height: 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Morning Workout")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Text("6:00 AM • 3 actions")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text("✓ Selected")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.primaryColor)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.primaryColor, lineWidth: 2)
                )
                
                // Arrow pointing to circle
                HStack {
                    Image(systemName: "arrow.up.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.primaryColor)
                    Text("Tap circle to select/deselect")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.primaryColor)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.leading, 8)
                
                // Unselected routine
                HStack(spacing: 12) {
                    Circle()
                        .stroke(AppTheme.primaryColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Evening Routine")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Text("9:00 PM • 5 actions")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                
                // Explanation
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppTheme.primaryColor)
                    Text("Only selected routines will trigger alarms")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .background(AppTheme.primaryColor.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            .background(AppTheme.elevatedBackground.opacity(0.5))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private func completeOnboarding() {
        OnboardingManager.shared.completeOnboarding()
        withAnimation {
            isPresented = false
        }
    }
}

// MARK: - Onboarding Manager

final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    @Published var hasCompletedOnboarding: Bool
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: hasCompletedOnboardingKey)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
