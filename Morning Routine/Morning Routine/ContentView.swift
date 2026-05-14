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
                    
                    // Request location update if any routine has sunrise/sunset based alarm enabled
                    if routineManager.routines.contains(where: { $0.wakeUpWithSun || $0.goToBedWithSun }) {
                        locationManager.getCurrentLocation()
                        print("[ContentView] Requesting location update for sun-based routines")
                    }
                }
                .onReceive(routineManager.$routines) { routines in
                    alarmManager.routines = routines
                }
                .onReceive(alarmManager.$triggeredRoutine.compactMap { $0 }) { routine in
                    // Only execute if this routine is in the selected routines
                    if routineManager.selectedRoutineIds.contains(routine.id) {
                        timerManager.setupWithActions(routine.actions)
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
