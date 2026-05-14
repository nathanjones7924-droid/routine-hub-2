import SwiftUI
import EventKit
import UserNotifications

/// View for creating or editing a Routine
struct AddRoutineView: View {
	let routineToEdit: Routine?

	@EnvironmentObject var routineManager: RoutineManager
	@EnvironmentObject var alarmManager: AlarmManager
	@EnvironmentObject var locationManager: LocationManager
	@EnvironmentObject var settingsManager: SettingsManager
	@Environment(\.dismiss) private var dismiss

	@State private var name: String
	@State private var alarmEnabled: Bool
	@State private var alarmTime: Date
	@State private var wakeUpWithSun: Bool
	@State private var goToBedWithSun: Bool
	@State private var showCalendarEvents: Bool
	@State private var selectedDays: Set<Int>
	@State private var actions: [RoutineAction]

	@State private var showingAddAction = false
	@State private var editingAction: RoutineAction? = nil
	@State private var showingSunriseHelp = false
	@State private var showingSunsetHelp = false
	@State private var showingNotificationSettingsAlert = false
	@State private var showingLocationSettingsAlert = false
	@State private var draggingActionId: UUID? = nil
	@State private var dragOffset: CGFloat = 0
	@State private var actionFrames: [UUID: CGRect] = [:]

	private var sunriseOffsetText: String {
		let minutes = settingsManager.minutesBeforeSunrise
		let absMinutes = abs(minutes)
		let minuteLabel = absMinutes == 1 ? "minute" : "minutes"
		if minutes < 0 {
			return "The alarm is set for \(absMinutes) \(minuteLabel) before sunrise"
		} else if minutes > 0 {
			return "The alarm is set for \(absMinutes) \(minuteLabel) after sunrise"
		} else {
			return "The alarm is set for sunrise time"
		}
	}

	private var sunsetOffsetText: String {
		let minutes = settingsManager.minutesFromSunset
		let absMinutes = abs(minutes)
		let minuteLabel = absMinutes == 1 ? "minute" : "minutes"
		if minutes < 0 {
			return "The alarm is set for \(absMinutes) \(minuteLabel) before sunset"
		} else if minutes > 0 {
			return "The alarm is set for \(absMinutes) \(minuteLabel) after sunset"
		} else {
			return "The alarm is set for sunset time"
		}
	}
	
	/// Short description for the alarm time display
	private var sunriseOffsetDescription: String {
		let minutes = settingsManager.minutesBeforeSunrise
		let absMinutes = abs(minutes)
		if minutes < 0 {
			return "\(absMinutes) min before sunrise"
		} else if minutes > 0 {
			return "\(absMinutes) min after sunrise"
		} else {
			return "at sunrise"
		}
	}

	/// Short description for the sunset alarm time display
	private var sunsetOffsetDescription: String {
		let minutes = settingsManager.minutesFromSunset
		let absMinutes = abs(minutes)
		if minutes < 0 {
			return "\(absMinutes) min before sunset"
		} else if minutes > 0 {
			return "\(absMinutes) min after sunset"
		} else {
			return "at sunset"
		}
	}
	
	/// Day labels for the day selector (Sunday = 1, Saturday = 7)
	private var dayLabels: [(weekday: Int, label: String)] {
		[
			(1, "S"),  // Sunday
			(2, "M"),  // Monday
			(3, "T"),  // Tuesday
			(4, "W"),  // Wednesday
			(5, "T"),  // Thursday
			(6, "F"),  // Friday
			(7, "S")   // Saturday
		]
	}
	
	/// Description of selected days
	private var selectedDaysDescription: String {
		let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
		let sortedDays = selectedDays.sorted()
		let names = sortedDays.map { dayNames[$0 - 1] }
		return names.joined(separator: ", ")
	}

	init(routineToEdit: Routine?) {
		self.routineToEdit = routineToEdit

		if let routine = routineToEdit {
			_name = State(initialValue: routine.name)
			_alarmEnabled = State(initialValue: routine.alarmEnabled)
			_alarmTime = State(initialValue: routine.alarmTime)
			_wakeUpWithSun = State(initialValue: routine.wakeUpWithSun)
			_goToBedWithSun = State(initialValue: routine.goToBedWithSun)
			_showCalendarEvents = State(initialValue: routine.showCalendarEvents)
			_selectedDays = State(initialValue: routine.selectedDays)
			_actions = State(initialValue: routine.actions)
		} else {
			_name = State(initialValue: "New Routine")
			_alarmEnabled = State(initialValue: false)
			_alarmTime = State(initialValue: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date())
			_wakeUpWithSun = State(initialValue: false)
			_goToBedWithSun = State(initialValue: false)
			_showCalendarEvents = State(initialValue: false)
			_selectedDays = State(initialValue: [1, 2, 3, 4, 5, 6, 7])
			_actions = State(initialValue: [])
		}
	}

	var body: some View {
		NavigationStack {
			ZStack {
				AppTheme.backgroundGradient.ignoresSafeArea()

				ScrollView(.vertical, showsIndicators: true) {
					VStack(spacing: AppTheme.padding) {
						routineNameSection
						alarmSettingsSection
						calendarEventsSection
						actionsSection
						Spacer(minLength: 40)
					}
					.padding(AppTheme.padding)
					.iPadConstrained()
				}
				.frame(maxWidth: .infinity)
				.dismissKeyboardOnTap()
			}
			.navigationTitle(routineToEdit == nil ? "New Routine" : "Edit Routine")
			.navigationBarTitleDisplayMode(.inline)
			.tint(AppTheme.navigationBarAccentColor)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") { saveRoutine() }
						.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || actions.isEmpty)
				}
			}
			.onChange(of: locationManager.sunriseTime) { oldValue, newSunrise in
				guard wakeUpWithSun, let sunrise = newSunrise else { return }
				let offsetMinutes = settingsManager.minutesBeforeSunrise
				let adjustedTime = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: sunrise) ?? sunrise
				alarmTime = adjustedTime
				alarmEnabled = true
				let formatter = DateFormatter()
				formatter.timeStyle = .short
				formatter.dateStyle = .none
				print("[AddRoutineView] Sunrise: \(formatter.string(from: sunrise)), Alarm set to: \(formatter.string(from: adjustedTime)) (offset: \(offsetMinutes) min)")
			}
			.onChange(of: locationManager.sunsetTime) { _, newSunset in
				guard goToBedWithSun, let sunset = newSunset else { return }
				let offsetMinutes = settingsManager.minutesFromSunset
				let adjustedTime = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: sunset) ?? sunset
				alarmTime = adjustedTime
				alarmEnabled = true
				let formatter = DateFormatter()
				formatter.timeStyle = .short
				formatter.dateStyle = .none
				print("[AddRoutineView] Sunset: \(formatter.string(from: sunset)), Alarm set to: \(formatter.string(from: adjustedTime)) (offset: \(offsetMinutes) min)")
			}
			.onChange(of: locationManager.authorizationStatus) { oldValue, newStatus in
				// Handle location permission changes when a sun-based alarm is enabled
				if wakeUpWithSun || goToBedWithSun {
					switch newStatus {
					case .denied, .restricted:
						showingLocationSettingsAlert = true
						wakeUpWithSun = false
						goToBedWithSun = false
					case .authorizedWhenInUse, .authorizedAlways:
						// Permission granted, get location
						locationManager.getCurrentLocation()
					default:
						break
					}
				}
			}
			.sheet(isPresented: $showingAddAction) {
				ActionEditorView(action: nil) { saved in
					actions.append(saved)
					showingAddAction = false
				}
			}
			.sheet(item: $editingAction) { actionToEdit in
				ActionEditorView(action: actionToEdit) { saved in
					if let index = actions.firstIndex(where: { $0.id == actionToEdit.id }) {
						actions[index] = saved
					}
					editingAction = nil
				}
			}
			.alert("Notifications Disabled", isPresented: $showingNotificationSettingsAlert) {
				Button("Open Settings") {
					if let url = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(url)
					}
				}
				Button("Cancel", role: .cancel) { }
			} message: {
				Text("To use alarms, please enable notifications in Settings.")
			}
			.alert("Location Access Required", isPresented: $showingLocationSettingsAlert) {
				Button("Open Settings") {
					if let url = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(url)
					}
				}
				Button("Cancel", role: .cancel) { }
			} message: {
				Text("To use sun-based alarms, Routine Hub needs location access to calculate sunrise and sunset times. Please enable location access in Settings.")
			}
			.sheet(isPresented: $showingSunriseHelp) {
				sunriseHelpSheet
			}
			.sheet(isPresented: $showingSunsetHelp) {
				sunsetHelpSheet
			}
		}
	}
	
	// MARK: - Extracted View Sections
	
	private var routineNameSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Routine Name")
				.font(AppTheme.headline)
				.foregroundColor(AppTheme.primaryText)

			TextField("My Routine", text: $name, axis: .vertical)
				.lineLimit(1...6)
				.font(AppTheme.body)
				.foregroundColor(AppTheme.controlTextColor)
				.tint(AppTheme.controlAccentColor)
				.padding()
				.background(AppTheme.cardBackground)
				.cornerRadius(AppTheme.cornerRadius)
				.overlay(
					RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
						.stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
				)
				.onSubmit {
					UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
				}
		}
		.frame(maxWidth: .infinity)
	}
	
	private var alarmSettingsSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Alarm")
				.font(AppTheme.headline)
				.foregroundColor(AppTheme.primaryText)

			Toggle(isOn: $alarmEnabled) {
				Text(alarmEnabled ? "On" : "Off")
					.foregroundColor(AppTheme.controlTextColor)
			}
			.toggleStyle(AppThemeToggleStyle())
			.onChange(of: alarmEnabled) { _, newValue in
				if newValue {
					checkNotificationPermission()
				} else {
					// Turn off sun-based options when alarm is disabled
					wakeUpWithSun = false
					goToBedWithSun = false
				}
			}

			if alarmEnabled && !wakeUpWithSun && !goToBedWithSun {
				alarmTimePicker
			} else if alarmEnabled && wakeUpWithSun {
				Text("Alarm: \(formattedAlarmTime) (\(sunriseOffsetDescription))")
					.font(AppTheme.body)
					.foregroundColor(AppTheme.primaryText)
					.lineLimit(2)
					.multilineTextAlignment(.leading)
					.minimumScaleFactor(0.7)
					.padding()
					.frame(maxWidth: .infinity, alignment: .center)
			} else if alarmEnabled && goToBedWithSun {
				Text("Alarm: \(formattedAlarmTime) (\(sunsetOffsetDescription))")
					.font(AppTheme.body)
					.foregroundColor(AppTheme.primaryText)
					.lineLimit(2)
					.multilineTextAlignment(.leading)
					.minimumScaleFactor(0.7)
					.padding()
					.frame(maxWidth: .infinity, alignment: .center)
			}

			wakeUpWithSunToggle
			goToBedWithSunToggle
			
			if alarmEnabled {
				daySelectorSection
			}
		}
	}
	
	private var alarmTimePicker: some View {
		DatePicker("Alarm Time", selection: $alarmTime, displayedComponents: .hourAndMinute)
			.datePickerStyle(.wheel)
			.labelsHidden()
			.tint(AppTheme.controlAccentColor)
			.colorMultiply(AppTheme.controlTextColor)
			.environment(\.colorScheme, AppTheme.controlColorScheme)
			.frame(maxWidth: .infinity, maxHeight: 150)
			.clipped()
			.padding()
			.background(AppTheme.cardBackground)
			.cornerRadius(AppTheme.cornerRadius)
			.overlay(
				RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
					.stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
			)
	}
	
	private var wakeUpWithSunToggle: some View {
		HStack(spacing: 0) {
			Text("Wake up with the sun")
				.foregroundColor(AppTheme.controlTextColor)
			
			Button(action: { showingSunriseHelp = true }) {
				Image(systemName: "questionmark.circle")
					.foregroundColor(AppTheme.primaryColor)
					.font(.system(size: 16))
			}
			.buttonStyle(.plain)
			.padding(.leading, 3)
			
			Spacer()
			
			Toggle("", isOn: $wakeUpWithSun)
				.toggleStyle(AppThemeToggleStyle())
				.labelsHidden()
		}
		.onChange(of: wakeUpWithSun) { oldValue, newValue in
			if newValue {
				goToBedWithSun = false
				enforceNotificationPermissionForWakeUpWithSun()
			}
			// When turning OFF wake up with sun, alarm stays on (no change needed)
		}
	}

	private var goToBedWithSunToggle: some View {
		HStack(spacing: 0) {
			Text("Look at the sunset")
				.foregroundColor(AppTheme.controlTextColor)

			Button(action: { showingSunsetHelp = true }) {
				Image(systemName: "questionmark.circle")
					.foregroundColor(AppTheme.primaryColor)
					.font(.system(size: 16))
			}
			.buttonStyle(.plain)
			.padding(.leading, 3)
			
			Spacer()
			
			Toggle("", isOn: $goToBedWithSun)
				.toggleStyle(AppThemeToggleStyle())
				.labelsHidden()
		}
		.onChange(of: goToBedWithSun) { _, newValue in
			if newValue {
				wakeUpWithSun = false
				enforceNotificationPermissionForGoToBedWithSun()
			}
		}
	}
	
	private var daySelectorSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Repeat")
				.font(AppTheme.caption)
				.foregroundColor(AppTheme.secondaryText)
			
			HStack(spacing: 8) {
				ForEach(dayLabels, id: \.weekday) { day in
					dayButton(for: day)
				}
			}
			.frame(maxWidth: .infinity)
			
			if selectedDays.isEmpty {
				Text("No days selected - alarm won't repeat")
					.font(AppTheme.caption)
					.foregroundColor(.orange)
			} else if selectedDays.count == 7 {
				Text("Every day")
					.font(AppTheme.caption)
					.foregroundColor(AppTheme.secondaryText)
			} else {
				Text(selectedDaysDescription)
					.font(AppTheme.caption)
					.foregroundColor(AppTheme.secondaryText)
			}
		}
		.padding(.top, 8)
	}
	
	private func dayButton(for day: (weekday: Int, label: String)) -> some View {
		Button(action: {
			if selectedDays.contains(day.weekday) {
				selectedDays.remove(day.weekday)
			} else {
				selectedDays.insert(day.weekday)
			}
		}) {
			Text(day.label)
				.font(.system(size: 14, weight: .medium))
				.frame(width: 36, height: 36)
				.background(
					Circle()
						.fill(selectedDays.contains(day.weekday) ? AppTheme.primaryColor : AppTheme.cardBackground)
				)
				.overlay(
					Circle()
						.stroke(selectedDays.contains(day.weekday) ? AppTheme.primaryColor : AppTheme.borderColor, lineWidth: 1)
				)
				.foregroundColor(selectedDays.contains(day.weekday) ? .white : AppTheme.primaryText)
		}
		.buttonStyle(.plain)
	}
	
	private var calendarEventsSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Calendar")
				.font(AppTheme.headline)
				.foregroundColor(AppTheme.primaryText)
			
			HStack(spacing: 0) {
				Text("Show today's events before starting")
					.foregroundColor(AppTheme.controlTextColor)
				
				Spacer()
				
				Toggle("", isOn: $showCalendarEvents)
					.toggleStyle(AppThemeToggleStyle())
					.labelsHidden()
			}
			.onChange(of: showCalendarEvents) { _, newValue in
				if newValue {
					requestCalendarPermission()
				}
			}
			
			if showCalendarEvents {
				Text("Your calendar events for today will be displayed before starting the routine actions.")
					.font(AppTheme.caption)
					.foregroundColor(AppTheme.secondaryText)
			}
		}
	}
	
	private var actionsSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Text("Actions")
					.font(AppTheme.headline)
					.foregroundColor(AppTheme.primaryText)

				Spacer()

				Button(action: {
					showingAddAction = true
				}) {
					Image(systemName: "plus")
						.padding(8)
						.background(AppTheme.primaryColor)
						.foregroundColor(.white)
						.cornerRadius(8)
				}
			}

			if actions.isEmpty {
				emptyActionsPlaceholder
			} else {
				actionsList
			}
		}
	}
	
	private var emptyActionsPlaceholder: some View {
		Text("No actions yet — add one to start building your routine")
			.font(AppTheme.caption)
			.foregroundColor(AppTheme.secondaryText)
			.padding(.vertical, 20)
			.frame(maxWidth: .infinity)
			.background(AppTheme.cardBackground)
			.cornerRadius(AppTheme.cornerRadius)
			.overlay(
				RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
					.stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
			)
	}
	
	private var actionsList: some View {
		VStack(spacing: AppTheme.paddingSmall) {
			ForEach(actions) { act in
				let isDragging = draggingActionId == act.id
				
				actionRow(for: act)
					.background(
						GeometryReader { geo in
							Color.clear
								.preference(key: ActionFrameKey.self, value: [act.id: geo.frame(in: .named("actionsList"))])
						}
					)
					.offset(y: isDragging ? dragOffset : 0)
					.zIndex(isDragging ? 1 : 0)
					.shadow(color: isDragging ? Color.black.opacity(0.15) : .clear, radius: isDragging ? 6 : 0)
					.gesture(
						LongPressGesture(minimumDuration: 0.2)
							.sequenced(before: DragGesture())
							.onChanged { value in
								switch value {
								case .second(true, let drag):
									if draggingActionId == nil {
										draggingActionId = act.id
										let generator = UIImpactFeedbackGenerator(style: .medium)
										generator.impactOccurred()
									}
									if let drag = drag {
										dragOffset = drag.translation.height
										checkForReorder(draggedId: act.id)
									}
								default:
									break
								}
							}
							.onEnded { _ in
								withAnimation(.easeInOut(duration: 0.15)) {
									dragOffset = 0
									draggingActionId = nil
								}
							}
					)
			}
		}
		.coordinateSpace(name: "actionsList")
		.onPreferenceChange(ActionFrameKey.self) { frames in
			actionFrames = frames
		}
	}
	
	private func actionRow(for act: RoutineAction) -> some View {
		actionRowContent(for: act)
			.overlay(
				RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
					.stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
			)
	}

	private func checkForReorder(draggedId: UUID) {
		guard let fromIndex = actions.firstIndex(where: { $0.id == draggedId }),
			  let draggedFrame = actionFrames[draggedId] else { return }
		
		let draggedCenter = draggedFrame.midY + dragOffset
		
		for (index, action) in actions.enumerated() {
			if action.id == draggedId { continue }
			guard let frame = actionFrames[action.id] else { continue }
			
			if fromIndex < index && draggedCenter > frame.midY {
				withAnimation(.easeInOut(duration: 0.15)) {
					actions.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: index + 1)
				}
				let distance = frame.midY - draggedFrame.midY
				dragOffset -= distance
				return
			} else if fromIndex > index && draggedCenter < frame.midY {
				withAnimation(.easeInOut(duration: 0.15)) {
					actions.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: index)
				}
				let distance = frame.midY - draggedFrame.midY
				dragOffset -= distance
				return
			}
		}
	}

	private func actionRowContent(for act: RoutineAction) -> some View {
		HStack {
			Image(systemName: "line.3.horizontal")
				.foregroundColor(AppTheme.secondaryText)
				.font(.system(size: 14))
				.padding(.trailing, 8)
			
			VStack(alignment: .leading) {
				Text(act.name)
					.font(AppTheme.body)
					.foregroundColor(AppTheme.primaryText)
					.lineLimit(2)
					.multilineTextAlignment(.leading)
					.minimumScaleFactor(0.7)
				Text(act.formattedDuration)
					.font(AppTheme.caption)
					.foregroundColor(AppTheme.secondaryText)
					.lineLimit(2)
					.minimumScaleFactor(0.7)
			}
			Spacer()
			
			Button {
				editingAction = act
			} label: {
				Image(systemName: "pencil")
					.foregroundColor(AppTheme.primaryColor)
					.frame(width: 44, height: 44)
					.contentShape(Rectangle())
			}
			.buttonStyle(.borderless)
			
			Button {
				actions.removeAll { $0.id == act.id }
			} label: {
				Image(systemName: "trash")
					.foregroundColor(.red)
					.frame(width: 44, height: 44)
					.contentShape(Rectangle())
			}
			.buttonStyle(.borderless)
		}
		.padding()
		.background(AppTheme.cardBackground)
		.cornerRadius(AppTheme.cornerRadius)
	}
	
	private var sunriseHelpSheet: some View {
		NavigationStack {
			ZStack {
				AppTheme.backgroundGradient.ignoresSafeArea()
				
				ScrollView {
					VStack(alignment: .leading, spacing: 16) {
						sunriseHelpContent
					}
					.padding(AppTheme.padding)
					.iPadConstrained()
				}
			}
			.navigationTitle("Wake Up with the Sun")
			.navigationBarTitleDisplayMode(.inline)
			.tint(AppTheme.navigationBarAccentColor)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") { showingSunriseHelp = false }
				}
			}
		}
	}
	
	private var sunriseHelpContent: some View {
		Group {
			Text("Wake Up with the Sun")
				.font(AppTheme.headline)
				.foregroundColor(AppTheme.primaryText)
			
			Text("Why Getting Up with the Sun is Very Healthy")
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(AppTheme.primaryColor)
			
			Text("Waking up around sunrise helps your body work the way it was designed to. Humans evolved for thousands of years using the sun—not alarms or screens—as the main signal for when to wake and sleep. When you get up with the sun consistently, several important systems in your body stay balanced and healthy.")
				.font(AppTheme.body)
				.foregroundColor(AppTheme.primaryText)
			
			sunriseBenefitsCard
			sunriseHowItWorksSection
		}
	}
	
	private var sunriseBenefitsCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Key Benefits:")
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(AppTheme.primaryText)
			
			sunriseBenefitsList
		}
		.padding()
		.background(AppTheme.cardBackground)
		.cornerRadius(AppTheme.cornerRadius)
	}
	
	private var sunriseBenefitsList: some View {
		VStack(alignment: .leading, spacing: 10) {
			benefitRow(title: "Sets Your Circadian Rhythm", description: "Your internal 24-hour clock aligns perfectly. Morning sunlight tells your brain it's daytime, making you feel more awake during the day and naturally sleepy at night.")
			benefitRow(title: "Improves Sleep Quality", description: "Morning sunlight stops melatonin at the right time. 12–14 hours later, your body naturally releases it again, helping you fall asleep faster with fewer wake-ups and more refreshing sleep.")
			benefitRow(title: "Boosts Mood & Mental Health", description: "Sunrise light increases serotonin (the mood chemical). People who get morning light tend to feel calmer, more positive, and less stressed.")
			benefitRow(title: "Enhances Focus & Energy", description: "Waking with the sun helps faster mental alertness, better concentration, and more consistent energy throughout the day.")
			benefitRow(title: "Supports Metabolism & Physical Health", description: "A well-aligned circadian rhythm helps regulate appetite, blood sugar, and hormones involved in growth and repair.")
			benefitRow(title: "Reduces Caffeine Dependence", description: "When you wake naturally with sunlight, you rely less on caffeine and feel less groggy. Your body learns to wake up on its own.")
		}
	}
	
	private func benefitRow(title: String, description: String) -> some View {
		HStack(alignment: .top, spacing: 8) {
			Text("✓")
				.foregroundColor(AppTheme.primaryColor)
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.system(size: 13, weight: .semibold))
					.foregroundColor(AppTheme.primaryText)
				Text(description)
					.font(AppTheme.caption)
					.foregroundColor(AppTheme.secondaryText)
			}
		}
	}
	
	private var sunriseHowItWorksSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("How It Works with Routine Hub:")
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(AppTheme.primaryText)
			
			VStack(alignment: .leading, spacing: 8) {
				bulletPoint("Your location is used to calculate today's sunrise time")
				bulletPoint(sunriseOffsetText)
				bulletPoint("This updates automatically each day based on your location")
				bulletPoint("Consistency matters more than perfection—waking within 30–60 minutes of sunrise makes a big difference")
			}
			.padding(.leading, 4)
		}
	}

	private var sunsetHelpSheet: some View {
		NavigationStack {
			ZStack {
				AppTheme.backgroundGradient.ignoresSafeArea()

				ScrollView {
					VStack(alignment: .leading, spacing: 16) {
						sunsetHelpContent
					}
					.padding(AppTheme.padding)
					.iPadConstrained()
				}
			}
			.navigationTitle("Look at the Sunset")
			.navigationBarTitleDisplayMode(.inline)
			.tint(AppTheme.navigationBarAccentColor)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") { showingSunsetHelp = false }
				}
			}
		}
	}

	private var sunsetHelpContent: some View {
		Group {
			Text("Look at the Sunset")
				.font(AppTheme.headline)
				.foregroundColor(AppTheme.primaryText)

			Text("Why Sleeping Around Sunset Can Help")
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(AppTheme.primaryColor)

			Text("Going to bed closer to sunset helps align your body clock with natural light cycles. When evening light exposure drops and you keep a consistent bedtime, your brain can release melatonin at the right time and support deeper, more restorative sleep.")
				.font(AppTheme.body)
				.foregroundColor(AppTheme.primaryText)

			sunsetBenefitsCard
			sunsetHowItWorksSection
		}
	}

	private var sunsetBenefitsCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Key Benefits:")
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(AppTheme.primaryText)

			VStack(alignment: .leading, spacing: 10) {
				benefitRow(title: "Better Sleep Onset", description: "Lower light exposure in the evening helps your body produce melatonin naturally, making it easier to fall asleep.")
				benefitRow(title: "More Stable Energy", description: "Consistent sleep timing improves next-day alertness, mood, and energy consistency.")
				benefitRow(title: "Improved Recovery", description: "Earlier, regular sleep supports hormone balance, tissue repair, and immune function.")
				benefitRow(title: "Less Night Stimulation", description: "Reducing late-night screen/light exposure may lower stress and improve sleep quality.")
			}
		}
		.padding()
		.background(AppTheme.cardBackground)
		.cornerRadius(AppTheme.cornerRadius)
	}

	private var sunsetHowItWorksSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("How It Works with Routine Hub:")
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(AppTheme.primaryText)

			VStack(alignment: .leading, spacing: 8) {
				bulletPoint("Your location is used to calculate today's sunset time")
				bulletPoint(sunsetOffsetText)
				bulletPoint("This updates automatically each day based on your location")
				bulletPoint("A consistent wind-down time is usually more important than being exact to the minute")
			}
			.padding(.leading, 4)
		}
	}
	
	private func bulletPoint(_ text: String) -> some View {
		HStack(alignment: .top, spacing: 8) {
			Text("•")
				.foregroundColor(AppTheme.primaryColor)
			Text(text)
				.font(AppTheme.caption)
				.foregroundColor(AppTheme.primaryText)
		}
	}

	private var formattedAlarmTime: String {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		return formatter.string(from: alarmTime)
	}

	private func saveRoutine() {
		let routine = Routine(
			id: routineToEdit?.id ?? UUID(),
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			alarmEnabled: alarmEnabled,
			alarmTime: alarmTime,
			wakeUpWithSun: wakeUpWithSun,
			goToBedWithSun: goToBedWithSun,
			showCalendarEvents: showCalendarEvents,
			selectedDays: selectedDays,
			actions: actions
		)

		// Check if this is the first routine being created
		let isFirstRoutine = routineToEdit == nil && routineManager.routines.isEmpty

		if routineToEdit == nil {
			routineManager.addRoutine(routine)
		} else {
			routineManager.updateRoutine(routine)
		}

		// Request notification permission after first routine is created
		if isFirstRoutine {
			requestNotificationPermission()
		}

		Task {
			if routine.alarmEnabled {
				await alarmManager.scheduleAlarm(for: routine)
			} else {
				await alarmManager.cancelAlarm(for: routine)
			}
		}

		dismiss()
	}
	
	private func requestNotificationPermission() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
			if let error = error {
				print("[AddRoutineView] Notification permission error: \\(error.localizedDescription)")
			} else {
				print("[AddRoutineView] Notification permission granted: \\(granted)")
			}
		}
	}
	
	private func checkNotificationPermission() {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			DispatchQueue.main.async {
				switch settings.authorizationStatus {
				case .notDetermined:
					// First time - request permission
					UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
						if !granted {
							DispatchQueue.main.async {
								self.alarmEnabled = false
							}
						}
					}
				case .denied:
					// Previously denied - show alert to go to settings
					self.alarmEnabled = false
					self.showingNotificationSettingsAlert = true
				case .authorized, .provisional, .ephemeral:
					// Already have permission
					break
				@unknown default:
					break
				}
			}
		}
	}

		private func enforceNotificationPermissionForWakeUpWithSun() {
			UNUserNotificationCenter.current().getNotificationSettings { settings in
				DispatchQueue.main.async {
					switch settings.authorizationStatus {
					case .notDetermined:
						UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
							DispatchQueue.main.async {
								if granted {
									enableWakeUpWithSunFlow()
								} else {
									wakeUpWithSun = false
									alarmEnabled = false
								}
							}
						}
					case .denied:
						showingNotificationSettingsAlert = true
						wakeUpWithSun = false
						alarmEnabled = false
					case .authorized, .provisional, .ephemeral:
						enableWakeUpWithSunFlow()
					@unknown default:
						wakeUpWithSun = false
						alarmEnabled = false
					}
				}
			}
		}

		private func enableWakeUpWithSunFlow() {
			// First check location permission
			let locationStatus = locationManager.authorizationStatus
			
			switch locationStatus {
			case .denied, .restricted:
				// Location permission denied - show alert
				showingLocationSettingsAlert = true
				wakeUpWithSun = false
				return
			case .notDetermined:
				// Request location permission
				locationManager.requestLocationPermission()
				// We'll need to wait for the permission result
				// The onChange on authorizationStatus will handle this
			case .authorizedWhenInUse, .authorizedAlways:
				// Permission granted, proceed
				break
			@unknown default:
				break
			}
			
			alarmEnabled = true
			
			// Request location permission and get current location
			locationManager.requestLocationPermission()
			
			// If we already have a sunrise time, use it immediately
			if let sunrise = locationManager.sunriseTime {
				let offsetMinutes = settingsManager.minutesBeforeSunrise
				let adjustedTime = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: sunrise) ?? sunrise
				alarmTime = adjustedTime
				let formatter = DateFormatter()
				formatter.timeStyle = .short
				formatter.dateStyle = .none
				print("[AddRoutineView] Wake-up-with-sun enabled (existing sunrise). Sunrise: \(formatter.string(from: sunrise)), Alarm set to: \(formatter.string(from: adjustedTime)) (offset: \(offsetMinutes) min)")
			} else {
				// No sunrise time yet - request fresh location
				// The onChange(of: locationManager.sunriseTime) will update alarm when available
				locationManager.getCurrentLocation()
				print("[AddRoutineView] Wake-up-with-sun enabled. Waiting for location/sunrise data...")
			}
		}

		private func enforceNotificationPermissionForGoToBedWithSun() {
			UNUserNotificationCenter.current().getNotificationSettings { settings in
				DispatchQueue.main.async {
					switch settings.authorizationStatus {
					case .notDetermined:
						UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
							DispatchQueue.main.async {
								if granted {
									enableGoToBedWithSunFlow()
								} else {
									goToBedWithSun = false
									alarmEnabled = false
								}
							}
						}
					case .denied:
						showingNotificationSettingsAlert = true
						goToBedWithSun = false
						alarmEnabled = false
					case .authorized, .provisional, .ephemeral:
						enableGoToBedWithSunFlow()
					@unknown default:
						goToBedWithSun = false
						alarmEnabled = false
					}
				}
			}
		}

		private func enableGoToBedWithSunFlow() {
			let locationStatus = locationManager.authorizationStatus

			switch locationStatus {
			case .denied, .restricted:
				showingLocationSettingsAlert = true
				goToBedWithSun = false
				return
			case .notDetermined:
				locationManager.requestLocationPermission()
			case .authorizedWhenInUse, .authorizedAlways:
				break
			@unknown default:
				break
			}

			alarmEnabled = true
			locationManager.requestLocationPermission()

			if let sunset = locationManager.sunsetTime {
				let offsetMinutes = settingsManager.minutesFromSunset
				let adjustedTime = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: sunset) ?? sunset
				alarmTime = adjustedTime
				let formatter = DateFormatter()
				formatter.timeStyle = .short
				formatter.dateStyle = .none
				print("[AddRoutineView] Go-to-bed-with-sun enabled (existing sunset). Sunset: \(formatter.string(from: sunset)), Alarm set to: \(formatter.string(from: adjustedTime)) (offset: \(offsetMinutes) min)")
			} else {
				locationManager.getCurrentLocation()
				print("[AddRoutineView] Go-to-bed-with-sun enabled. Waiting for location/sunset data...")
			}
		}
	
	private func requestCalendarPermission() {
		let eventStore = EKEventStore()
		let status = EKEventStore.authorizationStatus(for: .event)
		
		switch status {
		case .notDetermined:
			if #available(iOS 17.0, *) {
				eventStore.requestFullAccessToEvents { granted, error in
					if !granted {
						DispatchQueue.main.async {
							self.showCalendarEvents = false
						}
					}
				}
			} else {
				eventStore.requestAccess(to: .event) { granted, error in
					if !granted {
						DispatchQueue.main.async {
							self.showCalendarEvents = false
						}
					}
				}
			}
		case .denied, .restricted:
			// Permission denied - turn off toggle and could show alert to go to settings
			showCalendarEvents = false
		case .authorized, .fullAccess:
			// Already have permission
			break
		case .writeOnly:
			showCalendarEvents = false
		@unknown default:
			break
		}
	}
}

// MARK: - Preference Key for Action Frames

struct ActionFrameKey: PreferenceKey {
	static var defaultValue: [UUID: CGRect] = [:]
	static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
		value.merge(nextValue()) { $1 }
	}
}

#Preview {
	AddRoutineView(routineToEdit: nil)
		.environmentObject(RoutineManager())
		.environmentObject(AlarmManager())
		.environmentObject(LocationManager())
}
