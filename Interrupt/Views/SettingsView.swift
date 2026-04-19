//
//  AppFontDesign.swift
//  Interrupt
//
//  Created by Michael Brockman on 4/13/26.
//


import SwiftUI

// 1. The Font Options
enum AppFontDesign: String, CaseIterable {
    case standard = "Standard (Clean)"
    case rounded = "Rounded (Friendly)"
    case serif = "Serif (Classic)"
    
    var design: Font.Design {
        switch self {
        case .standard: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        }
    }
}

struct SettingsView: View {
    // 2. AppStorage saves the user's choice permanently
    @AppStorage("appFontPreference") private var appFontRaw: String = AppFontDesign.rounded.rawValue
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Legal Disclaimer Section
                Section(header: Text("Medical & Legal Disclaimer")) {
                    Text("Interrupt is designed as a lightweight self-help tool for momentary cognitive redirection. It is not intended to diagnose, treat, cure, or prevent any disease, mental health condition, or psychological disorder.\n\nThis application is not a substitute for professional therapy, counseling, or medical advice. If you are experiencing a mental health crisis, severe distress, or having thoughts of self-harm, please contact a qualified healthcare provider or emergency services immediately.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Appearance
                Section(header: Text("Appearance")) {
                    Picker("Typography", selection: $appFontRaw) {
                        ForEach(AppFontDesign.allCases, id: \.rawValue) { font in
                            Text(font.rawValue).tag(font.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("How to Use Interrupt")) {
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(
                            icon: "1.circle.fill",
                            title: "Notice",
                            text: "Catch yourself in a cycle of overthinking, stress, or negative self-talk."
                        )
                        InfoRow(
                            icon: "2.circle.fill",
                            title: "Trigger",
                            text: "Tap the app, Home Screen widget, or Apple Watch complication immediately."
                        )
                        InfoRow(
                            icon: "3.circle.fill",
                            title: "Select",
                            text: "Choose the emotion you are currently experiencing."
                        )
                        InfoRow(
                            icon: "4.circle.fill",
                            title: "Reset",
                            text: "Read the supportive reframe, take a deep breath, and let the thought go."
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Customization Section
                Section(header: Text("Customizing Your Experience")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("• **Add Custom Emotions:** On the main 'Interrupt' screen, scroll to the bottom to add your own specific triggers (e.g., 'Imposter Syndrome').\n\n• **Edit Your List:** Tap 'Edit List' to hide default emotions or delete custom ones.\n\n• **Personalize the Library:** Go to the 'Library' tab to write messages to your 'Future Self' or record 'Proof of Wins' so they appear when you need them most.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Privacy Section
                Section(header: Text("Privacy")) {
                    Text("Your mind is your own. All of your emotional data, trigger logs, and custom notes are stored locally on your device. We do not collect, read, transmit, or sell your personal data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}


struct InfoRow: View {
    let icon: String
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
