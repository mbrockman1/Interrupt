import SwiftUI
import SwiftData
import LinkPresentation
import StoreKit

struct ContentLibraryView: View {
    @Query(sort: \ContentPack.title) private var allPacks: [ContentPack]
    @Query(sort: \EmotionTrigger.name) private var triggers: [EmotionTrigger]
    @Query private var allMessages: [InterruptMessage]
    @Environment(\.modelContext) private var context
    
    @StateObject private var store = StoreManager.shared 
    
    // Sort so Custom is 1st, Received is 2nd, Core is 3rd, everything else alphabetical
    private var myPacks: [ContentPack] {
        allPacks.filter { $0.isPurchased }.sorted { a, b in
            if a.id == "custom" { return true }
            if b.id == "custom" { return false }
            if a.id == "received" { return true }
            if b.id == "received" { return false }
            if a.id == "core" { return true }
            if b.id == "core" { return false }
            return a.title < b.title
        }
    }
    
    private var storePacks: [ContentPack] {
        allPacks.filter { !$0.isPurchased }.sorted { $0.title < $1.title }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // SECTION 1: MY LIBRARY
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Library")
                            .font(.title2).bold()
                            .padding(.horizontal)
                        
                        ForEach(myPacks) { pack in
                            let packMessages = allMessages.filter { $0.packID == pack.id }
                            let isPackActive = packMessages.contains { $0.isActive }
                            
                            HStack {
                                NavigationLink(destination: PackDetailView(pack: pack, triggers: triggers)) {
                                    PackCardView(pack: pack)
                                }
                                .buttonStyle(.plain)
                                
                                Toggle("", isOn: Binding(
                                    get: { isPackActive },
                                    set: { newValue in
                                        withAnimation {
                                            for msg in packMessages { msg.isActive = newValue }
                                            try? context.save()
                                            syncLibraryToWatch()
                                        }
                                    }
                                ))
                                .labelsHidden()
                                .padding(.trailing, 24)
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }
                    
                    // SECTION 2: DISCOVER (STOREFRONT)
                    if !storePacks.isEmpty {
                        Divider()
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Discover Packs")
                                .font(.title2).bold()
                                .padding(.horizontal)
                            
                            ForEach(storePacks) { pack in
                                NavigationLink(destination: PackDetailView(pack: pack, triggers: triggers)) {
                                    PackCardView(pack: pack)
                                }
                                .buttonStyle(.plain)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
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
    
    private func syncLibraryToWatch() {
        if let messages = try? context.fetch(FetchDescriptor<InterruptMessage>()) {
            WatchSyncManager.shared.syncLibraryToWatch(messages: messages)
        }
    }
}

struct PackCardView: View {
    let pack: ContentPack
    @ObservedObject private var store = StoreManager.shared

    private var product: Product? {
        store.products.first(where: { $0.id == pack.id })
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(pack.isPurchased ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                
                Image(systemName: packIcon)
                    .foregroundStyle(pack.isPurchased ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            .frame(width: 56, height: 56)
            
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
            
            if pack.isPurchased {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if let product {
                Text(product.displayPrice)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .padding(.trailing, 16)
            } else {
                ProgressView()
                    .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 12)
        .padding(.leading, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(pack.isPurchased ? Color.clear : Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var packIcon: String {
        if !pack.isPurchased { return "lock.fill" }
        if pack.id == "custom" { return "square.and.pencil" }
        if pack.id == "received" { return "face.smiling.fill" }
        if pack.id == "core" { return "heart.text.square.fill" }
        return "checkmark.circle.fill"
    }
}

struct PackDetailView: View {
    let pack: ContentPack
    let triggers: [EmotionTrigger]
    @Environment(\.modelContext) private var context
    @Query private var allMessages: [InterruptMessage]
    @ObservedObject private var store = StoreManager.shared

    @State private var showingAddSheet = false
    @State private var messageToEdit: InterruptMessage?
    
    // Check if the user owns this pack
    private var isPreviewMode: Bool { !pack.isPurchased }
    
    var body: some View {
        List {
            // PROMINENT UNLOCK BUTTON FOR PREVIEW MODE
            if isPreviewMode {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Text("Preview Mode")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                        
                        Text("You can read the contents of this pack for free. To use these quotes in your active Interrupts, unlock the pack.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            Task {
                                // 1. Find the Apple Product matching this Pack (retry the fetch if it hasn't loaded yet)
                                var product = store.products.first(where: { $0.id == pack.id })
                                if product == nil {
                                    await store.fetchProducts()
                                    product = store.products.first(where: { $0.id == pack.id })
                                }

                                if let product {
                                    // 2. Trigger the Apple Pay Sheet!
                                    await store.purchase(product, pack: pack, context: context)
                                } else {
                                    store.purchaseErrorMessage = "Couldn't reach the App Store. Check your connection and try again."
                                }
                            }
                        }) {
                            Group {
                                if store.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Unlock Pack")
                                        .font(.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isPurchasing)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            let packMessages = allMessages.filter { $0.packID == pack.id }
            let unlinkedMessages = packMessages.filter { $0.categoryName == "Unlinked" }
            
            ForEach(triggers) { trigger in
                let triggerMessages = packMessages.filter { $0.categoryName == trigger.name }
                if !triggerMessages.isEmpty {
                    Section(header: Text(trigger.name)) {
                        ForEach(triggerMessages) { msg in
                            PackMessageRow(msg: msg, isPreviewMode: isPreviewMode)
                                .contentShape(Rectangle()) // Makes the whole row tappable
                                .onTapGesture {
                                    if !isPreviewMode { messageToEdit = msg }
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                context.delete(triggerMessages[index])
                            }
                            try? context.save()
                            syncLibraryToWatch()
                        }
                        // Disables swipe-to-delete completely in Preview mode!
                        .deleteDisabled(pack.id != "custom" && pack.id != "received")
                    }
                }
            }
            
            if !unlinkedMessages.isEmpty {
                Section(header: Text("Unlinked"), footer: Text("Tap a message to reassign it to an active emotion.")) {
                    ForEach(unlinkedMessages) { msg in
                        // FIXED: Removed Button and used onTapGesture so swiping works!
                        PackMessageRow(msg: msg, isPreviewMode: isPreviewMode)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                messageToEdit = msg
                            }
                    }
                    // FIXED: Added the onDelete block so Custom/Received notes can actually be deleted from here
                    .onDelete { indexSet in
                        for index in indexSet {
                            context.delete(unlinkedMessages[index])
                        }
                        try? context.save()
                        syncLibraryToWatch()
                    }
                    // Safely disables deleting if it's a Core/Premium pack
                    .deleteDisabled(pack.id != "custom" && pack.id != "received")
                }
            }
        }
        .navigationTitle(pack.title)
        .alert("Purchase Issue", isPresented: Binding(
            get: { store.purchaseErrorMessage != nil },
            set: { isPresented in if !isPresented { store.purchaseErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.purchaseErrorMessage ?? "")
        }
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
    let isPreviewMode: Bool
    @Environment(\.modelContext) private var context
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.text)
                    .font(.body)
                    // If in preview mode, it always looks 'primary' so it's easy to read
                    .foregroundStyle((msg.isActive || isPreviewMode) ? .primary : .secondary)
                    .strikethrough(!msg.isActive && !isPreviewMode)
                
                Text(msg.typeRaw)
                    .font(.caption2).bold()
                    .foregroundStyle(Color.accentColor)
            }
            Spacer()
            
            // Hides the active/inactive toggle if they haven't bought it yet
            if !isPreviewMode {
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
                // FIXED 3: The Share button ONLY appears for Custom or Received notes!
                ToolbarItem(placement: .topBarTrailing) {
                    if message.packID == "custom" || message.packID == "received" {
                        if let shareURL = ShareHelper.createShareURL(for: message) {
                            
                            let shareText = """
                            A note for \(message.categoryName):
                            
                            "\(message.text)"
                            
                            Tap to save to your Interrupt app:
                            \(shareURL.absoluteString)
                            """
                            
                            ShareLink(
                                item: shareText,
                                preview: SharePreview("Interrupt Note", image: Image("WidgetIcon"))
                            ) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
                
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
