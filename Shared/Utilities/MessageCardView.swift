import SwiftUI
import UIKit // Required for Haptics

struct MessageCardView: View {
    let message: InterruptMessage
    let requiresBreathing: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false
    
    // New 3-Phase State
    enum Phase { case countdown, breathing, quote }
    @State private var currentPhase: Phase = .quote
    
    // Breathing Animation States
    @State private var breathScale: CGFloat = 0.5
    @State private var promptText = "3"
    
    var splitText: (quote: String, author: String?) {
        let parts = message.text.components(separatedBy: "\n— ")
        if parts.count > 1 { return (parts[0], "— " + parts[1]) }
        return (message.text, nil)
    }
    
    var body: some View {
        ZStack {
            
            if currentPhase == .countdown || currentPhase == .breathing {
                // --- PHASE 1 & 2: ISOLATED BREATHING UI ---
                VStack(spacing: 80) { // Spacing prevents overlap completely
                    Text(promptText)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText()) // Beautiful number animation
                        .animation(.easeInOut, value: promptText)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .scaleEffect(breathScale)
                }
            } else if currentPhase == .quote {
                // --- PHASE 3: THE QUOTE CARD ---
                GeometryReader { geo in
                    Circle().fill(Color.accentColor.opacity(0.12)).frame(width: geo.size.width * 0.8).blur(radius: 60).offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.1)
                    Circle().fill(Color.accentColor.opacity(0.08)).frame(width: geo.size.width * 0.9).blur(radius: 80).offset(x: geo.size.width * 0.4, y: geo.size.height * 0.6)
                }
                .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 32)).foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    VStack(spacing: 20) {
                        Text(splitText.quote).font(.system(size: 32, weight: .medium)).multilineTextAlignment(.center)
                        if let author = splitText.author {
                            Text(author).font(.system(size: 20, weight: .regular)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                    }
                    .padding(30)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(y: animateIn ? 0 : 20)
                    
                    Text(message.typeRaw.uppercased()).font(.caption.bold()).foregroundStyle(.secondary).padding(.horizontal, 12).padding(.vertical, 6).background(Color.secondary.opacity(0.1)).clipShape(Capsule()).opacity(animateIn ? 1.0 : 0.0)
                    Spacer()
                    Text("Take a deep breath...").font(.callout).foregroundStyle(.tertiary).padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            if requiresBreathing {
                startBreathingSequence()
            } else {
                currentPhase = .quote
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { animateIn = true }
            }
        }
    }
    
    // MARK: - Core Haptics & Timing Engine
    private func startBreathingSequence() {
        currentPhase = .countdown
        promptText = "3"
        playHaptic()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            promptText = "2"
            playHaptic()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            promptText = "1"
            playHaptic()
        }
        
        // INHALE
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            currentPhase = .breathing
            promptText = "Inhale..."
            playHaptic(isSoft: true)
            withAnimation(.easeInOut(duration: 4.0)) { breathScale = 1.4 }
        }
        
        // EXHALE
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            promptText = "Exhale..."
            playHaptic(isSoft: true)
            withAnimation(.easeInOut(duration: 6.0)) { breathScale = 0.5 }
        }
        
        // REFRAME / QUOTE
        DispatchQueue.main.asyncAfter(deadline: .now() + 13.0) {
            withAnimation(.easeInOut(duration: 0.4)) { currentPhase = .quote }
            if BreathingSettings.shared.hapticsIOS {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { animateIn = true }
            }
        }
    }
    
    private func playHaptic(isSoft: Bool = false) {
            guard BreathingSettings.shared.hapticsIOS else { return }
            
            let strength = BreathingSettings.shared.hapticStrength
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            
            if isSoft {
                style = .soft
            } else {
                switch strength {
                case 1: style = .light
                case 2: style = .medium
                case 3: style = .heavy
                default: style = .medium
                }
            }
            
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }


}
