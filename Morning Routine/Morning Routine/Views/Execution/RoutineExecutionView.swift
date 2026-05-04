import SwiftUI

/// Full-screen view for executing a routine with timer and actions
struct RoutineExecutionView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var routineManager: RoutineManager
    @EnvironmentObject var alarmManager: AlarmManager
    @Environment(\.dismiss) private var dismiss
    
    let routine: Routine
    @Binding var isPresented: Bool
    
    @State private var showingCompletion = false
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Turn off alarm button (if alarm is beeping)
                if alarmManager.isAlarmBeeping {
                    Button {
                        alarmManager.stopAlarmBeep()
                    } label: {
                        HStack {
                            Image(systemName: "alarm.fill")
                            Text("Turn Off Alarm")
                        }
                        .font(AppTheme.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.top, AppTheme.paddingSmall)
                }
                
                // Header
                executionHeader
                
                Spacer()
                
                // Current action display
                if let currentAction = timerManager.currentAction {
                    actionDisplay(currentAction)
                }
                
                Spacer()
                
                // Timer display
                timerDisplay
                
                Spacer()
                
                // Control buttons
                controlButtons
                
                Spacer()
            }
            .padding(AppTheme.padding)
            
            // Red filter overlay (when enabled for current or next action)
            if timerManager.shouldShowRedFilter,
               (timerManager.isRunning || timerManager.currentActionIndex == 0) {
                Color(red: 1.0, green: 0.0, blue: 0.0)
                    .opacity(0.75)
                    .blendMode(.multiply)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .fullScreenCover(isPresented: $showingCompletion) {
            CompletionView(isExecutionPresented: $isPresented)
                .environmentObject(routineManager)
        }
        .onChange(of: timerManager.allActionsCompleted) { _, completed in
            if completed {
                showingCompletion = true
            }
        }
        .onDisappear {
            timerManager.pause()
            routineManager.stopRoutine()
            timerManager.stopLoudAlarm()
        }
    }
    
    // MARK: - Header
    
    private var executionHeader: some View {
        HStack {
            Button {
                timerManager.pause()
                timerManager.stopLoudAlarm()
                routineManager.stopRoutine()
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.elevatedBackground)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                    )
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(routine.name)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Action \(timerManager.currentActionIndex + 1) of \(routine.actions.count)")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            // Progress indicator
            CircularProgressView(progress: overallProgress)
                .frame(width: 36, height: 36)
        }
        .padding(.vertical, AppTheme.padding)
    }
    
    private var overallProgress: Double {
        guard !routine.actions.isEmpty else { return 0 }
        let completedActions = Double(timerManager.currentActionIndex)
        let currentProgress = timerManager.progress
        return (completedActions + currentProgress) / Double(routine.actions.count)
    }
    
    // MARK: - Action Display
    
    private func actionDisplay(_ action: RoutineAction) -> some View {
        VStack(spacing: AppTheme.padding) {
            // Action icon
            Image(systemName: actionIcon(for: action.name))
                .font(.system(size: 48))
                .foregroundColor(AppTheme.primaryColor)
            
            // Action name
            Text(action.name)
                .font(AppTheme.largeTitle)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
            
            // Duration info
            Text("Duration: \(action.formattedDuration)")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
            
            // Red filter indicator
            if action.useRedFilter {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                    Text("Red filter active")
                }
                .font(AppTheme.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .cornerRadius(AppTheme.cornerRadiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(Color.red, lineWidth: AppTheme.borderWidth)
                )
            }
        }
        .padding(AppTheme.paddingLarge)
    }
    
    private func actionIcon(for name: String) -> String {
        let lowercased = name.lowercased()
        
        if lowercased.contains("brush") || lowercased.contains("teeth") {
            return "mouth.fill"
        } else if lowercased.contains("shower") || lowercased.contains("bath") {
            return "shower.fill"
        } else if lowercased.contains("exercise") || lowercased.contains("workout") {
            return "figure.run"
        } else if lowercased.contains("meditat") {
            return "brain.head.profile"
        } else if lowercased.contains("breakfast") || lowercased.contains("eat") || lowercased.contains("food") {
            return "fork.knife"
        } else if lowercased.contains("coffee") || lowercased.contains("drink") {
            return "cup.and.saucer.fill"
        } else if lowercased.contains("read") || lowercased.contains("book") {
            return "book.fill"
        } else if lowercased.contains("dress") || lowercased.contains("cloth") {
            return "tshirt.fill"
        } else if lowercased.contains("stretch") || lowercased.contains("yoga") {
            return "figure.yoga"
        } else if lowercased.contains("journal") || lowercased.contains("write") {
            return "pencil.and.list.clipboard"
        } else if lowercased.contains("skin") || lowercased.contains("face") {
            return "face.smiling"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        VStack(spacing: AppTheme.paddingSmall) {
            // Main timer
            Text(timerManager.formattedRemainingTime)
                .font(AppTheme.timerFont)
                .foregroundColor(timerManager.remainingSeconds <= 10 && timerManager.isRunning ? .red : AppTheme.primaryColor)
                .monospacedDigit()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.elevatedBackground)
                        .frame(height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                        )
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.primaryColor)
                        .frame(width: geometry.size.width * timerManager.progress, height: 8)
                        .animation(.linear(duration: 0.1), value: timerManager.progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, AppTheme.paddingLarge)
        }
        .padding(AppTheme.paddingLarge)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        VStack(spacing: AppTheme.padding) {
            if !timerManager.isRunning && !timerManager.isCompleted {
                // Start button
                Button {
                    timerManager.start()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Action")
                    }
                    .primaryButtonStyle()
                }
                
                // Skip button
                Button {
                    timerManager.pause()
                    timerManager.moveToNextAction()
                } label: {
                    Text("Skip Action")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.secondaryText)
                }
            } else if timerManager.isRunning {
                // Pause button
                Button {
                    timerManager.pause()
                } label: {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .secondaryButtonStyle()
                }
                
                // Skip button when running on last action
                if !timerManager.hasNextAction {
                    Button {
                        timerManager.pause()
                        timerManager.moveToNextAction()
                    } label: {
                        Text("Skip to Complete")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            } else if timerManager.isCompleted {
                // Move to next or finish
                Button {
                    if timerManager.hasNextAction {
                        timerManager.moveToNextAction()
                    } else {
                        timerManager.moveToNextAction() // This will set allActionsCompleted
                    }
                } label: {
                    HStack {
                        Image(systemName: timerManager.hasNextAction ? "forward.fill" : "checkmark.circle.fill")
                        Text(timerManager.hasNextAction ? "Move to Next Action" : "Complete Routine")
                    }
                    .primaryButtonStyle()
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingLarge)
        .padding(.bottom, AppTheme.paddingLarge)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.elevatedBackground, lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.primaryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.primaryColor)
        }
    }
}

#Preview {
    let routine = Routine(
        name: "Test Routine",
        actions: [
            RoutineAction(name: "Brush Teeth", durationSeconds: 120, useRedFilter: false),
            RoutineAction(name: "Meditate", durationSeconds: 300, useRedFilter: true)
        ]
    )
    
    RoutineExecutionView(routine: routine, isPresented: .constant(true))
        .environmentObject(TimerManager())
        .environmentObject(RoutineManager())
}
