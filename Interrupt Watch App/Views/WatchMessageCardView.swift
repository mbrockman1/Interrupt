import SwiftUI
import WatchKit

struct WatchMessageCardView: View {
    let message: InterruptMessage
    @Environment(\.dismiss) private var dismiss
    
    // New 3-Phase State
    enum Phase { case countdown, breathing, quote }
    @State private var currentPhase: Phase = .quote
    
    @State private var breathScale: CGFloat = 0.5
    @State private var promptText = "3"
    
    var splitText: (quote: String, author: String?) {
        let parts = message.text.components(separatedBy: "\n— ")
        if parts.count > 1 { return (parts[0], "— " + parts[1]) }
        return (message.text, nil)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if currentPhase == .countdown || currentPhase == .breathing {
                VStack(spacing: 30) {
                    Text(promptText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: promptText)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 90, height: 90)
                        .scaleEffect(breathScale)
                }
            } else if currentPhase == .quote {
                ScrollView {
                    VStack(spacing: 12) {
                        Text(splitText.quote).font(.system(size: 20, weight: .medium)).multilineTextAlignment(.center).padding(.top, 24).padding(.horizontal, 8)
                        if let author = splitText.author {
                            Text(author).font(.system(size: 14, weight: .regular)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 8)
                        }
//                        Button(action: { dismiss() }) { Text("Done").fontWeight(.bold) }.buttonStyle(.borderedProminent).tint(.accentColor).padding(.vertical, 16)
                    }
                }
            }
        }
        .onAppear {
            let needsBreathing = BreathingSettings.shared.isWatchEnabled && BreathingSettings.shared.hasBreathing(for: message.categoryName)
            if needsBreathing {
                startBreathingSequence()
            } else {
                currentPhase = .quote
            }
        }
    }
    
    // NEW: Simulates 1-3 strength by using different Watch haptic types
    private func playWatchHaptic(isExhale: Bool = false) {
        guard BreathingSettings.shared.hapticsWatch else { return }
        
        let strength = BreathingSettings.shared.hapticStrength
        
        switch strength {
        case 1:
            // Light: Subtle wrist clicks
            WKInterfaceDevice.current().play(.click)
        case 2:
            // Medium: Apple's native Directional taps
            WKInterfaceDevice.current().play(isExhale ? .directionDown : .directionUp)
        case 3:
            // Heavy: Strong prominent notification rumbles
            WKInterfaceDevice.current().play(.notification)
        default:
            WKInterfaceDevice.current().play(.click)
        }
    }

    func startBreathingSequence() {
        currentPhase = .countdown
        promptText = "3"
        playWatchHaptic()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            promptText = "2"
            playWatchHaptic()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            promptText = "1"
            playWatchHaptic()
        }
        
        // INHALE
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            currentPhase = .breathing
            promptText = "Inhale..."
            playWatchHaptic()
            withAnimation(.easeInOut(duration: 4.0)) { breathScale = 1.5 }
            
            Task {
                let inhaleDelays = [0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.3, 0.2]
                for _ in inhaleDelays {
                    playWatchHaptic()
                    try? await Task.sleep(for: .seconds(0.4)) // Keeps a steady pulse
                }
            }
        }
        
        // EXHALE
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            promptText = "Exhale..."
            playWatchHaptic(isExhale: true)
            withAnimation(.easeInOut(duration: 6.0)) { breathScale = 0.5 }
            
            Task {
                let exhaleDelays = [0.6, 0.9, 1.2, 1.5, 1.8]
                for _ in exhaleDelays {
                    playWatchHaptic(isExhale: true)
                    try? await Task.sleep(for: .seconds(0.8)) // Slower pulse for exhale
                }
            }
        }
        
        // REFRAME / QUOTE
        DispatchQueue.main.asyncAfter(deadline: .now() + 13.0) {
            withAnimation(.easeInOut(duration: 0.4)) { currentPhase = .quote }
            if BreathingSettings.shared.hapticsWatch {
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
}
