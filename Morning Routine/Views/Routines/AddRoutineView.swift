import SwiftUI

/// View for creating or editing a Routine
struct AddRoutineView: View {
	let routineToEdit: Routine?

	@EnvironmentObject var routineManager: RoutineManager
	@EnvironmentObject var alarmManager: AlarmManager
	@EnvironmentObject var locationManager: LocationManager
	@Environment(\.dismiss) private var dismiss

	@State private var name: String
	@State private var alarmEnabled: Bool
	@State private var alarmTime: Date
	@State private var wakeUpWithSun: Bool
	@State private var actions: [RoutineAction]

	@State private var showingAddAction = false
	@State private var editingAction: RoutineAction? = nil
	@State private var showingSunriseHelp = false

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

							TextField("Morning Routine", text: $name)
								.padding()
								.background(AppTheme.cardBackground)
								.cornerRadius(AppTheme.cornerRadius)
								.overlay(
									RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
										.stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
								)
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
												Text(act.formattedDuration)
													.font(AppTheme.caption)
													.foregroundColor(AppTheme.secondaryText)
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
								.scrollDisabled(true)
								.frame(height: CGFloat(actions.count * 90))
								.background(Color.clear)
							}
						}

						Spacer(minLength: 40)
					}
					.padding(AppTheme.padding)
				}
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
								
								Text("When enabled, your alarm will automatically adjust to ring 5 minutes before the sunrise time in your location. This allows you to wake up naturally as the day begins, rather than at a fixed time each day.")
									.font(AppTheme.body)
									.foregroundColor(AppTheme.primaryText)
									.lineSpacing(4)
								
								VStack(alignment: .leading, spacing: 12) {
									Text("How it works:")
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
											Text("The alarm is set for 5 minutes before sunrise")
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
									}
									.padding(.leading, 4)
								}
								.padding()
								.background(AppTheme.cardBackground)
								.cornerRadius(AppTheme.cornerRadius)
								
								Spacer()
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
