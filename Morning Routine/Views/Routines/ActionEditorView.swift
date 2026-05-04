import SwiftUI

/// View for adding or editing a single action within a routine
struct ActionEditorView: View {
        @State private var showingRedFilterInfo = false
    @Environment(\.dismiss) private var dismiss
    
    // If editing, pass existing action; otherwise nil
    let action: RoutineAction?
    
    // Callback when saving
    let onSave: (RoutineAction) -> Void
    
    // Form state - initialize from action if editing
    @State private var name: String
    @State private var durationMinutes: Int
    @State private var durationSeconds: Int
    @State private var useRedFilter: Bool
    @State private var isAlarmEnabled: Bool
    
    init(action: RoutineAction?, onSave: @escaping (RoutineAction) -> Void) {
        self.action = action
        self.onSave = onSave
        
        // Initialize state from action if editing, otherwise use defaults
        if let action = action {
            _name = State(initialValue: action.name)
            _durationMinutes = State(initialValue: action.durationSeconds / 60)
            _durationSeconds = State(initialValue: action.durationSeconds % 60)
            _useRedFilter = State(initialValue: action.useRedFilter)
            _isAlarmEnabled = State(initialValue: action.isAlarmEnabled)
        } else {
            _name = State(initialValue: "")
            _durationMinutes = State(initialValue: 1)
            _durationSeconds = State(initialValue: 0)
            _useRedFilter = State(initialValue: false)
            _isAlarmEnabled = State(initialValue: true)
        }
    }
    
    var isEditing: Bool {
        action != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                VStack {
                    ScrollView {
                        VStack(spacing: AppTheme.paddingLarge) {
                            // Action name
                            nameSection
                            // Duration picker
                            durationSection
                            // Alarm toggle
                            alarmSection
                            // Red filter toggle
                            redFilterSection
                            Spacer(minLength: 50)
                        }
                        .padding(AppTheme.padding)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle(isEditing ? "Edit Action" : "New Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAction()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    /// Helper to dismiss the keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Name Section
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Action Name")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            TextField("e.g., Brush Teeth, Meditate, Exercise", text: $name)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.primaryText)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                )
        }
    }
    
    // MARK: - Duration Section
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("How long will this action take?")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: AppTheme.padding) {
                // Duration display
                HStack {
                    Spacer()
                    
                    Text(formattedDuration)
                        .font(AppTheme.timerFont)
                        .foregroundColor(AppTheme.primaryColor)
                    
                    Spacer()
                }
                .padding(.vertical, AppTheme.padding)
                
                // Pickers
                HStack(spacing: 0) {
                    // Minutes picker
                    VStack(spacing: 4) {
                        Picker("Minutes", selection: $durationMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                        
                        Text("min")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Text(":")
                        .font(AppTheme.title)
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.bottom, 24)
                    
                    // Seconds picker
                    VStack(spacing: 4) {
                        Picker("Seconds", selection: $durationSeconds) {
                            ForEach(0..<60) { second in
                                Text(String(format: "%02d", second)).tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                        
                        Text("sec")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                // Quick duration buttons
                HStack(spacing: AppTheme.paddingSmall) {
                    quickDurationButton(minutes: 1, label: "1 min")
                    quickDurationButton(minutes: 2, label: "2 min")
                    quickDurationButton(minutes: 5, label: "5 min")
                    quickDurationButton(minutes: 10, label: "10 min")
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
        }
    }
    
    private var formattedDuration: String {
        return String(format: "%d:%02d", durationMinutes, durationSeconds)
    }
    
    private func quickDurationButton(minutes: Int, label: String) -> some View {
        Button {
            durationMinutes = minutes
            durationSeconds = 0
        } label: {
            Text(label)
                .font(AppTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(durationMinutes == minutes && durationSeconds == 0 ? .white : AppTheme.primaryColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(durationMinutes == minutes && durationSeconds == 0 ? AppTheme.primaryColor : AppTheme.elevatedBackground)
                .cornerRadius(AppTheme.cornerRadiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                )
        }
    }
    
    // MARK: - Alarm Section
    
    private var alarmSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            Text("Alarm Notification")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 0) {
                Toggle(isOn: $isAlarmEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isAlarmEnabled ? AppTheme.primaryColor : AppTheme.secondaryText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isAlarmEnabled ? "Alarm Enabled" : "Alarm Disabled")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                            Text(isAlarmEnabled ? "Notification will fire when this action starts" : "This action won't trigger a notification")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                .tint(AppTheme.primaryColor)
                .padding()
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
            .animation(.easeInOut(duration: 0.25), value: isAlarmEnabled)
        }
    }
    
    // MARK: - Red Filter Section
    
    private var redFilterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            HStack(spacing: 8) {
                Button {
                    showingRedFilterInfo = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
                Text("Display Options")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
            }
            VStack(spacing: 0) {
                Toggle(isOn: $useRedFilter) {
                    HStack(spacing: 12) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Red Filter During Action")
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.primaryText)
                            Text("Shows a red overlay to reduce blue light")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                .tint(AppTheme.primaryColor)
                .padding()
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
            )
            .animation(.easeInOut(duration: 0.25), value: useRedFilter)
        }
        .sheet(isPresented: $showingRedFilterInfo) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Why Avoid Blue Light in the Morning?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Getting blue-light exposure before natural sunlight in the morning can confuse your body’s internal clock. Your brain uses the first strong light signal of the day to decide when “morning” starts. If that first signal comes from a phone, tablet, or other artificial blue light instead of the sun, your circadian rhythm can shift in an unnatural way. Artificial blue light is weaker and more concentrated compared to sunlight, so your brain may treat it as a “fake morning,” which can reduce the strength of your real morning signal once you actually go outside. This can make your body slower to fully wake up, reduce the natural morning energy boost sunlight gives, and make your sleep schedule drift later over time. Morning sunlight has a balanced spectrum and is much brighter, giving your brain the proper cue to set your daily rhythm. When blue-light devices come first, they can blunt that natural effect and make it harder for your body to stay on a consistent schedule.")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryText)
                        Text("This redlight filter will prevent blue light from reaching your eyes.")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.primaryColor)
                    }
                    .padding(.bottom, 16)
                }
                Spacer()
                Button("Close") {
                    showingRedFilterInfo = false
                }
                .primaryButtonStyle()
            }
            .padding(AppTheme.paddingLarge)
        }
    }
    
    // MARK: - Load / Save
    
    private func loadExistingAction() {
        guard let action = action else {
            // Reset to defaults if no action (new action)
            name = ""
            durationMinutes = 1
            durationSeconds = 0
            useRedFilter = false
            return
        }
        
        // Load existing action data
        name = action.name
        durationMinutes = action.durationSeconds / 60
        durationSeconds = action.durationSeconds % 60
        useRedFilter = action.useRedFilter
        isAlarmEnabled = action.isAlarmEnabled
    }
    
    private func saveAction() {
        let totalSeconds = (durationMinutes * 60) + durationSeconds
        
        let newAction = RoutineAction(
            id: action?.id ?? UUID(),
            name: name,
            durationSeconds: max(1, totalSeconds), // At least 1 second
            useRedFilter: useRedFilter,
            isAlarmEnabled: isAlarmEnabled
        )
        
        onSave(newAction)
        dismiss()
    }
}

#Preview {
    ActionEditorView(action: nil) { _ in }
}
