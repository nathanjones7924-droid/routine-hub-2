import SwiftUI
import Combine
import UserNotifications

/// Onboarding view shown to first-time users
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var currentPage = 0
    
    private let totalPages = 7
    
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
                    actionFeaturesPage.tag(3)
                    calendarPage.tag(4)
                    timerPage.tag(5)
                    themePickerPage.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .iPadConstrained()
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? AppTheme.primaryColor : AppTheme.borderColor.opacity(0.35))
                            .frame(width: index == currentPage ? 14 : 8, height: index == currentPage ? 14 : 8)
                            .overlay(
                                Circle()
                                    .stroke(index == currentPage ? Color.white.opacity(0.9) : Color.clear, lineWidth: 2)
                            )
                            .shadow(color: index == currentPage ? AppTheme.primaryColor.opacity(0.55) : .clear, radius: 6)
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
                            completeOnboarding(askPermission: true)
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
            
            Text("Alarms only go off when your phone is on Ring")
                .font(AppTheme.headline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
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
            
            Text("Make sure your phone is on Ring for alarm notifications to play sound")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
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
    
    // MARK: - Page 4: Action Features
    
    private var actionFeaturesPage: some View {
        VStack(spacing: 16) {
            Text("Customize Your Actions")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            
            Text("Each action has powerful options")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            VStack(spacing: 12) {
                // Loud Alarm feature
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loud Alarm")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Text("Get a loud alert when action ends")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                
                // Red Filter feature
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "eye.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Red Light Filter")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Text("Protect your eyes in early morning")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                
                // Duration feature
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "timer")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom Duration")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.primaryText)
                        Text("Set hours, minutes, or seconds")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
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
    
    // MARK: - Page 5: Calendar
    
    private var calendarPage: some View {
        VStack(spacing: 16) {
            Text("See Your Day Ahead")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            
            Text("View calendar events before starting")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            VStack(spacing: 16) {
                // Calendar toggle mockup
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.primaryColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Calendar Events")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryText)
                        Text("Enable in routine settings")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
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
                
                // Mock calendar events
                VStack(spacing: 8) {
                    Text("Today's Events")
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 4, height: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Team Meeting")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                            Text("9:00 AM - 10:00 AM")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.elevatedBackground)
                    .cornerRadius(8)
                    
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green)
                            .frame(width: 4, height: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lunch with Sarah")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                            Text("12:30 PM - 1:30 PM")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.elevatedBackground)
                    .cornerRadius(8)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                
                // Explanation
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppTheme.primaryColor)
                    Text("Review your schedule, then start your routine")
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
    
    // MARK: - Page 6: Timer
    
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
    
    // MARK: - Page 7: Appearance
    
    private var themePickerPage: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                Text("Customize Appearance")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Theme, background, and box colors can all be customized in Settings")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Appearance controls preview
                VStack(spacing: 12) {
                HStack {
                    Text("Use Grayscale")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.controlTextColor)

                    Spacer()

                    Toggle("", isOn: $settingsManager.themeUseGrayscale)
                        .labelsHidden()
                        .toggleStyle(AppThemeToggleStyle())
                }

                HStack {
                    Text("Theme Color")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.primaryText)

                    Spacer()

                    Circle()
                        .fill(AppTheme.primaryColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.borderColor, lineWidth: 2)
                        )
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)

                GeometryReader { geometry in
                    let width = max(geometry.size.width, 1)
                    let knobX = settingsManager.themeAccentHue * width

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: settingsManager.themeUseGrayscale
                                        ? [
                                            Color(white: 0.0),
                                            Color(white: 1.0)
                                        ]
                                        : stride(from: 0.0, through: 1.0, by: 0.1).map {
                                            Color(hue: $0, saturation: 0.95, brightness: 1.0)
                                        },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 22)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.borderColor, lineWidth: 1)
                            )

                        Circle()
                            .fill(AppTheme.primaryColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.9), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                            .position(x: min(max(knobX, 0), width), y: geometry.size.height / 2)
                    }
                    .overlay(
                        HorizontalDragOverlay { norm in
                            settingsManager.themeAccentHue = norm
                        }
                    )
                }
                .frame(height: 30)
                .padding(.horizontal, 8)

                HStack {
                    Text("Background Grayscale")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.controlTextColor)

                    Spacer()

                    Toggle("", isOn: $settingsManager.backgroundUseGrayscale)
                        .labelsHidden()
                        .toggleStyle(AppThemeToggleStyle())
                }

                HStack {
                    Text("Background Color")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.primaryText)

                    Spacer()

                    Circle()
                        .fill(
                            settingsManager.backgroundUseGrayscale
                                ? Color(white: settingsManager.backgroundHue)
                                : Color(hue: settingsManager.backgroundHue, saturation: 0.95, brightness: 1.0)
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.borderColor, lineWidth: 2)
                        )
                }

                GeometryReader { geometry in
                    let width = max(geometry.size.width, 1)
                    let knobX = settingsManager.backgroundHue * width

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: settingsManager.backgroundUseGrayscale
                                        ? [
                                            Color(white: 0.0),
                                            Color(white: 1.0)
                                        ]
                                        : stride(from: 0.0, through: 1.0, by: 0.1).map {
                                            Color(hue: $0, saturation: 0.95, brightness: 1.0)
                                        },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 22)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.borderColor, lineWidth: 1)
                            )

                        Circle()
                            .fill(
                                settingsManager.backgroundUseGrayscale
                                    ? Color(white: settingsManager.backgroundHue)
                                    : Color(hue: settingsManager.backgroundHue, saturation: 0.95, brightness: 1.0)
                            )
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.9), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                            .position(x: min(max(knobX, 0), width), y: geometry.size.height / 2)
                    }
                    .overlay(
                        HorizontalDragOverlay { norm in
                            settingsManager.backgroundHue = norm
                        }
                    )
                }
                .frame(height: 30)
                .padding(.horizontal, 8)

                HStack {
                    Text("Box Grayscale")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.controlTextColor)

                    Spacer()

                    Toggle("", isOn: $settingsManager.boxBackgroundUseGrayscale)
                        .labelsHidden()
                        .toggleStyle(AppThemeToggleStyle())
                }

                HStack {
                    Text("Box Background")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.primaryText)

                    Spacer()

                    Circle()
                        .fill(AppTheme.boxPreviewColor(
                            hue: settingsManager.boxBackgroundHue,
                            useGrayscale: settingsManager.boxBackgroundUseGrayscale
                        ))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.borderColor, lineWidth: 2)
                        )
                }

                GeometryReader { geometry in
                    let width = max(geometry.size.width, 1)
                    let knobX = settingsManager.boxBackgroundHue * width

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: AppTheme.boxSliderColors(
                                        useGrayscale: settingsManager.boxBackgroundUseGrayscale
                                    ),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 22)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.borderColor, lineWidth: 1)
                            )

                        Circle()
                            .fill(AppTheme.boxPreviewColor(
                                hue: settingsManager.boxBackgroundHue,
                                useGrayscale: settingsManager.boxBackgroundUseGrayscale
                            ))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.9), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                            .position(x: min(max(knobX, 0), width), y: geometry.size.height / 2)
                    }
                    .overlay(
                        HorizontalDragOverlay { norm in
                            settingsManager.boxBackgroundHue = norm
                        }
                    )
                }
                .frame(height: 30)
                .padding(.horizontal, 8)

                Button {
                    resetAppearanceDefaults()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Appearance to Defaults")
                        Spacer()
                    }
                    .font(AppTheme.body)
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.top, 4)
                }
                
                    // Explanation
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.primaryColor)
                        Text("These controls are also in Settings → Appearance")
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
                .padding()
                .padding(.bottom, 40)
            }
        }
        .padding(.top, 20)
    }
    
    private func completeOnboarding(askPermission: Bool = false) {
        OnboardingManager.shared.completeOnboarding()
        
        withAnimation {
            isPresented = false
        }
        
        if askPermission {
            // Request notification permission after onboarding view is dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if let error = error {
                        print("[OnboardingView] Notification permission error: \(error.localizedDescription)")
                    } else {
                        print("[OnboardingView] Notification permission granted: \(granted)")
                    }
                }
            }
        }
    }

    private func resetAppearanceDefaults() {
        settingsManager.themeUseGrayscale = AppTheme.defaultThemeUseGrayscale
        settingsManager.themeAccentHue = AppTheme.defaultThemeAccentHue
        settingsManager.backgroundUseGrayscale = AppTheme.defaultBackgroundUseGrayscale
        settingsManager.backgroundHue = AppTheme.defaultBackgroundHue
        settingsManager.boxBackgroundUseGrayscale = AppTheme.defaultBoxBackgroundUseGrayscale
        settingsManager.boxBackgroundHue = AppTheme.defaultBoxBackgroundHue
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
        .environmentObject(SettingsManager())
}
