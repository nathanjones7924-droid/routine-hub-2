//
//  Morning_RoutineApp.swift
//  Morning Routine
//
//  Created by Jason Jones on 12/10/25.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAnalytics
import GoogleMobileAds
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // Reference to alarm manager (set from app)
    static var alarmManager: AlarmManager?
    static var routineManager: RoutineManager?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set notification delegate to handle taps
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize Google Mobile Ads
        // The GADApplicationIdentifier is now in Info.plist
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["6e169cd0b52443295503d76c1ccbcc8d"]
        GADMobileAds.sharedInstance().start { status in
            print("[GAD] Mobile Ads SDK initialized")
            // Log adapter initialization states
            for (adapterName, adapterStatus) in status.adapterStatusesByClassName {
                print("[GAD] Adapter: \(adapterName) - state: \(String(describing: adapterStatus.state)) - description: \(adapterStatus.description)")
            }
        }
        
        // Log app launch
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        
        return true
    }
    
    // Handle notification when app is in foreground - show it and play sound
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("[AppDelegate] Notification received while app in foreground")
        
        // Check if it's an alarm notification
        if notification.request.content.categoryIdentifier == "MORNING_ROUTINE_ALARM" {
            // Start beeping immediately when alarm fires while app is open
            if let routineIdString = notification.request.content.userInfo["routineId"] as? String,
               let routineId = UUID(uuidString: routineIdString) {
                Task { @MainActor in
                    // Only trigger if this is the selected routine
                    if let alarmManager = AppDelegate.alarmManager,
                       let routineManager = AppDelegate.routineManager,
                       routineManager.selectedRoutineId == routineId,
                       let routine = routineManager.routines.first(where: { $0.id == routineId }) {
                        print("[AppDelegate] Starting alarm beep for routine: \(routine.name)")
                        alarmManager.triggeredRoutine = routine
                        alarmManager.playAlarmBeep()
                    } else {
                        print("[AppDelegate] Alarm notification ignored - routine is not selected")
                    }
                }
            }
        }
        
        // Show banner, play sound
        completionHandler([.banner, .sound])
    }
    
    // Handle when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("[AppDelegate] User tapped notification")
        
        let userInfo = response.notification.request.content.userInfo
        
        // Check if it's an alarm notification
        if response.notification.request.content.categoryIdentifier == "MORNING_ROUTINE_ALARM" {
            if let routineIdString = userInfo["routineId"] as? String,
               let routineId = UUID(uuidString: routineIdString) {
                
                Task { @MainActor in
                    // Only trigger if this is the selected routine
                    guard let routineManager = AppDelegate.routineManager,
                          routineManager.selectedRoutineId == routineId,
                          let routine = routineManager.routines.first(where: { $0.id == routineId }) else {
                        print("[AppDelegate] Alarm notification ignored - routine is not selected")
                        completionHandler()
                        return
                    }
                    
                    print("[AppDelegate] Alarm tapped for routine: \(routine.name)")
                    
                    // Handle different actions
                    switch response.actionIdentifier {
                    case "START_ROUTINE":
                        print("[AppDelegate] User chose to start routine")
                        AppDelegate.alarmManager?.triggeredRoutine = routine
                        AppDelegate.alarmManager?.playAlarmBeep()
                        
                    case "SNOOZE":
                        print("[AppDelegate] User chose to snooze")
                        // Schedule a new notification in 5 minutes
                        await AppDelegate.alarmManager?.snoozeAlarm(for: routine)
                        
                    case UNNotificationDefaultActionIdentifier:
                        // User tapped the notification itself
                        print("[AppDelegate] User tapped notification - starting alarm beep")
                        AppDelegate.alarmManager?.triggeredRoutine = routine
                        AppDelegate.alarmManager?.playAlarmBeep()
                        
                    default:
                        break
                    }
                }
            }
        }
        
        completionHandler()
    }
}

@main
struct Morning_RoutineApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create state objects for dependency injection
    @StateObject private var routineManager = RoutineManager()
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var locationManager = LocationManager()
    
    init() {
        // Configure navigation bar appearance for dark mode
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.91, green: 0.36, blue: 0.02, alpha: 1.0)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(routineManager)
                .environmentObject(alarmManager)
                .environmentObject(timerManager)
                .environmentObject(locationManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Set up dependencies
                    alarmManager.locationManager = locationManager
                    alarmManager.routines = routineManager.routines
                    alarmManager.selectedRoutineId = routineManager.selectedRoutineId
                    
                    // Set static references for AppDelegate to access
                    AppDelegate.alarmManager = alarmManager
                    AppDelegate.routineManager = routineManager
                    
                    // Request notification permission on app launch
                    Task {
                        await alarmManager.requestPermission()
                        // Schedule all alarms on app launch
                        await alarmManager.updateAllAlarms(routines: routineManager.routines)
                    }
                }
                .onChange(of: routineManager.routines) { _, newRoutines in
                    // Update alarms when routines change
                    alarmManager.routines = newRoutines
                    Task {
                        await alarmManager.updateAllAlarms(routines: newRoutines)
                    }
                }
                .onChange(of: routineManager.selectedRoutineId) { _, newSelectedId in
                    // Sync selected routine to alarm manager
                    alarmManager.selectedRoutineId = newSelectedId
                }
                .onChange(of: locationManager.sunriseTime) { _, _ in
                    // Reschedule sunrise-based alarms when sunrise time updates
                    Task {
                        await alarmManager.rescheduleSunriseAlarms(routines: routineManager.routines)
                    }
                }
        }
    }
}
