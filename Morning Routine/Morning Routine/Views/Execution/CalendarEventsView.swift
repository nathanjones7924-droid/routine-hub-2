import SwiftUI
import EventKit

/// View showing today's calendar events before starting a routine
struct CalendarEventsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let routine: Routine
    let onContinue: () -> Void
    
    @State private var events: [EKEvent] = []
    @State private var permissionStatus: EKAuthorizationStatus = .notDetermined
    @State private var isLoading = true
    
    private let eventStore = EKEventStore()
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.padding) {
                // Header
                header
                
                // Events list
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryColor))
                        .scaleEffect(1.5)
                    Spacer()
                } else if permissionStatus == .denied || permissionStatus == .restricted {
                    permissionDeniedView
                } else if events.isEmpty {
                    noEventsView
                } else {
                    eventsList
                }
                
                // Continue button
                continueButton
            }
            .padding(AppTheme.padding)
            .iPadConstrained()
        }
        .onAppear {
            requestCalendarAccess()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.primaryColor)
            
            Text("Today's Schedule")
                .font(AppTheme.largeTitle)
                .foregroundColor(AppTheme.primaryText)
            
            Text(formattedDate)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.top, AppTheme.padding)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Events List
    
    private var eventsList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: AppTheme.paddingSmall) {
                ForEach(events, id: \.eventIdentifier) { event in
                    eventCard(event)
                }
            }
        }
    }
    
    private func eventCard(_ event: EKEvent) -> some View {
        HStack(spacing: AppTheme.padding) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled Event")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if event.isAllDay {
                    Text("All Day")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.secondaryText)
                } else {
                    Text(formatEventTime(event))
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(location)
                            .lineLimit(1)
                    }
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(AppTheme.padding)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
        )
    }
    
    private func formatEventTime(_ event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        
        return "\(start) - \(end)"
    }
    
    // MARK: - Empty/Permission Views
    
    private var noEventsView: some View {
        VStack(spacing: AppTheme.padding) {
            Spacer()
            
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.primaryColor.opacity(0.5))
            
            Text("No Events Today")
                .font(AppTheme.title)
                .foregroundColor(AppTheme.primaryText)
            
            Text("Your calendar is clear for today!")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: AppTheme.padding) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Calendar Access Needed")
                .font(AppTheme.title)
                .foregroundColor(AppTheme.primaryText)
            
            Text("To show your events, please enable calendar access in Settings.")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.primaryColor)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button {
            onContinue()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start \(routine.name)")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(AppTheme.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryColor)
            .cornerRadius(AppTheme.cornerRadius)
        }
        .padding(.bottom, AppTheme.padding)
    }
    
    // MARK: - Calendar Access
    
    private func requestCalendarAccess() {
        permissionStatus = EKEventStore.authorizationStatus(for: .event)
        
        switch permissionStatus {
        case .authorized, .fullAccess:
            fetchTodayEvents()
        case .notDetermined:
            if #available(iOS 17.0, *) {
                eventStore.requestFullAccessToEvents { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            self.permissionStatus = .fullAccess
                            self.fetchTodayEvents()
                        } else {
                            self.permissionStatus = .denied
                            self.isLoading = false
                        }
                    }
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            self.permissionStatus = .authorized
                            self.fetchTodayEvents()
                        } else {
                            self.permissionStatus = .denied
                            self.isLoading = false
                        }
                    }
                }
            }
        case .denied, .restricted:
            isLoading = false
        case .writeOnly:
            isLoading = false
            permissionStatus = .denied
        @unknown default:
            isLoading = false
        }
    }
    
    private func fetchTodayEvents() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            isLoading = false
            return
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let fetchedEvents = eventStore.events(matching: predicate)
        
        // Sort by start time, all-day events first
        events = fetchedEvents.sorted { event1, event2 in
            if event1.isAllDay && !event2.isAllDay {
                return true
            } else if !event1.isAllDay && event2.isAllDay {
                return false
            } else {
                return event1.startDate < event2.startDate
            }
        }
        
        isLoading = false
    }
}

#Preview {
    CalendarEventsView(
        routine: Routine(name: "Morning Routine"),
        onContinue: {}
    )
}
