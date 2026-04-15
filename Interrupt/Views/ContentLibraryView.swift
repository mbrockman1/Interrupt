import SwiftUI
import SwiftData

struct ContentLibraryView: View {
    @Query private var allPacks: [ContentPack]
    @Query(sort: \EmotionTrigger.name) private var triggers: [EmotionTrigger]
    @Query private var allMessages: [InterruptMessage]
    @Environment(\.modelContext) private var context
    
    // Separate purchased from unpurchased packs with custom sorting
    private var purchasedPacks: [ContentPack] { 
        allPacks.filter { $0.isPurchased }
            .sorted { pack1, pack2 in
                // Always put "custom" (My Custom Notes) first
                if pack1.id == "custom" { return true }
                if pack2.id == "custom" { return false }
                // Then sort alphabetically by title
                return pack1.title < pack2.title
            }
    }
    private var availableForPurchase: [ContentPack] { 
        allPacks.filter { !$0.isPurchased }
            .sorted { $0.title < $1.title }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // SECTION 1: My Library (Purchased Packs)
                    if !purchasedPacks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Library")
                                .font(.title2).bold()
                                .padding(.horizontal)
                            
                            ForEach(purchasedPacks) { pack in
                                NavigationLink(destination: PackDetailView(pack: pack, triggers: triggers)) {
                                    PackCardView(pack: pack)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // DIVIDER between sections
                    if !purchasedPacks.isEmpty && !availableForPurchase.isEmpty {
                        Divider()
                            .padding(.horizontal)
                    }
                    
                    // SECTION 2: Available Packs (Purchasable)
                    if !availableForPurchase.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Packs")
                                .font(.title2).bold()
                                .padding(.horizontal)
                            
                            Text("Premium content coming soon")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(availableForPurchase) { pack in
                                Button(action: { 
                                    // TODO: Trigger StoreKit Purchase
                                    purchasePack(pack)
                                }) {
                                    PackCardView(pack: pack)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Library")
        }
    }
    
    private func purchasePack(_ pack: ContentPack) {
        // TODO: Integrate StoreKit here
        // For now, just mark as purchased for testing
        pack.isPurchased = true
        try? context.save()
        syncLibraryToWatch()
    }
    
    private func syncLibraryToWatch() {
        if let messages = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
            WatchSyncManager.shared.syncLibraryToWatch(messages: messages)
        }
    }
}

// MARK: - Pack Card Component
struct PackCardView: View {
    let pack: ContentPack
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon based on pack status
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(pack.isPurchased ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                
                if pack.isPurchased {
                    if pack.id == "custom" {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }
            .frame(width: 56, height: 56)
            
            // Pack info
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.title)
                    .font(.headline)
                    .foregroundStyle(pack.isPurchased ? .primary : .secondary)
                
                Text(pack.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Trailing icon
            if pack.isPurchased {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                // Show "Get" button for unpurchased packs
                Text("Get")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(pack.isPurchased ? Color.clear : Color.accentColor.opacity(0.3), lineWidth: 1)
                .padding(.horizontal)
        )
    }
}

// MARK: - Drilled Down Pack View
struct PackDetailView: View {
    let pack: ContentPack
    let triggers: [EmotionTrigger]
    @Environment(\.modelContext) private var context
    @Query private var allMessages: [InterruptMessage]
    
    @State private var showingAddSheet = false
    @State private var messageToEdit: InterruptMessage?
    
    var body: some View {
        List {
            let packMessages = allMessages.filter { $0.packID == pack.id }
            let unlinkedMessages = packMessages.filter { $0.categoryName == "Unlinked" }
            
            // 1. Standard Triggers
            ForEach(triggers) { trigger in
                let triggerMessages = packMessages.filter { $0.categoryName == trigger.name }
                if !triggerMessages.isEmpty {
                    Section(header: Text(trigger.name)) {
                        ForEach(triggerMessages) { msg in
                            Button(action: { messageToEdit = msg }) {
                                PackMessageRow(msg: msg)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let msg = triggerMessages[index]
                                if msg.packID == "custom" {
                                    // Custom notes are permanently deleted
                                    context.delete(msg)
                                } else {
                                    // Pack notes are protected: move to unlinked and disable
                                    msg.categoryName = "Unlinked"
                                    msg.isActive = false
                                }
                            }
                            try? context.save()
                            syncLibraryToWatch()
                        }
                    }
                }
            }
            
            // 2. The "Unlinked" Section
            if !unlinkedMessages.isEmpty {
                Section(header: Text("Unlinked"), footer: Text("Tap a message to reassign it to an active emotion. Built-in pack messages cannot be permanently deleted.")) {
                    ForEach(unlinkedMessages) { msg in
                        Button(action: { messageToEdit = msg }) {
                            PackMessageRow(msg: msg)
                        }
                        .buttonStyle(.plain)
                        // MAGIC: Disables the swipe-to-delete gesture for Pack quotes!
                        .deleteDisabled(msg.packID != "custom")
                    }
                    .onDelete { indexSet in
                        // This will only ever trigger for custom notes because of deleteDisabled above
                        for index in indexSet {
                            context.delete(unlinkedMessages[index])
                        }
                        try? context.save()
                        syncLibraryToWatch()
                    }
                }
            }
        }
        .navigationTitle(pack.title)
        .toolbar {
            if pack.id == "custom" {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMessageView(triggers: triggers.filter { !$0.isHidden })
        }
        .sheet(item: $messageToEdit) { msg in
            EditMessageView(message: msg, triggers: triggers.filter { !$0.isHidden })
        }
    }
    
    private func syncLibraryToWatch() {
        if let messages = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
            WatchSyncManager.shared.syncLibraryToWatch(messages: messages)
        }
    }
}

// MARK: - Message Row
struct PackMessageRow: View {
    @Bindable var msg: InterruptMessage
    @Environment(\.modelContext) private var context
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.text)
                    .font(.body)
                    .foregroundStyle(msg.isActive ? .primary : .secondary)
                    .strikethrough(!msg.isActive)
                
                Text(msg.typeRaw)
                    .font(.caption2).bold()
                    .foregroundStyle(Color.accentColor)
            }
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { msg.isActive },
                set: { newValue in
                    msg.isActive = newValue
                    try? context.save()
                    syncLibraryToWatch()
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
    
    private func syncLibraryToWatch() {
        if let messages = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
            WatchSyncManager.shared.syncLibraryToWatch(messages: messages)
        }
    }
}

// MARK: - Add Message View
struct AddMessageView: View {
    let triggers: [EmotionTrigger]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var text = ""
    @State private var selectedType = "Affirmation"
    @State private var selectedCategory = "" // Starts empty, fixed in onAppear
    
    let types = ["Affirmation", "Quote", "Future Self", "Proof of Win"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Message Content") {
                    TextField("Type your message here...", text: $text, axis: .vertical)
                        .lineLimit(4...10)
                }
                Section("Settings") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { Text($0) }
                    }
                    Picker("Emotion", selection: $selectedCategory) {
                        ForEach(triggers) { trigger in
                            Text(trigger.name).tag(trigger.name)
                        }
                    }
                }
            }
            .navigationTitle("Add to Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newMessage = InterruptMessage(text: text, typeRaw: selectedType, categoryName: selectedCategory, packID: "custom")
                        context.insert(newMessage)
                        try? context.save()
                        
                        if let all = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
                            WatchSyncManager.shared.syncLibraryToWatch(messages: all)
                        }
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
            .onAppear {
                // FIXED: Default to the first available emotion so it's never blank
                if selectedCategory.isEmpty {
                    selectedCategory = triggers.first?.name ?? "Stress"
                }
            }
        }
    }
}

// MARK: - Edit Message View
// MARK: - Edit Message View
struct EditMessageView: View {
    @Bindable var message: InterruptMessage
    let triggers: [EmotionTrigger]
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let types = ["Affirmation", "Quote", "Future Self", "Proof of Win"]
    
    var body: some View {
        NavigationStack {
            Form {
                if message.packID == "custom" {
                    Section("Edit Content") {
                        TextField("Text", text: $message.text, axis: .vertical)
                            .lineLimit(4...10)
                    }
                    Section("Type") {
                        Picker("Type", selection: $message.typeRaw) {
                            ForEach(types, id: \.self) { Text($0) }
                        }
                    }
                } else {
                    Section(header: Text("Content (Locked by Pack)"), footer: Text("You cannot edit the text of built-in pack quotes, but you can change which emotion triggers them.")) {
                        Text(message.text)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Associated Emotion") {
                    Picker("Emotion", selection: $message.categoryName) {
                        // ALWAYS show this option so users can manually Unlink quotes
                        Text("Unassigned (Unlinked)").tag("Unlinked")
                        
                        ForEach(triggers) { trigger in
                            Text(trigger.name).tag(trigger.name)
                        }
                    }
                    .onChange(of: message.categoryName) { _, newValue in
                        // Automatically toggle off if they move it to Unlinked
                        if newValue == "Unlinked" {
                            message.isActive = false
                        }
                    }
                }
            }
            .navigationTitle(message.packID == "custom" ? "Edit Note" : "Reassign Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        if let all = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
                            WatchSyncManager.shared.syncLibraryToWatch(messages: all)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
