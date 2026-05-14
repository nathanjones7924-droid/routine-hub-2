import Foundation
import AudioToolbox
import AVFoundation
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
    
    /// The currently selected routines (only these will trigger alarms)
    @Published var selectedRoutineIds: Set<UUID> = []
    private var alarmBeepTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
            /// Play a repeating alarm sound until stopped (repeats every 4 seconds)
            /// When the app is active, this will play continuously until user turns off the alarm
            func playAlarmBeep() {
                print("[AlarmManager] Starting alarm sound.")
                stopAlarmBeep()
                isAlarmBeeping = true
                
                // Try to load custom sound file (supports wav, m4a, caf, and mp3)
                if let soundURL = Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "wav") ??
                                  Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "m4a") ??
                                  Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "caf") ??
                                  Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "mp3") {
                    do {
                        audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                        audioPlayer?.numberOfLoops = -1 // Infinite loop
                        audioPlayer?.play()
                        print("[AlarmManager] Playing custom alarm sound (infinite loop)")
                    } catch {
                        print("[AlarmManager] Error loading custom sound: \(error)")
                        playSystemAlarmFallback()
                    }
                } else {
                    print("[AlarmManager] Custom sound file not found, using system sound")
                    playSystemAlarmFallback()
                }
            }
            
            /// Fallback to system sound if custom sound is not available
            private func playSystemAlarmFallback() {
                alarmBeepTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                    AudioServicesPlaySystemSound(1304)
                    print("[AlarmManager] System alarm beep")
                }
                if let timer = alarmBeepTimer {
                    RunLoop.main.add(timer, forMode: .common)
                }
                AudioServicesPlaySystemSound(1304)
            }

            /// Stop the alarm beep sound
            func stopAlarmBeep() {
                if alarmBeepTimer != nil {
                    print("[AlarmManager] Alarm beep manually stopped.")
                }
                alarmBeepTimer?.invalidate()
                alarmBeepTimer = nil
                audioPlayer?.stop()
                audioPlayer = nil
                isAlarmBeeping = false
                // Don't clear triggeredRoutine here - let it persist so the UI can show the routine
            }

            /// Prevent alarm beeping for a specific routine for a short window
            func suppressAlarmBeep(for routineId: UUID, duration: TimeInterval = 60) {
                suppressBeepRoutineId = routineId
                suppressBeepUntil = Date().addingTimeInterval(duration)
            }

            private func shouldSuppressBeep(for routineId: UUID, now: Date) -> Bool {
                guard suppressBeepRoutineId == routineId, let suppressUntil = suppressBeepUntil else {
                    return false
                }
                if suppressUntil > now {
                    return true
                }
                suppressBeepRoutineId = nil
                suppressBeepUntil = nil
                return false
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
    private var suppressBeepUntil: Date?
    private var suppressBeepRoutineId: UUID?
    weak var locationManager: LocationManager?
    weak var settingsManager: SettingsManager?
    
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
            print("[AlarmManager] Selected routines: \(selectedRoutineIds.count)")
            print("[AlarmManager] Checking \(routines.count) routines for alarms")
        }
        
        // Check all selected routines for alarms
        let selectedRoutines = routines.filter { selectedRoutineIds.contains($0.id) }
        
        for routine in selectedRoutines where routine.alarmEnabled {
            // Skip if today's weekday is not in the routine's selected days
            // Calendar weekday: 1=Sunday, 2=Monday, ... 7=Saturday (matches our model)
            let todayWeekday = calendar.component(.weekday, from: now)
            if !routine.selectedDays.contains(todayWeekday) {
                continue
            }
            
            // Skip if alarm is already beeping for this routine
            if isAlarmBeeping && triggeredRoutine?.id == routine.id {
                print("[AlarmManager] Skipping routine \(routine.name) - alarm already beeping")
                continue
            }
            
            // Skip if we already triggered for this routine in this minute (prevent re-triggering after manual stop)
            if let lastTriggered = lastTriggeredMinute,
               lastTriggered.routineId == routine.id,
               lastTriggered.hour == nowHour,
               lastTriggered.minute == nowMinute {
                return
            }
            
            // Calculate alarm time - if sun-based mode is enabled, recalculate daily
            let alarmTime: Date
            var usingSunEvent = false
            var sunEventName = ""
            
            if routine.wakeUpWithSun, let sunriseTime = locationManager?.sunriseTime {
                // Recalculate alarm time daily: apply configured offset from sunrise
                let minutesBeforeSunrise = settingsManager?.minutesBeforeSunrise ?? -3
                if let sunriseAlarmTime = calendar.date(byAdding: .minute, value: minutesBeforeSunrise, to: sunriseTime) {
                    alarmTime = sunriseAlarmTime
                    usingSunEvent = true
                    sunEventName = "sunrise"
                } else {
                    // Fallback to stored alarm time if calculation fails
                    let routineHour = calendar.component(.hour, from: routine.alarmTime)
                    let routineMinute = calendar.component(.minute, from: routine.alarmTime)
                    alarmTime = calendar.date(bySettingHour: routineHour, minute: routineMinute, second: 0, of: now) ?? routine.alarmTime
                }
            } else if routine.goToBedWithSun, let sunsetTime = locationManager?.sunsetTime {
                // Recalculate alarm time daily: apply configured offset from sunset
                let minutesFromSunset = settingsManager?.minutesFromSunset ?? -3
                if let sunsetAlarmTime = calendar.date(byAdding: .minute, value: minutesFromSunset, to: sunsetTime) {
                    alarmTime = sunsetAlarmTime
                    usingSunEvent = true
                    sunEventName = "sunset"
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
                if triggeredRoutine?.id != routine.id {
                    if usingSunEvent {
                        print("[AlarmManager] ⏰ \(sunEventName.capitalized)-based alarm triggered for routine: \(routine.name)")
                    } else {
                        print("[AlarmManager] ⏰ Alarm time matched for routine: \(routine.name). Opening routine.")
                    }
                    // Just set the triggered routine - the notification handles the sound
                    triggeredRoutine = routine
                    // Remember that we triggered for this routine in this minute
                    lastTriggeredMinute = (hour: nowHour, minute: nowMinute, routineId: routine.id)
                } else {
                    print("[AlarmManager] ⚠️ Already triggered for this routine, skipping")
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
        content.body = "Time to start your routine!"
        // Use custom alarm sound (CAF) for wakeup notifications
        if Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "caf") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("ringtone-1-275863.caf"))
        } else {
            content.sound = UNNotificationSound.defaultCritical
        }
        content.categoryIdentifier = alarmCategoryIdentifier
        content.userInfo = ["routineId": routine.id.uuidString]
        content.interruptionLevel = .critical
        
        // Calculate alarm time
        var alarmDate: Date
        
        if routine.wakeUpWithSun, let sunriseTime = locationManager?.sunriseTime {
            // Use configured minutes offset from sunrise (negative = before, positive = after)
            let minutesBeforeSunrise = settingsManager?.minutesBeforeSunrise ?? -3
            alarmDate = Calendar.current.date(byAdding: .minute, value: minutesBeforeSunrise, to: sunriseTime) ?? routine.alarmTime
            print("[AlarmManager] Scheduling sunrise-based alarm: \(minutesBeforeSunrise) min from sunrise")
        } else if routine.goToBedWithSun, let sunsetTime = locationManager?.sunsetTime {
            // Use configured minutes offset from sunset (negative = before, positive = after)
            let minutesFromSunset = settingsManager?.minutesFromSunset ?? -3
            alarmDate = Calendar.current.date(byAdding: .minute, value: minutesFromSunset, to: sunsetTime) ?? routine.alarmTime
            print("[AlarmManager] Scheduling sunset-based alarm: \(minutesFromSunset) min from sunset")
        } else {
            alarmDate = routine.alarmTime
        }
        
        // Schedule a separate notification for each selected day
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarmDate)
        let minute = calendar.component(.minute, from: alarmDate)
        
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        for day in routine.selectedDays {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = day // 1=Sunday ... 7=Saturday
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "\(alarmIdentifier(for: routine))_day\(day)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await notificationCenter.add(request)
                let dayName = day >= 1 && day <= 7 ? dayNames[day] : "??"
                print("[AlarmManager] ✅ Alarm scheduled for routine '\(routine.name)' at \(hour):\(String(format: "%02d", minute)) on \(dayName)")
            } catch {
                print("[AlarmManager] ❌ Error scheduling alarm for day \(day): \(error)")
            }
        }
        
        if routine.selectedDays.isEmpty {
            print("[AlarmManager] ⚠️ No days selected for routine '\(routine.name)', no alarms scheduled")
        }
    }
    
    /// Cancel an alarm for a routine
    func cancelAlarm(for routine: Routine) async {
        // Cancel the base identifier plus all day-specific identifiers
        let baseId = alarmIdentifier(for: routine)
        var ids = [baseId]
        for day in 1...7 {
            ids.append("\(baseId)_day\(day)")
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
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
        
        // Only schedule alarms for selected routines
        let selectedRoutines = routines.filter { selectedRoutineIds.contains($0.id) && $0.alarmEnabled }
        for routine in selectedRoutines {
            await scheduleAlarm(for: routine)
        }
        
        // Log pending notifications
        let pending = await notificationCenter.pendingNotificationRequests()
        print("[AlarmManager] Total pending alarms: \(pending.count)")
    }
    
    /// Reschedule sunrise alarms (call this when location updates)
    func rescheduleSunriseAlarms(routines: [Routine]) async {
        // Reschedule all sun-based alarms (sunrise and sunset) for selected routines
        let selectedRoutines = routines.filter {
            selectedRoutineIds.contains($0.id)
                && $0.alarmEnabled
                && ($0.wakeUpWithSun || $0.goToBedWithSun)
        }
        for routine in selectedRoutines {
            await scheduleAlarm(for: routine)
        }
    }
    
    /// Snooze alarm for 5 minutes
    func snoozeAlarm(for routine: Routine) async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(routine.name) - Snoozed"
        content.body = "Time to start your routine!"
        // Use custom alarm sound (CAF) for snooze
        if Bundle.main.url(forResource: "ringtone-1-275863", withExtension: "caf") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("ringtone-1-275863.caf"))
        } else {
            content.sound = UNNotificationSound.defaultCritical
        }
        content.categoryIdentifier = alarmCategoryIdentifier
        content.userInfo = ["routineId": routine.id.uuidString]
        content.interruptionLevel = .critical
        
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
