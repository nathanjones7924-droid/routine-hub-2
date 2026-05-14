import SwiftUI

/// Settings view with app info and preferences
struct SettingsView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var routineManager: RoutineManager
    @EnvironmentObject var settingsManager: SettingsManager
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    
    @State private var showingResetAlert = false
    @State private var showOnboarding = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.paddingLarge) {
                // Sunrise preferences section
                sunrisePreferencesSection
                // Appearance section
                appearanceSection
                // Notifications section
                notificationsSection
                // Onboarding section
                onboardingSection
                // Data section
                dataSection
                Spacer(minLength: 50)
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, AppTheme.padding)
            .iPadConstrained()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all your routines and settings. This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
    
    // MARK: - Sun Preferences Section
    
    private var sunrisePreferencesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Sun Preferences")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: AppTheme.paddingSmall) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wake Up Before Sunrise")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("For 'wake with sun' routines")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Button(action: { decrementSunriseMinutes() }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                            
                            Text("\(settingsManager.minutesBeforeSunrise) min")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                                .frame(minWidth: 50, alignment: .center)
                            
                            Button(action: { incrementSunriseMinutes() }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                        }
                    }
                }
                .padding()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Look at the Sunset")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryText)

                        Text("For 'go to bed with sun' routines")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Button(action: { decrementSunsetMinutes() }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.primaryColor)
                            }

                            Text("\(settingsManager.minutesFromSunset) min")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                                .frame(minWidth: 50, alignment: .center)

                            Button(action: { incrementSunsetMinutes() }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
        }
    }
    
    private func incrementSunriseMinutes() {
        if settingsManager.minutesBeforeSunrise < 60 {
            settingsManager.minutesBeforeSunrise += 1
        }
    }
    
    private func decrementSunriseMinutes() {
        if settingsManager.minutesBeforeSunrise > -60 {
            settingsManager.minutesBeforeSunrise -= 1
        }
    }

    private func incrementSunsetMinutes() {
        if settingsManager.minutesFromSunset < 60 {
            settingsManager.minutesFromSunset += 1
        }
    }

    private func decrementSunsetMinutes() {
        if settingsManager.minutesFromSunset > -60 {
            settingsManager.minutesFromSunset -= 1
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Appearance")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)

            VStack(alignment: .leading, spacing: 12) {
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

                Text("Drag to choose any color")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)

                Divider().background(AppTheme.borderColor.opacity(0.6))

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
                                : Color(hue: settingsManager.backgroundHue, saturation: 0.50, brightness: 0.26)
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

                Text("Drag to choose a background color")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)

                Divider().background(AppTheme.borderColor.opacity(0.6))

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

                Text("Drag to choose box/card background color")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)

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
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Notifications")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: alarmManager.notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(alarmManager.notificationsEnabled ? AppTheme.primaryColor : AppTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alarm Notifications")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text(alarmManager.notificationsEnabled ? "Enabled" : "Disabled")
                            .font(AppTheme.caption)
                            .foregroundColor(alarmManager.notificationsEnabled ? .green : AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    if !alarmManager.notificationsEnabled {
                        Button("Enable") {
                            Task {
                                await alarmManager.requestPermission()
                            }
                        }
                        .font(AppTheme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.primaryColor)
                        .cornerRadius(AppTheme.cornerRadiusSmall)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                        )
                    }
                }
                .padding()
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
        }
    }
    
    // MARK: - Onboarding Section
    
    private var onboardingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Help")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 0) {
                Button {
                    showOnboarding = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Restart Onboarding")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text("Learn how to use the app")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding()
                }
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Data")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 0) {
                // Stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Routines")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("\(routineManager.routines.count) routine(s)")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryColor)
                }
                .padding()
                
                Divider().background(AppTheme.borderColor).padding(.leading, 16)
                
                // Reset button
                Button {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                        
                        Text("Reset All Data")
                            .font(AppTheme.body)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
        }
    }
    
    // MARK: - Actions
    
    private func resetAllData() {
        // Clear all routines
        for routine in routineManager.routines {
            routineManager.deleteRoutine(routine)
        }
        
        // Cancel all alarms
        alarmManager.cancelAllAlarms()
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

#Preview {
    SettingsView()
        .environmentObject(AlarmManager())
        .environmentObject(RoutineManager())
}
