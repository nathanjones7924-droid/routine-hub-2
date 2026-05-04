import Foundation
import AudioToolbox
@preconcurrency import UserNotifications
import Combine

/// Manages alarm notifications for routines
@MainActor
class AlarmManager: ObservableObject {
                @Published var triggeredRoutine: Routine? = nil
            /// Whether the alarm beep menu should be shown
            @Published var isAlarmBeeping: Bool = false
        /// All routines to check for alarms
        @Published var routines: [Routine] = []
    
    /// The currently selected routine (only this one will trigger alarms)
    @Published var selectedRoutineId: UUID? = nil
    private var alarmBeepTimer: Timer?
            /// Play a repeating beep sound until stopped (beeps every second)
            /// When the app is active, this will beep continuously until user turns off the alarm
            func playAlarmBeep() {
                print("[AlarmManager] Starting alarm beep sound.")
                stopAlarmBeep()
                isAlarmBeeping = true
                alarmBeepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                    guard self != nil else { return }
                    AudioServicesPlaySystemSound(1304) // System beep
                    print("[AlarmManager] Beep")
                }
                // Add to common run loop modes so it runs even when scrolling/interacting
                if let timer = alarmBeepTimer {
                    RunLoop.main.add(timer, forMode: .common)
                }
                // Play first beep immediately
                AudioServicesPlaySystemSound(1304)
            }

            /// Stop the alarm beep sound
            func stopAlarmBeep() {
                if alarmBeepTimer != nil {
                    print("[AlarmManager] Alarm beep manually stopped.")
                }
                alarmBeepTimer?.invalidate()
                alarmBeepTimer = nil
                isAlarmBeeping = false
                // Don't clear triggeredRoutine here - let it persist so the UI can show the routine
            }
        private var timeLoggerTimer: Timer?
    private var lastTriggeredMinute: (hour: Int, minute: Int, routineId: UUID)? = nil
    // MARK: - Published Properties
    
    /// Whether notification permissions have been granted
    @Published var notificationsEnabled: Bool = false
    
    /// Whether we've requested permissions
    @Published var hasRequestedPermission: Bool = false
    
    // MARK: - Private Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let alarmCategoryIdentifier = "MORNING_ROUTINE_ALARM"
    weak var locationManager: LocationManager?
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkNotificationStatus()
        }
        startTimeLogger()
    }

    /// Starts a timer that checks for alarms every second
    private func startTimeLogger() {
        timeLoggerTimer?.invalidate()
        // Check every second to ensure we don't miss the alarm time
        // Use main run loop to ensure it runs even when app is active
        timeLoggerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.checkAlarms()
            }
        }
        // Add to common run loop modes so it runs even when scrolling/interacting
        RunLoop.main.add(timeLoggerTimer!, forMode: .common)
        // Also run immediately
        Task { @MainActor in
            checkAlarms()
        }
    }

    private var lastCheckedMinute: Int = -1
    
    private func checkAlarms() {
        let now = Date()
        let calendar = Calendar.current
        let nowHour = calendar.component(.hour, from: now)
        let nowMinute = calendar.component(.minute, from: now)
        let nowSecond = calendar.component(.second, from: now)
        
        // Only log once per minute to avoid spam
        if nowMinute != lastCheckedMinute {
            lastCheckedMinute = nowMinute
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .none
            print("[AlarmManager] Current time: \(formatter.string(from: now))")
            print("[AlarmManager] Selected routine: \(selectedRoutineId?.uuidString ?? "none")")
            print("[AlarmManager] Checking \(routines.count) routines for alarms")
        }
        
        // Only check the selected routine for alarms
        guard let selectedId = selectedRoutineId,
              let routine = routines.first(where: { $0.id == selectedId }) else {
            if nowMinute != lastCheckedMinute - 1 {
                // Print once per minute only
            }
            return
        }
        
        // Check if the selected routine has alarm enabled
        if routine.alarmEnabled {
            // Skip if alarm is already beeping for this routine
            if isAlarmBeeping && triggeredRoutine?.id == routine.id {
                print("[AlarmManager] Skipping routine \(routine.name) - alarm already beeping")
                return
            }
            
            // Skip if we already triggered for this routine in this minute (prevent re-triggering after manual stop)
            if let lastTriggered = lastTriggeredMinute,
               lastTriggered.routineId == routine.id,
               lastTriggered.hour == nowHour,
               lastTriggered.minute == nowMinute {
                return
            }
            
            // Calculate alarm time - if wakeUpWithSun is enabled, recalculate daily based on sunrise
            let alarmTime: Date
            var usingSunrise = false
            
            if routine.wakeUpWithSun, let sunriseTime = locationManager?.sunriseTime {
                // Recalculate alarm time daily: 5 minutes before today's sunrise
                if let sunriseAlarmTime = calendar.date(byAdding: .minute, value: -5, to: sunriseTime) {
                    alarmTime = sunriseAlarmTime
                    usingSunrise = true
                } else {
                    // Fallback to stored alarm time if calculation fails
                    let routineHour = calendar.component(.hour, from: routine.alarmTime)
                    let routineMinute = calendar.component(.minute, from: routine.alarmTime)
                    alarmTime = calendar.date(bySettingHour: routineHour, minute: routineMinute, second: 0, of: now) ?? routine.alarmTime
                }
            } else {
                // Use the routine's stored alarm time (normalize to today's date for accurate comparison)
                let routineHour = calendar.component(.hour, from: routine.alarmTime)
                let routineMinute = calendar.component(.minute, from: routine.alarmTime)
                alarmTime = calendar.date(bySettingHour: routineHour, minute: routineMinute, second: 0, of: now) ?? routine.alarmTime
            }
            
            let alarmHour = calendar.component(.hour, from: alarmTime)
            let alarmMinute = calendar.component(.minute, from: alarmTime)
            
            // Debug: Log comparison details when close to alarm time or every 10 seconds
            let shouldLog = (nowHour == alarmHour && abs(nowMinute - alarmMinute) <= 2) || nowSecond % 10 == 0
            if shouldLog {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .none
                let alarmTimeStr = formatter.string(from: alarmTime)
                let match = nowHour == alarmHour && nowMinute == alarmMinute
                print("[AlarmManager] Routine '\(routine.name)': Current=\(nowHour):\(String(format: "%02d", nowMinute)):\(String(format: "%02d", nowSecond)), Alarm=\(alarmHour):\(String(format: "%02d", alarmMinute)) (\(alarmTimeStr)), Match=\(match), isAlarmBeeping=\(isAlarmBeeping), alarmEnabled=\(routine.alarmEnabled)")
            }
            
            // Trigger alarm when hour and minute match
            if nowHour == alarmHour && nowMinute == alarmMinute {
                print("[AlarmManager] ✅ TIME MATCHED for routine '\(routine.name)'!")
                // Only trigger if we haven't already triggered for this routine in this minute
                if !isAlarmBeeping || triggeredRoutine?.id != routine.id {
                    if usingSunrise {
                        print("[AlarmManager] ⏰ Sunrise-based alarm triggered for routine: \(routine.name) (5 minutes before sunrise)")
                    } else {
                        print("[AlarmManager] ⏰ Alarm time matched for routine: \(routine.name). Playing beep and starting routine.")
                    }
                    print("[AlarmManager] Calling playAlarmBeep()...")
                    playAlarmBeep()
                    triggeredRoutine = routine
                    // Remember that we triggered for this routine in this minute
                    lastTriggeredMinute = (hour: nowHour, minute: nowMinute, routineId: routine.id)
                    print("[AlarmManager] Alarm beep started. isAlarmBeeping: \(isAlarmBeeping)")
                } else {
                    print("[AlarmManager] ⚠️ Alarm already beeping for this routine, skipping")
                }
            } else {
                // Clear the last triggered minute when we move to a new minute
                if let lastTriggered = lastTriggeredMinute,
                   (lastTriggered.hour != nowHour || lastTriggered.minute != nowMinute) {
                    lastTriggeredMinute = nil
                }
            }
        }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from the user
    func requestPermission() async {
        print("[AlarmManager] Requesting notification permission...")
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.notificationsEnabled = granted
                self.hasRequestedPermission = true
            }
            print("[AlarmManager] Notification permission granted: \(granted)")
            if granted {
                await setupNotificationCategory()
            }
        } catch {
            print("[AlarmManager] Error requesting notification permission: \(error)")
            await MainActor.run {
                self.hasRequestedPermission = true
            }
        }
    }
    
    /// Check current notification permission status
    func checkNotificationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.notificationsEnabled = settings.authorizationStatus == .authorized
            self.hasRequestedPermission = settings.authorizationStatus != .notDetermined
        }
    }
    
    /// Setup notification category with actions
    private func setupNotificationCategory() async {
        let startAction = UNNotificationAction(
            identifier: "START_ROUTINE",
            title: "Start Routine",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 5 min",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: alarmCategoryIdentifier,
            actions: [startAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    // MARK: - Alarm Scheduling
    
    /// Schedule an alarm notification for a routine
    func scheduleAlarm(for routine: Routine) async {
        guard routine.alarmEnabled else {
            print("[AlarmManager] Alarm disabled for routine: \(routine.name)")
            return
        }
        
        // First cancel any existing alarm for this routine
        await cancelAlarm(for: routine)
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(routine.name)"
        content.body = "Time to start your morning routine!"
        // Use custom alarm sound if available, otherwise use default ringtone (loud)
        // To add a custom sound: Add a .wav/.caf/.m4a file up to 30 seconds named "alarm_sound.wav" to your project
        // For longer alarm sounds, use a longer audio file (max 30 seconds for notifications)
        if Bundle.main.url(forResource: "alarm_sound", withExtension: "wav") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.wav"))
        } else {
            content.sound = UNNotificationSound.defaultRingtone
        }
        content.categoryIdentifier = alarmCategoryIdentifier
        content.userInfo = ["routineId": routine.id.uuidString]
        content.interruptionLevel = .timeSensitive
        
        // Calculate alarm time
        var alarmDate: Date
        
        if routine.wakeUpWithSun, let sunriseTime = locationManager?.sunriseTime {
            // 5 minutes before sunrise
            alarmDate = Calendar.current.date(byAdding: .minute, value: -5, to: sunriseTime) ?? routine.alarmTime
            print("[AlarmManager] Scheduling sunrise-based alarm: 5 min before sunrise")
        } else {
            alarmDate = routine.alarmTime
        }
        
        // Create date components for the alarm time (daily repeating)
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: alarmDate)
        dateComponents.minute = calendar.component(.minute, from: alarmDate)
        
        // Create trigger that repeats daily
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: alarmIdentifier(for: routine),
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            print("[AlarmManager] ✅ Alarm scheduled for routine '\(routine.name)' at \(formatter.string(from: alarmDate)) (repeats daily)")
        } catch {
            print("[AlarmManager] ❌ Error scheduling alarm: \(error)")
        }
    }
    
    /// Cancel an alarm for a routine
    func cancelAlarm(for routine: Routine) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarmIdentifier(for: routine)])
        print("[AlarmManager] Cancelled alarm for routine: \(routine.name)")
    }
    
    /// Cancel all alarms
    func cancelAllAlarms() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("[AlarmManager] All alarms cancelled")
    }
    
    /// Update alarms for all routines
    func updateAllAlarms(routines: [Routine]) async {
        // Cancel all existing alarms
        cancelAllAlarms()
        
        // Only schedule alarm for the selected routine
        if let selectedId = selectedRoutineId,
           let selectedRoutine = routines.first(where: { $0.id == selectedId }),
           selectedRoutine.alarmEnabled {
            await scheduleAlarm(for: selectedRoutine)
        }
        
        // Log pending notifications
        let pending = await notificationCenter.pendingNotificationRequests()
        print("[AlarmManager] Total pending alarms: \(pending.count)")
    }
    
    /// Reschedule sunrise alarms (call this when location updates)
    func rescheduleSunriseAlarms(routines: [Routine]) async {
        // Only reschedule if the selected routine has sunrise-based alarm
        if let selectedId = selectedRoutineId,
           let selectedRoutine = routines.first(where: { $0.id == selectedId }),
           selectedRoutine.alarmEnabled && selectedRoutine.wakeUpWithSun {
            await scheduleAlarm(for: selectedRoutine)
        }
    }
    
    /// Snooze alarm for 5 minutes
    func snoozeAlarm(for routine: Routine) async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(routine.name) - Snoozed"
        content.body = "Time to start your morning routine!"
        // Use custom alarm sound if available, otherwise use default ringtone (loud)
        if Bundle.main.url(forResource: "alarm_sound", withExtension: "wav") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.wav"))
        } else {
            content.sound = UNNotificationSound.defaultRingtone
        }
        content.categoryIdentifier = alarmCategoryIdentifier
        content.userInfo = ["routineId": routine.id.uuidString]
        content.interruptionLevel = .timeSensitive
        
        // Trigger in 5 minutes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "snooze_\(routine.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("[AlarmManager] ⏰ Snooze scheduled for 5 minutes")
        } catch {
            print("[AlarmManager] ❌ Error scheduling snooze: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func alarmIdentifier(for routine: Routine) -> String {
        return "alarm_\(routine.id.uuidString)"
    }
}
