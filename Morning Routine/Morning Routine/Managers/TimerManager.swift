import Foundation
import AudioToolbox
import AVFoundation
import Combine
import FirebaseAnalytics
import UserNotifications
import UIKit

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
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// The time when the current action started (used for background sync)
    private var actionStartTime: Date?
    
    /// The expected end time for the current action
    private var expectedEndTime: Date?
    
    /// Audio player for loud alarm
    private var audioPlayer: AVAudioPlayer?
    
    /// Timer for repeating loud alarm
    private var loudAlarmTimer: Timer?
    private let timerStateKey = "actionTimerState"
    
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
    
    /// The next action after the current one
    var nextAction: RoutineAction? {
        let nextIndex = currentActionIndex + 1
        guard nextIndex < actions.count else { return nil }
        return actions[nextIndex]
    }
    
    /// Whether the red filter should be shown
    /// Shows filter if current action has it, OR if we're in a sequence where the next action has it
    /// and the previous action also had it (continuous sequence)
    var shouldShowRedFilter: Bool {
        let currentHasFilter = currentAction?.useRedFilter ?? false
        
        // If current action has filter, always show
        if currentHasFilter {
            return true
        }
        
        // Check if we're between red filter actions (previous had it AND next has it)
        // This keeps the filter on during transitions between consecutive red filter actions
        let previousHasFilter = previousAction?.useRedFilter ?? false
        let nextHasFilter = nextAction?.useRedFilter ?? false
        
        // Show filter if next action has it (to prepare user)
        // OR if we just finished a red filter action and next one also has it
        return nextHasFilter || (previousHasFilter && !isRunning && hasNextAction && nextHasFilter)
    }
    
    /// The previous action before the current one
    var previousAction: RoutineAction? {
        let prevIndex = currentActionIndex - 1
        guard prevIndex >= 0 else { return nil }
        return actions[prevIndex]
    }
    
    // MARK: - Timer Control
    
    /// Setup timer with a list of actions
    func setupWithActions(_ routineActions: [RoutineAction]) {
        // Stop any existing timer
        stopTimer()
        stopLoudAlarm()
        
        actions = routineActions
        currentActionIndex = 0
        allActionsCompleted = false
        hasPlayedCompletionSound = false
        
        if let firstAction = actions.first {
            remainingSeconds = firstAction.durationSeconds
        }
        
        isRunning = false
        isCompleted = false
        actionStartTime = nil
        expectedEndTime = nil
        
        clearTimerState()
        print("[TimerManager] Setup with \(routineActions.count) actions")
    }
    
    /// Start or resume the countdown timer
    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        
        isRunning = true
        isCompleted = false
        hasPlayedCompletionSound = false
        
        // Record start time and calculate expected end time
        actionStartTime = Date()
        expectedEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        
        print("[TimerManager] Starting timer: \(remainingSeconds)s, expected end: \(expectedEndTime?.description ?? "nil")")
        
        // Begin background task
        beginBackgroundTask()
        
        // Schedule notification for when action completes
        scheduleActionCompletionNotification()
        
        // Start the timer
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
        saveTimerState()
    }
    
    /// Pause the countdown timer
    func pause() {
        stopTimer()
        
        // End background task when paused
        endBackgroundTask()
        
        // Cancel scheduled notification
        cancelActionNotifications()
        clearTimerState()
        print("[TimerManager] Paused at \(remainingSeconds)s")
    }
    
    /// Stop the timer (internal use)
    private func stopTimer() {
        isRunning = false
        timer?.cancel()
        timer = nil
        actionStartTime = nil
        expectedEndTime = nil
    }
    
    /// Stop and reset the timer to current action's duration
    func stop() {
        pause()
        remainingSeconds = currentAction?.durationSeconds ?? 0
        isCompleted = false
        clearTimerState()
    }
    
    /// Reset the entire routine execution
    func reset() {
        pause()
        stopLoudAlarm()
        currentActionIndex = 0
        allActionsCompleted = false
        hasPlayedCompletionSound = false
        
        if let firstAction = actions.first {
            remainingSeconds = firstAction.durationSeconds
        }
        
        isCompleted = false
        clearTimerState()
        print("[TimerManager] Reset routine")
    }
    
    /// Move to the next action
    func moveToNextAction() {
        pause()
        stopLoudAlarm()
        
        if currentActionIndex < actions.count - 1 {
            currentActionIndex += 1
            remainingSeconds = actions[currentActionIndex].durationSeconds
            isCompleted = false
            hasPlayedCompletionSound = false
            clearTimerState()
            
            print("[TimerManager] Moved to action \(currentActionIndex): \(currentAction?.name ?? "unknown")")
        } else {
            // All actions completed
            allActionsCompleted = true
            
            Analytics.logEvent("routine_completed", parameters: [
                "total_actions": actions.count,
                "total_duration_seconds": actions.reduce(0) { $0 + $1.durationSeconds }
            ])
            
            print("[TimerManager] All actions completed")
            clearTimerState()
        }
    }
    
    // MARK: - Timer Tick
    
    private func tick() {
        guard isRunning else { return }
        
        // Calculate remaining time based on expected end time for accuracy
        if let endTime = expectedEndTime {
            let remaining = Int(ceil(endTime.timeIntervalSinceNow))
            remainingSeconds = max(0, remaining)
        } else if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        
        // Check if completed
        if remainingSeconds <= 0 && !hasPlayedCompletionSound {
            completeCurrentAction()
        }
    }
    
    /// Complete the current action - called when timer reaches zero
    private func completeCurrentAction() {
        print("[TimerManager] Action completed: \(currentAction?.name ?? "unknown")")
        
        stopTimer()
        endBackgroundTask()
        cancelActionNotifications()
        
        remainingSeconds = 0
        isCompleted = true
        hasPlayedCompletionSound = true
        clearTimerState()
        
        // Play completion sound if alarm is enabled
        if let action = currentAction, action.isAlarmEnabled {
            playCompletionSound(useLoud: action.useLoudAlarm)
        }
        
        // Log analytics
        if let action = currentAction {
            Analytics.logEvent("action_completed", parameters: [
                "action_name": action.name,
                "action_duration_seconds": action.durationSeconds,
                "action_index": currentActionIndex,
                "total_actions": actions.count
            ])
        }
    }
    
    // MARK: - Background Sync
    
    /// Sync timer state when app returns to foreground
    func syncTimerWithElapsedTime() {
        guard isRunning, let endTime = expectedEndTime else { return }
        
        let remaining = Int(ceil(endTime.timeIntervalSinceNow))
        
        print("[TimerManager] Sync: remaining=\(remaining)s (was \(remainingSeconds)s)")
        
        if remaining <= 0 && !hasPlayedCompletionSound {
            // Timer should have completed while in background
            completeCurrentAction()
            print("[TimerManager] Action completed during background")
        } else {
            remainingSeconds = max(0, remaining)
            saveTimerState()
        }
    }
    
    /// Mark the current action as completed (called from notification handler)
    func markCurrentActionCompleted() {
        guard !hasPlayedCompletionSound else { return }
        
        stopTimer()
        endBackgroundTask()
        
        remainingSeconds = 0
        isCompleted = true
        hasPlayedCompletionSound = true
        clearTimerState()
        
        print("[TimerManager] Action marked completed from notification")
    }

    // MARK: - Persistence

    private struct TimerState: Codable {
        let expectedEndTime: TimeInterval
        let currentActionIndex: Int
        let remainingSeconds: Int
        let isRunning: Bool
    }

    private func saveTimerState() {
        guard let endTime = expectedEndTime else { return }
        let state = TimerState(
            expectedEndTime: endTime.timeIntervalSince1970,
            currentActionIndex: currentActionIndex,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: timerStateKey)
        }
    }

    private func clearTimerState() {
        UserDefaults.standard.removeObject(forKey: timerStateKey)
    }

    func restoreTimerStateIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: timerStateKey),
              let state = try? JSONDecoder().decode(TimerState.self, from: data) else {
            return
        }
        guard state.currentActionIndex < actions.count else { return }
        currentActionIndex = state.currentActionIndex
        expectedEndTime = Date(timeIntervalSince1970: state.expectedEndTime)
        let remaining = Int(ceil(expectedEndTime?.timeIntervalSinceNow ?? 0))
        remainingSeconds = max(0, remaining)
        isRunning = state.isRunning
        if isRunning && remainingSeconds > 0 {
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.tick()
                }
            scheduleActionCompletionNotification()
        } else if remainingSeconds <= 0 && !hasPlayedCompletionSound {
            completeCurrentAction()
        }
    }
    
    // MARK: - Sound Playback
    
    /// Play completion sound
    func playCompletionSound(useLoud: Bool = false) {
        if useLoud {
            startLoudAlarmRepeating()
        } else {
            // Original quiet system beep
            AudioServicesPlaySystemSound(1000)
            print("[TimerManager] Quiet action beep played")
        }
    }
    
    /// Start the loud alarm and repeat every 4 seconds until stopped
    private func startLoudAlarmRepeating() {
        stopLoudAlarm()
        configureAudioSessionForLoudAlarm()
        playLoudAlarmOnce()
        loudAlarmTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playLoudAlarmOnce()
            }
        }
        if let timer = loudAlarmTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        print("[TimerManager] Loud alarm started (repeats every 4s)")
    }
    
    /// Play the loud alarm sound once
    private func playLoudAlarmOnce() {
        if let soundURL = Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "mp3") {
            do {
                audioPlayer?.stop()
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 1.0
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("[TimerManager] Loud alarm played (custom mp3)")
                return
            } catch {
                print("[TimerManager] Loud alarm mp3 failed: \(error)")
            }
        }
        AudioServicesPlayAlertSound(1005)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        print("[TimerManager] Loud alarm played (system fallback)")
    }

    
    private func configureAudioSessionForLoudAlarm() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[TimerManager] Audio session error: \(error)")
        }
    }
    
    /// Stop the loud alarm
    func stopLoudAlarm() {
        loudAlarmTimer?.invalidate()
        loudAlarmTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore errors when deactivating
        }
        
        print("[TimerManager] Loud alarm stopped")
    }
    
    // MARK: - Background Task
    
    private func beginBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        print("[TimerManager] Background task started")
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        print("[TimerManager] Background task ended")
    }
    
    // MARK: - Notifications
    
    /// Schedule notification for action completion
    private func scheduleActionCompletionNotification() {
        guard let action = currentAction, remainingSeconds > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Action Complete!"
        content.body = "\(action.name) has finished. Time for the next step!"
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "ACTION_COMPLETION"
        
        // Store action info
        content.userInfo = [
            "actionIndex": currentActionIndex,
            "useLoudAlarm": action.useLoudAlarm,
            "isAlarmEnabled": action.isAlarmEnabled
        ]
        
        // Notification sound (background only)
        if action.isAlarmEnabled {
            if action.useLoudAlarm {
                if Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "caf") != nil {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName("ringtone-1-275863.caf"))
                } else {
                    content.sound = UNNotificationSound.defaultCritical
                }
            } else {
                content.sound = UNNotificationSound.default
            }
        } else {
            content.sound = nil
        }
        
        // Schedule for when timer completes
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(remainingSeconds),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "action_completion_\(currentActionIndex)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("[TimerManager] Notification error: \(error)")
            } else {
                print("[TimerManager] Notification scheduled for '\(action.name)' in \(self.remainingSeconds)s (loud: \(action.useLoudAlarm))")
            }
        }
    }
    
    /// Cancel action completion notifications
    private func cancelActionNotifications() {
        let identifier = "action_completion_\(currentActionIndex)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("[TimerManager] Notification cancelled")
    }
}
