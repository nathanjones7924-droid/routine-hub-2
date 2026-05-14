import Foundation
import SwiftUI
import Combine
import FirebaseAnalytics

/// Manages all routines - CRUD operations, persistence, and selection
@MainActor
class RoutineManager: ObservableObject {
    // MARK: - Published Properties
    
    /// All saved routines
    @Published var routines: [Routine] = []
    
    /// The currently selected routines (used for alarm and quick start)
    @Published var selectedRoutineIds: Set<UUID> = []
    
    /// Whether a routine is currently being executed
    @Published var isExecutingRoutine: Bool = false
    
    /// The routine currently being executed
    @Published var executingRoutine: Routine?
    
    // MARK: - Private Properties
    
    private let routinesKey = "savedRoutines"
    private let selectedRoutinesKey = "selectedRoutineIds"
    
    /// Reference to location manager for sunrise updates
    weak var locationManager: LocationManager?
    
    /// Reference to settings manager for sunrise preferences
    weak var settingsManager: SettingsManager?
    
    // MARK: - Computed Properties
    
    /// The currently selected routines as an array
    var selectedRoutines: [Routine] {
        routines.filter { selectedRoutineIds.contains($0.id) }
    }
    
    /// The first selected routine (for backward compatibility with single routine UI)
    var selectedRoutine: Routine? {
        selectedRoutines.first
    }
    
    /// Keeps old API for compatibility
    var selectedRoutineId: UUID? {
        selectedRoutineIds.first
    }
    
    // MARK: - Initialization
    
    init() {
        loadRoutines()
        loadSelectedRoutines()
    }
    
    // MARK: - Sunrise Updates
    
    /// Update alarm times for all routines that have "wake up with sun" enabled
    /// This should be called when sunrise time changes (e.g., new day, location change)
    func updateSunriseAlarmTimes(sunriseTime: Date) {
        updateSunEventAlarmTimes(sunriseTime: sunriseTime, sunsetTime: locationManager?.sunsetTime)
    }

    /// Update alarm times for all routines that have sunrise/sunset-based alarms enabled
    func updateSunEventAlarmTimes(sunriseTime: Date?, sunsetTime: Date?) {
        let calendar = Calendar.current
        var hasChanges = false
        
        // Get offsets from settings
        let minutesBeforeSunrise = settingsManager?.minutesBeforeSunrise ?? -3
        let minutesFromSunset = settingsManager?.minutesFromSunset ?? -3
        
        for index in routines.indices {
            if routines[index].wakeUpWithSun && routines[index].alarmEnabled, let sunriseTime {
                // Sunrise-based alarm time
                if let newAlarmTime = calendar.date(byAdding: .minute, value: minutesBeforeSunrise, to: sunriseTime) {
                    let oldTime = routines[index].alarmTime
                    let oldHour = calendar.component(.hour, from: oldTime)
                    let oldMinute = calendar.component(.minute, from: oldTime)
                    let newHour = calendar.component(.hour, from: newAlarmTime)
                    let newMinute = calendar.component(.minute, from: newAlarmTime)
                    
                    // Only update if the time actually changed
                    if oldHour != newHour || oldMinute != newMinute {
                        routines[index].alarmTime = newAlarmTime
                        hasChanges = true
                        
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        print("[RoutineManager] 🌅 Updated alarm time for '\(routines[index].name)': \(formatter.string(from: oldTime)) → \(formatter.string(from: newAlarmTime))")
                        
                        // Log analytics event
                        Analytics.logEvent("sunrise_alarm_updated", parameters: [
                            "routine_id": routines[index].id.uuidString,
                            "routine_name": routines[index].name,
                            "new_alarm_hour": newHour,
                            "new_alarm_minute": newMinute
                        ])
                    }
                }
            } else if routines[index].goToBedWithSun && routines[index].alarmEnabled, let sunsetTime {
                // Sunset-based alarm time
                if let newAlarmTime = calendar.date(byAdding: .minute, value: minutesFromSunset, to: sunsetTime) {
                    let oldTime = routines[index].alarmTime
                    let oldHour = calendar.component(.hour, from: oldTime)
                    let oldMinute = calendar.component(.minute, from: oldTime)
                    let newHour = calendar.component(.hour, from: newAlarmTime)
                    let newMinute = calendar.component(.minute, from: newAlarmTime)

                    if oldHour != newHour || oldMinute != newMinute {
                        routines[index].alarmTime = newAlarmTime
                        hasChanges = true

                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        print("[RoutineManager] 🌇 Updated alarm time for '\(routines[index].name)': \(formatter.string(from: oldTime)) → \(formatter.string(from: newAlarmTime))")
                    }
                }
            }
        }
        
        // Save if any changes were made
        if hasChanges {
            saveRoutines()
            print("[RoutineManager] 🌅 Sunrise-based alarm times saved")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new routine
    func addRoutine(_ routine: Routine) {
        routines.append(routine)
		
        // Auto-select newly created routine
        selectRoutine(routine)
        
        saveRoutines()
        
        // Log analytics event
        Analytics.logEvent("routine_created", parameters: [
            "routine_id": routine.id.uuidString,
            "routine_name": routine.name,
            "alarm_enabled": routine.alarmEnabled,
            "action_count": routine.actions.count,
            "total_duration_seconds": routine.totalDurationSeconds
        ])
    }
    
    /// Update an existing routine
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
            saveRoutines()
            
            // Log analytics event
            Analytics.logEvent("routine_updated", parameters: [
                "routine_id": routine.id.uuidString,
                "routine_name": routine.name,
                "alarm_enabled": routine.alarmEnabled,
                "action_count": routine.actions.count,
                "total_duration_seconds": routine.totalDurationSeconds
            ])
        }
    }
    
    /// Delete a routine
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        
        // Remove from selected routines if it was selected
        deselectRoutine(routine)
        
        saveRoutines()
        
        // Log analytics event
        Analytics.logEvent("routine_deleted", parameters: [
            "routine_id": routine.id.uuidString,
            "routine_name": routine.name
        ])
    }
    
    /// Delete routines at offsets (for List onDelete)
    func deleteRoutines(at offsets: IndexSet) {
        let routinesToDelete = offsets.map { routines[$0] }
        routines.remove(atOffsets: offsets)
        
        // Remove deleted routines from selected set
        for routine in routinesToDelete {
            selectedRoutineIds.remove(routine.id)
        }
        
        saveRoutines()
        saveSelectedRoutines()
    }
    
    /// Select a routine
    func selectRoutine(_ routine: Routine) {
        selectedRoutineIds.insert(routine.id)
        saveSelectedRoutines()
    }
    
    /// Deselect a routine
    func deselectRoutine(_ routine: Routine) {
        selectedRoutineIds.remove(routine.id)
        saveSelectedRoutines()
    }
    
    /// Toggle routine selection (select if not selected, deselect if selected)
    func toggleRoutine(_ routine: Routine) {
        if selectedRoutineIds.contains(routine.id) {
            deselectRoutine(routine)
        } else {
            selectRoutine(routine)
        }
    }
    
    /// Start executing a routine
    func startRoutine(_ routine: Routine) {
        executingRoutine = routine
        isExecutingRoutine = true
        
        // Log analytics event
        Analytics.logEvent("routine_started", parameters: [
            "routine_id": routine.id.uuidString,
            "routine_name": routine.name,
            "action_count": routine.actions.count,
            "total_duration_seconds": routine.totalDurationSeconds
        ])
    }
    
    /// Stop executing the current routine
    func stopRoutine() {
        executingRoutine = nil
        isExecutingRoutine = false
    }
    
    // MARK: - Persistence
    
    /// Save routines to UserDefaults
    private func saveRoutines() {
        do {
            let data = try JSONEncoder().encode(routines)
            UserDefaults.standard.set(data, forKey: routinesKey)
        } catch {
            print("Error saving routines: \(error)")
        }
    }
    
    /// Load routines from UserDefaults
    private func loadRoutines() {
        guard let data = UserDefaults.standard.data(forKey: routinesKey) else { return }
        
        do {
            routines = try JSONDecoder().decode([Routine].self, from: data)
        } catch {
            print("Error loading routines: \(error)")
        }
    }
    
    /// Save selected routine IDs to UserDefaults
    private func saveSelectedRoutines() {
        let idStrings = selectedRoutineIds.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: selectedRoutinesKey)
    }
    
    /// Load selected routine IDs from UserDefaults
    private func loadSelectedRoutines() {
        guard let idStrings = UserDefaults.standard.array(forKey: selectedRoutinesKey) as? [String] else { return }
        
        for idString in idStrings {
            if let id = UUID(uuidString: idString), routines.contains(where: { $0.id == id }) {
                selectedRoutineIds.insert(id)
            }
        }
    }
}
