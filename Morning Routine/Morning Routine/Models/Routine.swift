import Foundation

/// Represents a complete morning routine with alarm and actions
struct Routine: Identifiable, Codable, Equatable {
    /// Unique identifier for the routine
    var id: UUID
    
    /// Name of the routine (e.g., "Weekday Morning", "Weekend Relaxed")
    var name: String
    
    /// Whether the alarm is enabled for this routine
    var alarmEnabled: Bool
    
    /// The time the alarm should go off (only time components are used)
    var alarmTime: Date
    
    /// Whether to wake up 5 minutes before sunrise (alarm time recalculates daily)
    var wakeUpWithSun: Bool
    
    /// List of actions in this routine, executed in order
    var actions: [RoutineAction]
    
    /// Creates a new Routine
    init(
        id: UUID = UUID(),
        name: String = "New Routine",
        alarmEnabled: Bool = false,
        alarmTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
        wakeUpWithSun: Bool = false,
        actions: [RoutineAction] = []
    ) {
        self.id = id
        self.name = name
        self.alarmEnabled = alarmEnabled
        self.alarmTime = alarmTime
        self.wakeUpWithSun = wakeUpWithSun
        self.actions = actions
    }
    
    /// Formatted alarm time string (e.g., "7:00 AM")
    var formattedAlarmTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: alarmTime)
    }
    
    /// Total duration of all actions combined in seconds
    var totalDurationSeconds: Int {
        actions.reduce(0) { $0 + $1.durationSeconds }
    }
    
    /// Formatted total duration (e.g., "15 min")
    var formattedTotalDuration: String {
        let minutes = totalDurationSeconds / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
}
