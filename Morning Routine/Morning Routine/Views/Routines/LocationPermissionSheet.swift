import SwiftUI

/// Sheet view for requesting location permission and displaying sunrise time
struct LocationPermissionSheet: View {
    @ObservedObject var locationManager: LocationManager
    let onLocationGranted: (Date?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.paddingLarge) {
                    Spacer()
                    
                    // Sun icon
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primaryColor)
                    
                    // Title
                    VStack(spacing: AppTheme.paddingSmall) {
                        Text("Wake Up with the Sun")
                            .font(AppTheme.largeTitle)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Share your location to set your alarm to sunrise time")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Status message
                    if let errorMessage = locationManager.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .font(AppTheme.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(AppTheme.cornerRadius)
                    } else if let sunriseTime = locationManager.sunriseTime {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primaryColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sunrise Time")
                                        .font(AppTheme.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    
                                    Text(formatTime(sunriseTime))
                                        .font(AppTheme.headline)
                                        .foregroundColor(AppTheme.primaryText)
                                }
                                
                                Spacer()
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
                    
                    Spacer()
                    
                    // Share location button
                    if locationManager.sunriseTime == nil {
                        Button(action: {
                            locationManager.requestLocationPermission()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                Text("Share Location")
                            }
                            .font(AppTheme.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                    }
                    
                    // Done button
                    Button(action: {
                        onLocationGranted(locationManager.sunriseTime)
                    }) {
                        Text(locationManager.sunriseTime != nil ? "Use Sunrise Time" : "Cancel")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.elevatedBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(AppTheme.borderColor, lineWidth: AppTheme.borderWidth)
                            )
                    }
                }
                .padding(AppTheme.padding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.navigationBarAccentColor)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    LocationPermissionSheet(locationManager: LocationManager(), onLocationGranted: { _ in })
}
