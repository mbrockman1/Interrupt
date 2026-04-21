import SwiftUI
import SwiftData

struct InterruptView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \EmotionTrigger.name) private var triggers: [EmotionTrigger]
    
    @Binding var pendingEmotion: String?
    
    @State private var activeMessage: InterruptMessage?
    @State private var showingAddTrigger = false
    @State private var newTriggerName = ""
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)
                    
                    Text("What are you ruminating on?")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 12) {
                        ForEach(triggers.filter { isEditing || !$0.isHidden }) { trigger in
                            HStack(spacing: 16) {
                                if isEditing {
                                    Button(action: {
                                        withAnimation {
                                            if trigger.isDefault {
                                                trigger.isHidden.toggle() // Toggles Hide/Unhide
                                                triggerSyncToWatch() // BUG 2 FIX: Sync instantly
                                            } else {
                                                deleteTrigger(trigger)
                                            }
                                        }
                                    }) {
                                        if trigger.isDefault {
                                            Image(systemName: trigger.isHidden ? "eye.fill" : "eye.slash.fill")
                                                .font(.title2)
                                                .foregroundStyle(trigger.isHidden ? .green : .orange)
                                        } else {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                                
                                Button(action: {
                                    if !isEditing && !trigger.isHidden { triggerInterrupt(for: trigger.name) }
                                }) {
                                    Text(trigger.name)
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .foregroundStyle(trigger.isHidden ? Color.secondary : Color.accentColor)
                                        .background(Color.accentColor.opacity(trigger.isHidden ? 0.05 : 0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .disabled(isEditing || trigger.isHidden)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    HStack(spacing: 30) {
                        Button(action: { showingAddTrigger = true }) {
                            Text("+ Add Emotion")
                                .font(.callout).fontWeight(.medium).foregroundStyle(.secondary)
                        }
                        
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(width: 1, height: 16)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isEditing.toggle()
                            }
                        }) {
                            Text(isEditing ? "Done Editing" : "Edit List")
                                .font(.callout).fontWeight(.medium)
                                .foregroundStyle(isEditing ? Color.accentColor : .secondary)
                        }
                    }
                    .padding(.top, 24)
                    Spacer(minLength: 40)
                }
            }
            .fullScreenCover(item: $activeMessage) { msg in
                let needsBreathing = BreathingSettings.shared.isIOSEnabled && BreathingSettings.shared.hasBreathing(for: msg.categoryName)
                
                MessageCardView(message: msg, requiresBreathing: needsBreathing)
            }
            .alert("New Emotion", isPresented: $showingAddTrigger) {
                TextField("E.g., Overwhelmed", text: $newTriggerName)
                Button("Cancel", role: .cancel) { newTriggerName = "" }
                Button("Add") {
                    let trimmed = newTriggerName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        withAnimation {
                            context.insert(EmotionTrigger(name: trimmed))
                            triggerSyncToWatch() // BUG 2 FIX: Sync custom emotions instantly
                        }
                        newTriggerName = ""
                    }
                }
            }
            .onChange(of: pendingEmotion) { _, newValue in
                if let emotionName = newValue {
                    // SAFETY CHECK: Does this emotion still exist and is it active?
                    if triggers.contains(where: { $0.name == emotionName && !$0.isHidden }) {
                        triggerInterrupt(for: emotionName) // We can call this because it's inside this file!
                    } else {
                        print("⚠️ Deep link emotion '\(emotionName)' was deleted or hidden. Defaulting to Main Menu.")
                    }
                    // Reset the trigger so it can fire again next time
                    pendingEmotion = nil
                }
            }
        }
    }
    
    // MARK: - Actions
    
    // Helper to instantly beam the current list to the watch
    private func triggerSyncToWatch() {
            // 1. FORCE THE SAVE FIRST
            // This ensures the current 'isHidden' state is actually on the disk
            try? context.save()
            
            // 2. Fetch the latest state from the disk
            let fetch = FetchDescriptor<EmotionTrigger>()
            if let allTriggers = try? context.fetch(fetch) {
                // 3. Beam the updated list (including the hidden flags)
                WatchSyncManager.shared.syncTriggersToWatch(triggers: allTriggers)
                print("📱 iPhone: Beaming \(allTriggers.count) triggers to watch.")
            }
        }
    
    private func deleteTrigger(_ trigger: EmotionTrigger) {
            let nameToDelete = trigger.name
            
            // 1. Fetch all messages associated with this category name
            let fetchDescriptor = FetchDescriptor<InterruptMessage>()
            if let allMessages = try? context.fetch(fetchDescriptor) {
                let messagesToUnlink = allMessages.filter { $0.categoryName == nameToDelete }
                
                // 2. Disable them and move them to 'Unlinked' instead of deleting them
                for message in messagesToUnlink {
                    message.categoryName = "Unlinked"
                    message.isActive = false
                }
            }
            
            // 3. Delete the trigger itself
            context.delete(trigger)
            
            // 4. Force save and sync the changes to the watch
            triggerSyncToWatch()
        }
    
    private func triggerInterrupt(for categoryName: String) {
        context.insert(InterruptLog(categoryName: categoryName))
        try? context.save()
        let msg = MessageStore.shared.getMessage(for: categoryName, context: context)
        activeMessage = msg
    }
}
