import Foundation
import AudioToolbox
import Combine
import FirebaseAnalytics

/// Manages countdown timers and audio alerts for routine execution
@MainActor
class TimerManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Remaining time in seconds for current action
    @Published var remainingSeconds: Int = 0
    
    /// Whether the timer is currently running
    @Published var isRunning: Bool = false
    
    /// Whether the timer has completed (hit zero)
    @Published var isCompleted: Bool = false
    
    /// Current action index being executed
    @Published var currentActionIndex: Int = 0
    
    /// Whether all actions have been completed
    @Published var allActionsCompleted: Bool = false
    
    // MARK: - Private Properties
    
    private var timer: AnyCancellable?
    private var actions: [RoutineAction] = []
    private var hasPlayedCompletionSound = false
    
    // MARK: - Computed Properties
    
    /// The currently executing action
    var currentAction: RoutineAction? {
        guard currentActionIndex < actions.count else { return nil }
        return actions[currentActionIndex]
    }
    
    /// Progress of current action (0.0 to 1.0)
    var progress: Double {
        guard let action = currentAction, action.durationSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(action.durationSeconds))
    }
    
    /// Formatted remaining time string (e.g., "2:45")
    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Whether there are more actions after the current one
    var hasNextAction: Bool {
        return currentActionIndex < actions.count - 1
    }
    
    // MARK: - Timer Control
    
    /// Setup timer with a list of actions
    func setupWithActions(_ routineActions: [RoutineAction]) {
        actions = routineActions
        currentActionIndex = 0
        allActionsCompleted = false
        hasPlayedCompletionSound = false
        
        if let firstAction = actions.first {
            remainingSeconds = firstAction.durationSeconds
        }
        
        isRunning = false
        isCompleted = false
    }
    
    /// Start or resume the countdown timer
    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        
        isRunning = true
        isCompleted = false
        hasPlayedCompletionSound = false
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    /// Pause the countdown timer
    func pause() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }
    
    /// Stop and reset the timer
    func stop() {
        pause()
        remainingSeconds = currentAction?.durationSeconds ?? 0
        isCompleted = false
    }
    
    /// Reset the entire routine execution
    func reset() {
        pause()
        currentActionIndex = 0
        allActionsCompleted = false
        hasPlayedCompletionSound = false
        
        if let firstAction = actions.first {
            remainingSeconds = firstAction.durationSeconds
        }
        
        isCompleted = false
    }
    
    /// Move to the next action
    func moveToNextAction() {
        pause()
        
        if currentActionIndex < actions.count - 1 {
            currentActionIndex += 1
            remainingSeconds = actions[currentActionIndex].durationSeconds
            isCompleted = false
            hasPlayedCompletionSound = false // Reset for new action
        } else {
            // All actions completed
            allActionsCompleted = true
            // Don't play sound here - it should have already played when the timer reached 0
            
            // Log analytics event for routine completion
            Analytics.logEvent("routine_completed", parameters: [
                "total_actions": actions.count,
                "total_duration_seconds": actions.reduce(0) { $0 + $1.durationSeconds }
            ])
        }
    }
    
    // MARK: - Private Methods
    
    private func tick() {
        guard isRunning else { return } // Safety check: only tick if running
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        
        if remainingSeconds == 0 && !hasPlayedCompletionSound && isRunning {
            pause() // Stop timer first
            isCompleted = true
            hasPlayedCompletionSound = true
            
            // Only play sound if this action has alarm enabled
            if let action = currentAction, action.isAlarmEnabled {
                playCompletionSound()
            }
            
            // Log analytics event for action completion
            if let action = currentAction {
                Analytics.logEvent("action_completed", parameters: [
                    "action_name": action.name,
                    "action_duration_seconds": action.durationSeconds,
                    "action_index": currentActionIndex,
                    "total_actions": actions.count
                ])
            }
        }
    }
    
    /// Play a beep/alert sound when timer completes
    func playCompletionSound() {
        // System sound ID 1000 is a simple single beep alert
        AudioServicesPlaySystemSound(1000)
        print("[TimerManager] Action completion beep played")
    }
}
