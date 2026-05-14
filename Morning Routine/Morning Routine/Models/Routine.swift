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

    /// Whether to go to bed with the sun (alarm time recalculates daily from sunset)
    var goToBedWithSun: Bool
    
    /// Whether to show calendar events before starting the routine
    var showCalendarEvents: Bool
    
    /// Days of the week the alarm should go off (1=Sunday, 2=Monday, ... 7=Saturday)
    /// Empty set means every day
    var selectedDays: Set<Int>
    
    /// List of actions in this routine, executed in order
    var actions: [RoutineAction]
    
    /// Creates a new Routine
    init(
        id: UUID = UUID(),
        name: String = "New Routine",
        alarmEnabled: Bool = false,
        alarmTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
        wakeUpWithSun: Bool = false,
        goToBedWithSun: Bool = false,
        showCalendarEvents: Bool = false,
        selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7],
        actions: [RoutineAction] = []
    ) {
        self.id = id
        self.name = name
        self.alarmEnabled = alarmEnabled
        self.alarmTime = alarmTime
        self.wakeUpWithSun = wakeUpWithSun
        self.goToBedWithSun = goToBedWithSun
        self.showCalendarEvents = showCalendarEvents
        self.selectedDays = selectedDays
        self.actions = actions
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case alarmEnabled
        case alarmTime
        case wakeUpWithSun
        case goToBedWithSun
        case showCalendarEvents
        case selectedDays
        case actions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        alarmEnabled = try container.decode(Bool.self, forKey: .alarmEnabled)
        alarmTime = try container.decode(Date.self, forKey: .alarmTime)
        wakeUpWithSun = try container.decodeIfPresent(Bool.self, forKey: .wakeUpWithSun) ?? false
        goToBedWithSun = try container.decodeIfPresent(Bool.self, forKey: .goToBedWithSun) ?? false
        showCalendarEvents = try container.decodeIfPresent(Bool.self, forKey: .showCalendarEvents) ?? false
        selectedDays = try container.decodeIfPresent(Set<Int>.self, forKey: .selectedDays) ?? [1, 2, 3, 4, 5, 6, 7]
        actions = try container.decodeIfPresent([RoutineAction].self, forKey: .actions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(alarmEnabled, forKey: .alarmEnabled)
        try container.encode(alarmTime, forKey: .alarmTime)
        try container.encode(wakeUpWithSun, forKey: .wakeUpWithSun)
        try container.encode(goToBedWithSun, forKey: .goToBedWithSun)
        try container.encode(showCalendarEvents, forKey: .showCalendarEvents)
        try container.encode(selectedDays, forKey: .selectedDays)
        try container.encode(actions, forKey: .actions)
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
