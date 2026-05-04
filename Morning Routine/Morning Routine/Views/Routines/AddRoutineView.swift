import SwiftUI

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
	@State private var actions: [RoutineAction]

	@State private var showingAddAction = false
	@State private var editingAction: RoutineAction? = nil
	@State private var showingSunriseHelp = false

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

	init(routineToEdit: Routine?) {
		self.routineToEdit = routineToEdit

		if let routine = routineToEdit {
			_name = State(initialValue: routine.name)
			_alarmEnabled = State(initialValue: routine.alarmEnabled)
			_alarmTime = State(initialValue: routine.alarmTime)
			_wakeUpWithSun = State(initialValue: routine.wakeUpWithSun)
			_actions = State(initialValue: routine.actions)
		} else {
			_name = State(initialValue: "New Routine")
			_alarmEnabled = State(initialValue: false)
			_alarmTime = State(initialValue: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date())
			_wakeUpWithSun = State(initialValue: false)
			_actions = State(initialValue: [])
		}
	}

	var body: some View {
		NavigationStack {
			ZStack {
				AppTheme.backgroundGradient.ignoresSafeArea()

				ScrollView {
					VStack(spacing: AppTheme.padding) {
						// Name
						VStack(alignment: .leading, spacing: 8) {
							Text("Routine Name")
								.font(AppTheme.headline)
								.foregroundColor(AppTheme.primaryText)

							TextField("My Routine", text: $name)
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

						// Alarm settings
						VStack(alignment: .leading, spacing: 8) {
							Text("Alarm")
								.font(AppTheme.headline)
								.foregroundColor(AppTheme.primaryText)

							Toggle(isOn: $alarmEnabled) {
								Text(alarmEnabled ? "On" : "Off")
									.foregroundColor(AppTheme.primaryText)
							}
							.tint(AppTheme.primaryColor)

						if alarmEnabled && !wakeUpWithSun {
							DatePicker("Alarm Time", selection: $alarmTime, displayedComponents: .hourAndMinute)
								.datePickerStyle(.wheel)
								.labelsHidden()
								.frame(maxHeight: 150)
								.padding()
								.background(AppTheme.cardBackground)
								.cornerRadius(AppTheme.cornerRadius)
								.overlay(
									RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
										.stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
								)
						} else if alarmEnabled && wakeUpWithSun {
							Text("Alarm: \(formattedAlarmTime) (5 min before sunrise)")
								.font(AppTheme.body)
								.foregroundColor(AppTheme.primaryText)
								.padding()
								.frame(maxWidth: .infinity, alignment: .center)
							}

							HStack(spacing: 0) {
								Text("Wake up with the sun")
									.foregroundColor(AppTheme.primaryText)
								
								Button(action: { showingSunriseHelp = true }) {
									Image(systemName: "questionmark.circle")
										.foregroundColor(AppTheme.primaryColor)
										.font(.system(size: 16))
								}
								.buttonStyle(.plain)
								.padding(.leading, 3)
								
								Spacer()
								
								Toggle("", isOn: $wakeUpWithSun)
									.tint(AppTheme.primaryColor)
									.labelsHidden()
							}
							.onChange(of: wakeUpWithSun) { oldValue, newValue in
								if newValue {
									alarmEnabled = true
									locationManager.requestLocationPermission()
									// If we already have a sunrise time, set alarm to 5 min before
									if let sunrise = locationManager.sunriseTime {
										let fiveMinutesBefore = Calendar.current.date(byAdding: .minute, value: -5, to: sunrise) ?? sunrise
										alarmTime = fiveMinutesBefore
										let formatter = DateFormatter()
										formatter.timeStyle = .short
										formatter.dateStyle = .none
										print("[AddRoutineView] Wake-up-with-sun enabled. Sunrise: \(formatter.string(from: sunrise)), Alarm set to 5 min before: \(formatter.string(from: fiveMinutesBefore))")
									}
								}
							}
						}

						// Actions
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
							} else {
								List {
									ForEach(actions) { act in
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
										.overlay(
											RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
												.stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
										)
										.listRowBackground(Color.clear)
										.listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
										.listRowSeparator(.hidden)
									}
									.onMove { indexSet, destination in
										actions.move(fromOffsets: indexSet, toOffset: destination)
									}
								}
								.listStyle(.plain)
								.scrollContentBackground(.hidden)
								.background(Color.clear)
							}
						}

						Spacer(minLength: 40)
					}
					.padding(AppTheme.padding)
				}
				.dismissKeyboardOnTap()
			}
			.navigationTitle(routineToEdit == nil ? "New Routine" : "Edit Routine")
			.navigationBarTitleDisplayMode(.inline)
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
				// Set alarm to 5 minutes before sunrise
				let fiveMinutesBefore = Calendar.current.date(byAdding: .minute, value: -5, to: sunrise) ?? sunrise
				alarmTime = fiveMinutesBefore
				alarmEnabled = true
				let formatter = DateFormatter()
				formatter.timeStyle = .short
				formatter.dateStyle = .none
				print("[AddRoutineView] Sunrise: \(formatter.string(from: sunrise)), Alarm set to 5 min before: \(formatter.string(from: fiveMinutesBefore))")
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
			.sheet(isPresented: $showingSunriseHelp) {
				NavigationStack {
					ZStack {
						AppTheme.backgroundGradient.ignoresSafeArea()
						
						ScrollView {
							VStack(alignment: .leading, spacing: 16) {
								Text("Wake Up with the Sun")
									.font(AppTheme.headline)
									.foregroundColor(AppTheme.primaryText)
								
								Text("Why Getting Up with the Sun is Very Healthy")
									.font(.system(size: 14, weight: .semibold))
									.foregroundColor(AppTheme.primaryColor)
								
								Text("Waking up around sunrise helps your body work the way it was designed to. Humans evolved for thousands of years using the sun—not alarms or screens—as the main signal for when to wake and sleep. When you get up with the sun consistently, several important systems in your body stay balanced and healthy.")
									.font(AppTheme.body)
									.foregroundColor(AppTheme.primaryText)
								
								// Key Benefits
								VStack(alignment: .leading, spacing: 12) {
									Text("Key Benefits:")
										.font(.system(size: 14, weight: .semibold))
										.foregroundColor(AppTheme.primaryText)
									
									VStack(alignment: .leading, spacing: 10) {
										HStack(alignment: .top, spacing: 8) {
											Text("✓")
												.foregroundColor(AppTheme.primaryColor)
											VStack(alignment: .leading, spacing: 2) {
												Text("Sets Your Circadian Rhythm")
													.font(.system(size: 13, weight: .semibold))
													.foregroundColor(AppTheme.primaryText)
												Text("Your internal 24-hour clock aligns perfectly. Morning sunlight tells your brain it's daytime, making you feel more awake during the day and naturally sleepy at night.")
													.font(AppTheme.caption)
													.foregroundColor(AppTheme.secondaryText)
											}
										}
										
										HStack(alignment: .top, spacing: 8) {
											Text("✓")
												.foregroundColor(AppTheme.primaryColor)
											VStack(alignment: .leading, spacing: 2) {
												Text("Improves Sleep Quality")
													.font(.system(size: 13, weight: .semibold))
													.foregroundColor(AppTheme.primaryText)
												Text("Morning sunlight stops melatonin at the right time. 12–14 hours later, your body naturally releases it again, helping you fall asleep faster with fewer wake-ups and more refreshing sleep.")
													.font(AppTheme.caption)
													.foregroundColor(AppTheme.secondaryText)
											}
										}
										
										HStack(alignment: .top, spacing: 8) {
											Text("✓")
												.foregroundColor(AppTheme.primaryColor)
											VStack(alignment: .leading, spacing: 2) {
												Text("Boosts Mood & Mental Health")
													.font(.system(size: 13, weight: .semibold))
													.foregroundColor(AppTheme.primaryText)
												Text("Sunrise light increases serotonin (the mood chemical). People who get morning light tend to feel calmer, more positive, and less stressed.")
													.font(AppTheme.caption)
													.foregroundColor(AppTheme.secondaryText)
											}
										}
										
										HStack(alignment: .top, spacing: 8) {
											Text("✓")
												.foregroundColor(AppTheme.primaryColor)
											VStack(alignment: .leading, spacing: 2) {
												Text("Enhances Focus & Energy")
													.font(.system(size: 13, weight: .semibold))
													.foregroundColor(AppTheme.primaryText)
												Text("Waking with the sun helps faster mental alertness, better concentration, and more consistent energy throughout the day.")
													.font(AppTheme.caption)
													.foregroundColor(AppTheme.secondaryText)
											}
										}
										
										HStack(alignment: .top, spacing: 8) {
											Text("✓")
												.foregroundColor(AppTheme.primaryColor)
											VStack(alignment: .leading, spacing: 2) {
												Text("Supports Metabolism & Physical Health")
													.font(.system(size: 13, weight: .semibold))
													.foregroundColor(AppTheme.primaryText)
												Text("A well-aligned circadian rhythm helps regulate appetite, blood sugar, and hormones involved in growth and repair.")
													.font(AppTheme.caption)
													.foregroundColor(AppTheme.secondaryText)
											}
										}
										
										HStack(alignment: .top, spacing: 8) {
											Text("✓")
												.foregroundColor(AppTheme.primaryColor)
											VStack(alignment: .leading, spacing: 2) {
												Text("Reduces Caffeine Dependence")
													.font(.system(size: 13, weight: .semibold))
													.foregroundColor(AppTheme.primaryText)
												Text("When you wake naturally with sunlight, you rely less on caffeine and feel less groggy. Your body learns to wake up on its own.")
													.font(AppTheme.caption)
													.foregroundColor(AppTheme.secondaryText)
											}
										}
									}
								}
								.padding()
								.background(AppTheme.cardBackground)
								.cornerRadius(AppTheme.cornerRadius)
								
								Text("How It Works with Routine Hub:")
									.font(.system(size: 14, weight: .semibold))
									.foregroundColor(AppTheme.primaryText)
								
								VStack(alignment: .leading, spacing: 8) {
									HStack(alignment: .top, spacing: 8) {
										Text("•")
											.foregroundColor(AppTheme.primaryColor)
										Text("Your location is used to calculate today's sunrise time")
											.font(AppTheme.caption)
											.foregroundColor(AppTheme.primaryText)
									}
									
									HStack(alignment: .top, spacing: 8) {
										Text("•")
											.foregroundColor(AppTheme.primaryColor)
										Text(sunriseOffsetText)
											.font(AppTheme.caption)
											.foregroundColor(AppTheme.primaryText)
									}
									
									HStack(alignment: .top, spacing: 8) {
										Text("•")
											.foregroundColor(AppTheme.primaryColor)
										Text("This updates automatically each day based on your location")
											.font(AppTheme.caption)
											.foregroundColor(AppTheme.primaryText)
									}
									
									HStack(alignment: .top, spacing: 8) {
										Text("•")
											.foregroundColor(AppTheme.primaryColor)
										Text("Consistency matters more than perfection—waking within 30–60 minutes of sunrise makes a big difference")
											.font(AppTheme.caption)
											.foregroundColor(AppTheme.primaryText)
									}
								}
								.padding(.leading, 4)
							}
							.padding(AppTheme.padding)
						}
					}
					.navigationTitle("Wake Up with the Sun")
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .confirmationAction) {
							Button("Done") { showingSunriseHelp = false }
						}
					}
				}
			}
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
			actions: actions
		)

		if routineToEdit == nil {
			routineManager.addRoutine(routine)
		} else {
			routineManager.updateRoutine(routine)
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
}

#Preview {
	AddRoutineView(routineToEdit: nil)
		.environmentObject(RoutineManager())
		.environmentObject(AlarmManager())
		.environmentObject(LocationManager())
}
