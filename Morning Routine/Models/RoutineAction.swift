import Foundation

/// Represents a single action within a morning routine
struct RoutineAction: Identifiable, Codable, Equatable {
    /// Unique identifier for the action
    var id: UUID
    
    /// Name/title of the action (e.g., "Brush Teeth", "Meditate")
    var name: String
    
    /// Duration of the action in seconds
    var durationSeconds: Int
    
    /// Whether to show a red filter overlay during this action
    var useRedFilter: Bool
    
    /// Whether the alarm notification should fire for this action
    var isAlarmEnabled: Bool
    
    /// Creates a new RoutineAction
    init(id: UUID = UUID(), name: String = "", durationSeconds: Int = 60, useRedFilter: Bool = false, isAlarmEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.useRedFilter = useRedFilter
        self.isAlarmEnabled = isAlarmEnabled
    }
    
    /// Formatted duration string (e.g., "5:00")
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
