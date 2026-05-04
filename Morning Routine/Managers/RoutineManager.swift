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
    
    /// The currently selected routine (used for alarm and quick start)
    @Published var selectedRoutineId: UUID?
    
    /// Whether a routine is currently being executed
    @Published var isExecutingRoutine: Bool = false
    
    /// The routine currently being executed
    @Published var executingRoutine: Routine?
    
    // MARK: - Private Properties
    
    private let routinesKey = "savedRoutines"
    private let selectedRoutineKey = "selectedRoutineId"
    
    // MARK: - Computed Properties
    
    /// The currently selected routine object
    var selectedRoutine: Routine? {
        guard let id = selectedRoutineId else { return nil }
        return routines.first { $0.id == id }
    }
    
    // MARK: - Initialization
    
    init() {
        loadRoutines()
        loadSelectedRoutine()
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new routine
    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        
        // Auto-select if it's the first routine
        if routines.count == 1 {
            selectedRoutineId = routine.id
            saveSelectedRoutine()
        }
        
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
        
        // If we deleted the selected routine, select another one
        if selectedRoutineId == routine.id {
            selectedRoutineId = routines.first?.id
            saveSelectedRoutine()
        }
        
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
        
        // Check if selected routine was deleted
        for routine in routinesToDelete {
            if selectedRoutineId == routine.id {
                selectedRoutineId = routines.first?.id
                saveSelectedRoutine()
                break
            }
        }
        
        saveRoutines()
    }
    
    /// Select a routine
    func selectRoutine(_ routine: Routine) {
        selectedRoutineId = routine.id
        saveSelectedRoutine()
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
    
    /// Save selected routine ID to UserDefaults
    private func saveSelectedRoutine() {
        if let id = selectedRoutineId {
            UserDefaults.standard.set(id.uuidString, forKey: selectedRoutineKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedRoutineKey)
        }
    }
    
    /// Load selected routine ID from UserDefaults
    private func loadSelectedRoutine() {
        guard let idString = UserDefaults.standard.string(forKey: selectedRoutineKey),
              let id = UUID(uuidString: idString) else { return }
        
        // Only set if the routine still exists
        if routines.contains(where: { $0.id == id }) {
            selectedRoutineId = id
        } else {
            selectedRoutineId = routines.first?.id
        }
    }
}
