//
//  ContentView.swift
//  Morning Routine
//
//  Created by Jason Jones on 12/10/25.
//

import SwiftUI
import Combine
import FirebaseAnalytics

// MARK: - Keyboard Dismissal Extension
extension View {
    func dismissKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct ContentView: View {
    @EnvironmentObject var routineManager: RoutineManager
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    
    @State private var showRoutineExecution = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            MainTabView()
                .dismissKeyboardOnTap()
                .onAppear {
                    // Show onboarding if not completed
                    if !onboardingManager.hasCompletedOnboarding {
                        showOnboarding = true
                    }
                    
                    // Connect LocationManager to AlarmManager
                    alarmManager.locationManager = locationManager
                    
                    // Request location update if any routine has wakeUpWithSun enabled
                    // This ensures sunrise time is recalculated daily
                    if routineManager.routines.contains(where: { $0.wakeUpWithSun }) {
                        locationManager.getCurrentLocation()
                        print("[ContentView] Requesting location update for wakeUpWithSun routines")
                    }
                }
                .onReceive(routineManager.$routines) { routines in
                    alarmManager.routines = routines
                }
                .onReceive(alarmManager.$triggeredRoutine.compactMap { $0 }) { routine in
                    // Only execute if this is the selected routine
                    if routineManager.selectedRoutineId == routine.id {
                        routineManager.startRoutine(routine)
                        showRoutineExecution = true
                    }
                }

            if showRoutineExecution, let routine = alarmManager.triggeredRoutine {
                RoutineExecutionView(routine: routine, isPresented: $showRoutineExecution)
                    .environmentObject(routineManager)
                    .environmentObject(timerManager)
                    .environmentObject(alarmManager)
                    .transition(.move(edge: .bottom))
            }

            // Alarm overlay on top so it's always visible
            if alarmManager.isAlarmBeeping {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Text("Alarm is sounding!")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                        Button(action: {
                            alarmManager.stopAlarmBeep()
                            
                            // Log analytics event for alarm turned off
                            if let routine = alarmManager.triggeredRoutine {
                                Analytics.logEvent("alarm_turned_off", parameters: [
                                    "routine_id": routine.id.uuidString,
                                    "routine_name": routine.name
                                ])
                            }
                            
                            // Setup and start the routine (same as clicking "Start Routine" button)
                            if let routine = alarmManager.triggeredRoutine {
                                timerManager.setupWithActions(routine.actions)
                                routineManager.startRoutine(routine)
                                showRoutineExecution = true
                            }
                        }) {
                            Text("Turn Off Alarm")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
            }
            
            // Onboarding overlay
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .transition(.opacity)
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    ContentView()
        .environmentObject(RoutineManager())
        .environmentObject(AlarmManager())
        .environmentObject(TimerManager())
}
