import SwiftUI

/// View displaying list of all routines with add functionality
struct RoutinesListView: View {
    @EnvironmentObject var routineManager: RoutineManager
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var showingAddRoutine = false
    @State private var routineToEdit: Routine?
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.padding) {
                // Add Routine button at top
                addRoutineButton
                // Routines list
                if routineManager.routines.isEmpty {
                    emptyStateView
                } else {
                    routinesList
                }
                Spacer(minLength: 50)
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, AppTheme.padding)
        }
        .navigationTitle("Routines")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineView(routineToEdit: nil)
                .environmentObject(routineManager)
                .environmentObject(alarmManager)
                .environmentObject(locationManager)
        }
        .sheet(item: $routineToEdit) { routine in
            AddRoutineView(routineToEdit: routine)
                .environmentObject(routineManager)
                .environmentObject(alarmManager)
                .environmentObject(locationManager)
        }
    }
    
    // MARK: - Add Routine Button
    
    private var addRoutineButton: some View {
        Button {
            showingAddRoutine = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                
                Text("Add Routine")
                    .font(AppTheme.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(AppTheme.padding)
            .background(AppTheme.primaryColor)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
            .shadow(color: AppTheme.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.padding) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.borderColor.opacity(0.5))
            
            Text("No Routines Yet")
                .font(AppTheme.title)
                .foregroundColor(AppTheme.primaryText)
            
            Text("Tap the button above to create your first routine")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Routines List
    
    private var routinesList: some View {
        VStack(spacing: AppTheme.padding) {
            ForEach(Array(routineManager.routines.enumerated()), id: \ .element.id) { index, routine in
                routineCard(routine)
            }
            .onDelete { offsets in
                routineManager.deleteRoutines(at: offsets)
            }
        }
    }
    
    private func routineCard(_ routine: Routine) -> some View {
        Button {
            routineToEdit = routine
        } label: {
            HStack(spacing: AppTheme.padding) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(AppTheme.primaryColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if routineManager.selectedRoutineIds.contains(routine.id) {
                        Circle()
                            .fill(AppTheme.primaryColor)
                            .frame(width: 16, height: 16)
                    }
                }
                .onTapGesture {
                    routineManager.toggleRoutine(routine)
                    
                    // Update alarm scheduling
                    Task {
                        await alarmManager.updateAllAlarms(routines: routineManager.routines)
                    }
                }
                
                // Routine info
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.7)
                    
                    HStack(spacing: 12) {
                        Label("\(routine.actions.count) actions", systemImage: "checkmark.circle")
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        
                        Label(routine.formattedTotalDuration, systemImage: "clock")
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                // Delete button
                Button {
                    routineManager.deleteRoutine(routine)
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Alarm indicator
                if routine.alarmEnabled {
                    VStack(spacing: 2) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 14))
                        Text(routine.formattedAlarmTime)
                            .font(.system(size: 11))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(AppTheme.primaryColor)
                    .padding(6)
                    .background(AppTheme.elevatedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                    )
                    .cornerRadius(AppTheme.cornerRadiusSmall)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(AppTheme.padding)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                routineManager.selectRoutine(routine)
            } label: {
                Label("Select as Active", systemImage: "checkmark.circle")
            }
            
            Button {
                routineToEdit = routine
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                routineManager.deleteRoutine(routine)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    RoutinesListView()
        .environmentObject(RoutineManager())
        .environmentObject(AlarmManager())
}
