import SwiftUI

/// Settings view with app info and preferences
struct SettingsView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var routineManager: RoutineManager
    
    @State private var showingResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.paddingLarge) {
                // Notifications section
                notificationsSection
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
                aboutRow(label: "Developer", value: "Morning Routine Team")
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
