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
                // Notifications section
                notificationsSection
                // Onboarding section
                onboardingSection
                // About section
                aboutSection
                // Data section
                dataSection
                Spacer(minLength: 50)
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, AppTheme.padding)
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
    
    // MARK: - Sunrise Preferences Section
    
    private var sunrisePreferencesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Sunrise Preferences")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 0) {
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
                            Button(action: { decrementMinutes() }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                            
                            Text("\(settingsManager.minutesBeforeSunrise) min")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                                .frame(minWidth: 50, alignment: .center)
                            
                            Button(action: { incrementMinutes() }) {
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
    
    private func incrementMinutes() {
        if settingsManager.minutesBeforeSunrise < 60 {
            settingsManager.minutesBeforeSunrise += 1
        }
    }
    
    private func decrementMinutes() {
        if settingsManager.minutesBeforeSunrise > -60 {
            settingsManager.minutesBeforeSunrise -= 1
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
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("About")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 0) {
                aboutRow(label: "App Version", value: "1.0.0")
                Divider().background(AppTheme.borderColor).padding(.leading, 16)
                aboutRow(label: "Build", value: "1")
                Divider().background(AppTheme.borderColor).padding(.leading, 16)
                aboutRow(label: "Developer", value: "Routine Hub Team")
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
        }
    }
    
    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.primaryText)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding()
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
}

#Preview {
    SettingsView()
        .environmentObject(AlarmManager())
        .environmentObject(RoutineManager())
}
