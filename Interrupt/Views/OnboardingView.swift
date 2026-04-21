//
//  OnboardingView.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/21/26.
//


import SwiftUI

struct OnboardingView: View {
    // Controls the first-launch state
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // AMBIENT BACKGROUND BLOBS
            GeometryReader { geo in
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.1)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: geo.size.width)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.6)
            }
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // PAGE 1: The Concept
                OnboardingPage(
                    icon: "brain.head.profile",
                    title: "Welcome to Interrupt.",
                    description: "A circuit breaker for your mind.\n\nWe all get stuck in thought loops. Interrupt is designed to help you catch and break cycles of stress, anxiety, and overthinking in seconds."
                )
                .tag(0)
                
                // PAGE 2: The Method
                OnboardingPage(
                    icon: "hand.raised.fill",
                    title: "The Method.",
                    description: "1. Notice you are ruminating.\n2. Open the app immediately.\n3. Select your emotion.\n\nInterrupt will guide you through a 10-second deep breath, followed by a curated psychological reframe."
                )
                .tag(1)
                
                // PAGE 3: The Secret Weapon (Widgets)
                VStack(spacing: 24) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentColor.gradient)
                        .padding(.bottom, 20)
                    
                    Text("The Secret Weapon")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text("Interrupt works best when it is instantly accessible.\n\nFor the best experience, add the Interrupt Widget to your iPhone Home Screen, and add the Complication to your Apple Watch face right now.")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer().frame(height: 40)
                    
                    Button(action: {
                        // Mark as seen and dismiss
                        hasSeenOnboarding = true
                        dismiss()
                    }) {
                        Text("I'm Ready")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 60)
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

// Reusable Page Component
struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor.gradient)
                .padding(.bottom, 20)
            
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 60) // Leaves room for the page dots
    }
}