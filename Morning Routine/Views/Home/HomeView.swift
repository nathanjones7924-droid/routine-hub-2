import SwiftUI

/// Home view showing welcome message, selected routine, and quick start
struct HomeView: View {
    @EnvironmentObject var routineManager: RoutineManager
    @EnvironmentObject var timerManager: TimerManager
    @Binding var selectedTab: MainTabView.Tab
    
    @State private var showingExecution = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.paddingLarge) {
                // Welcome header
                welcomeHeader
                // Selected routine card
                if let routine = routineManager.selectedRoutine {
                    selectedRoutineCard(routine)
                } else {
                    noRoutineCard
                }
                // Quick tips section
                tipsSections
                Spacer(minLength: 50)
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, AppTheme.padding)
        }
        .navigationTitle("Good Morning")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showingExecution) {
            if let routine = routineManager.selectedRoutine {
                RoutineExecutionView(routine: routine, isPresented: $showingExecution)
                    .environmentObject(timerManager)
                    .environmentObject(routineManager)
            }
        }
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(AppTheme.largeTitle)
                .foregroundColor(AppTheme.primaryText)
            
            Text(dateText)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.padding)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning! ☀️"
        case 12..<17: return "Good Afternoon! 🌤"
        case 17..<21: return "Good Evening! 🌅"
        default: return "Good Night! 🌙"
        }
    }
    
    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Selected Routine Card
    
    private func selectedRoutineCard(_ routine: Routine) -> some View {
        VStack(spacing: AppTheme.padding) {
            // Routine info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Routine")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(routine.name)
                        .font(AppTheme.title)
                        .foregroundColor(AppTheme.primaryText)
                }
                
                Spacer()
                
                // Alarm badge
                if routine.alarmEnabled {
                    VStack(spacing: 2) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 16))
                        Text(routine.formattedAlarmTime)
                            .font(AppTheme.caption)
                    }
                    .foregroundColor(AppTheme.primaryColor)
                    .padding(8)
                    .background(AppTheme.elevatedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                    )
                    .cornerRadius(AppTheme.cornerRadiusSmall)
                }
            }
            
            // Actions summary
            HStack(spacing: AppTheme.padding) {
                statItem(value: "\(routine.actions.count)", label: "Actions")
                
                Divider()
                    .frame(height: 30)
                
                statItem(value: routine.formattedTotalDuration, label: "Duration")
            }
            .padding(.vertical, AppTheme.paddingSmall)
            
            // Start button
            Button {
                startRoutine(routine)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Routine")
                }
                .primaryButtonStyle()
            }
            .disabled(routine.actions.isEmpty)
            .opacity(routine.actions.isEmpty ? 0.5 : 1)
        }
        .padding(AppTheme.padding)
        .cardStyle()
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryColor)
            
            Text(label)
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - No Routine Card
    
    private var noRoutineCard: some View {
        VStack(spacing: AppTheme.padding) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.primaryColor)
            
            Text("No Routine Selected")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            Text("Create your first morning routine to get started!")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button {
                selectedTab = .routines
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Routine")
                }
                .primaryButtonStyle()
            }
        }
        .padding(AppTheme.paddingLarge)
        .cardStyle()
    }
    
    // MARK: - Tips Section
    
    private var tipsSections: some View {
        VStack(alignment: .leading, spacing: AppTheme.padding) {
            Text("Tips for Success")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            tipCard(
                icon: "moon.stars.fill",
                title: "Prepare the Night Before",
                description: "Set out clothes and prepare breakfast items"
            )
            
            tipCard(
                icon: "iphone.gen3",
                title: "Phone Away",
                description: "Keep your phone out of arm's reach"
            )
            
            tipCard(
                icon: "drop.fill",
                title: "Hydrate First",
                description: "Drink water before coffee"
            )
        }
    }
    
    private func tipCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AppTheme.padding) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.primaryColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                
                Text(description)
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(AppTheme.padding)
        .cardStyle()
    }
    
    // MARK: - Actions
    
    private func startRoutine(_ routine: Routine) {
        timerManager.setupWithActions(routine.actions)
        routineManager.startRoutine(routine)
        showingExecution = true
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(RoutineManager())
        .environmentObject(AlarmManager())
        .environmentObject(TimerManager())
}
