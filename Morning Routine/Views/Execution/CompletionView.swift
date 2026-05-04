import SwiftUI

/// Completion view shown when all actions in a routine are done
struct CompletionView: View {
    @EnvironmentObject var routineManager: RoutineManager
    @EnvironmentObject var alarmManager: AlarmManager
    @Environment(\.dismiss) private var dismiss
    @Binding var isExecutionPresented: Bool
    
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background gradient (dark)
            LinearGradient(
                colors: [
                    AppTheme.darkBackground,
                    Color(red: 0.12, green: 0.08, blue: 0.10),
                    Color(red: 0.15, green: 0.10, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti effect
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            // Main content
            VStack(spacing: AppTheme.paddingLarge) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(AppTheme.elevatedBackground)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.borderColor.opacity(0.5), lineWidth: 2)
                        )
                    
                    Circle()
                        .fill(AppTheme.primaryColor)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.borderColor, lineWidth: 2)
                        )
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                
                // Great job text
                VStack(spacing: AppTheme.paddingSmall) {
                    Text("Great Job! 🎉")
                        .font(AppTheme.largeTitle)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text("You've completed your morning routine")
                        .font(AppTheme.body)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(showConfetti ? 1.0 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.3), value: showConfetti)
                
                Spacer()
                
                // Motivational message
                VStack(spacing: 8) {
                    Text("\"The way you start your day")
                    Text("sets the tone for the rest of it.\"")
                }
                .font(AppTheme.body)
                .italic()
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .opacity(showConfetti ? 1.0 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.5), value: showConfetti)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: AppTheme.padding) {
                    // Back to homepage button
                    Button {
                        goBackToHomepage()
                    } label: {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Back to Homepage")
                        }
                        .primaryButtonStyle()
                    }
                    
                    // Quit app button
                    Button {
                        quitApp()
                    } label: {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit App")
                        }
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
                .padding(.horizontal, AppTheme.paddingLarge)
                .padding(.bottom, AppTheme.paddingLarge)
                .opacity(showConfetti ? 1.0 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.7), value: showConfetti)
            }
            .padding(AppTheme.padding)
        }
        .onAppear {
            withAnimation {
                showConfetti = true
            }
            
            // Cancel the alarm notification so it won't fire again
            if let routine = routineManager.executingRoutine {
                Task {
                    await alarmManager.cancelAlarm(for: routine)
                    print("[CompletionView] Cancelled alarm for routine: \(routine.name)")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func goBackToHomepage() {
        routineManager.stopRoutine()
        isExecutionPresented = false
    }
    
    private func quitApp() {
        routineManager.stopRoutine()
        // Exit the app
        exit(0)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }
    
    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [
            AppTheme.primaryColor,
            AppTheme.borderColor,
            .yellow,
            .orange,
            .pink,
            .white
        ]
        
        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .orange,
                startX: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -100...(-50)),
                endY: size.height + 100,
                delay: Double.random(in: 0...1.5),
                duration: Double.random(in: 2...4),
                rotation: Double.random(in: 0...720)
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let delay: Double
    let duration: Double
    let rotation: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    
    @State private var yPosition: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8, height: 12)
            .cornerRadius(2)
            .rotationEffect(.degrees(currentRotation))
            .position(x: piece.startX + sin(yPosition / 30) * 30, y: yPosition)
            .opacity(opacity)
            .onAppear {
                yPosition = piece.startY
                
                withAnimation(
                    .easeIn(duration: piece.duration)
                    .delay(piece.delay)
                ) {
                    yPosition = piece.endY
                    currentRotation = piece.rotation
                }
                
                withAnimation(
                    .easeIn(duration: 0.5)
                    .delay(piece.delay + piece.duration - 0.5)
                ) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    CompletionView(isExecutionPresented: .constant(true))
        .environmentObject(RoutineManager())
}
