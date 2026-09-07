# Interrupt App - Architecture & Development Guide

**Version:** 0.20260907  
**Last Updated:** September 7, 2026  
**Developer:** Michael Brockman

---

## 🎯 Product Overview

**Interrupt** is a multi-platform mental health intervention app designed to help users break cycles of rumination through guided breathing, cognitive reframes, and community-shared wisdom.

### Core Value Proposition
- **Fast**: Interrupt a negative thought loop in <10 seconds
- **Accessible**: Available on iPhone, Apple Watch, Lock Screen, Home Screen
- **Ethical**: Free core experience with optional premium quote packs; all purchased quotes can be shared freely
- **Private**: All data stored locally on device; no cloud sync of personal triggers/logs

### Key Features
1. **Emotion Triggers** - Customizable list of negative thought patterns (Stress, Overthinking, Imposter Syndrome, etc.)
2. **Quick Interrupt** - Tap an emotion → guided 10-second breathing → cognitive reframe
3. **Multi-Platform Widgets** - Home screen widget, lock screen widget, Apple Watch complication
4. **Analytics Insights** - Track which emotions triggered most, time-of-day patterns
5. **Quote Packs** - Core free pack + purchasable premium packs
6. **Share Quotes** - Send custom or received quotes to friends via URL scheme
7. **Guided Breathing** - Haptic-enabled breathing guidance (customizable per emotion)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ iOS App (Main)                                              │
│  - ContentView (Tab Navigation)                             │
│  - InterruptView (Emotion selection)                        │
│  - ContentLibraryView (Quote packs & management)            │
│  - AnalyticsView (Insights & charts)                        │
│  - SettingsView (Config & breathing)                        │
└─────────────────────────────────────────────────────────────┘
                            ↕ WatchConnectivity
┌─────────────────────────────────────────────────────────────┐
│ watchOS App                                                 │
│  - WatchContentView (Emotion list)                          │
│  - WatchMessageCardView (Breathing & reframe)               │
│  - Watch Complication (Quick access)                        │
└─────────────────────────────────────────────────────────────┘
            ↕
┌─────────────────────────────────────────────────────────────┐
│ Home Screen Widget + Lock Screen Widgets                    │
│  - Quick one-tap interrupt for selected emotion             │
└─────────────────────────────────────────────────────────────┘
            ↕
┌─────────────────────────────────────────────────────────────┐
│ Shared Data Layer (SwiftData + App Groups)                 │
│  - Models: EmotionTrigger, InterruptMessage, InterruptLog  │
│  - Database: SQLite in app group container                 │
│  - UserDefaults: Shared settings between targets            │
└─────────────────────────────────────────────────────────────┘
            ↕
┌─────────────────────────────────────────────────────────────┐
│ Firebase (Analytics & Crash Reporting)                      │
│  - Events: app_launch, interrupt_triggered, purchase_*      │
│  - Crashlytics: Automatic crash collection                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Project Structure

```
Interrupt/
├── Interrupt/                          # iOS App Target
│   ├── InterruptApp.swift             # App entry point (Firebase init)
│   ├── ContentView.swift              # Main tab navigation
│   ├── Views/
│   │   ├── InterruptView.swift        # Emotion selection & quick interrupt
│   │   ├── ContentLibraryView.swift   # Quote pack management (2x largest file)
│   │   ├── AnalyticsView.swift        # Insights dashboard
│   │   ├── SettingsView.swift         # Config & breathing settings
│   │   └── OnboardingView.swift       # First-launch guide
│   └── Assets.xcassets
│
├── Interrupt Watch App/                # watchOS App Target
│   ├── InterruptApp.swift             # Watch app entry point
│   ├── ContentView.swift              # Emotion list for watch
│   ├── Views/
│   │   └── WatchMessageCardView.swift # Breathing + reframe animation
│   └── Assets.xcassets
│
├── InterruptWidget/                    # Home Screen Widget Target
│   └── InterruptWidget.swift          # Quick interrupt widget (iOS 17+)
│
├── Complications/                      # Watch Complication Target
│   └── Complications.swift            # Quick interrupt complication
│
├── Shared/                             # Cross-platform code
│   ├── Models/
│   │   ├── SharedModels.swift         # Data models (EmotionTrigger, ContentPack, etc.)
│   │   └── SeedManager.swift          # Database initialization
│   ├── Utilities/
│   │   ├── DatabaseHelper.swift       # SwiftData container setup
│   │   ├── MessageStore.swift         # Random message fetcher + fallbacks
│   │   ├── WatchSyncManager.swift     # WatchConnectivity sync
│   │   ├── StoreManager.swift         # StoreKit 2 purchases
│   │   ├── ShareHelper.swift          # URL scheme encoding/decoding
│   │   ├── BreathingSettings.swift    # Breathing config + UserDefaults
│   │   └── MessageCardView.swift      # Reusable breathing animation
│   ├── DefaultMessages/               # Core quote pack
│   │   ├── StressMessages.swift
│   │   ├── OverthinkingMessages.swift
│   │   └── ImposterSyndromeMessages.swift
│   └── PurchaseMessages/              # Premium quote pack
│       └── StoicMessages.swift
│
├── GoogleService-Info.plist           # Firebase config
├── InterruptStore.storekit            # StoreKit 2 product definitions
├── CLAUDE.md                          # This file
└── Interrupt.xcodeproj/               # Xcode project
```

---

## 🔑 Key Design Patterns

### 1. **Shared Data via App Groups**
All targets (iOS app, watch app, widgets, complications) share a single SQLite database via `group.com.mbapps.interrupt` app group container.

```swift
// DatabaseHelper.swift
let appGroupID = "group.com.mbapps.interrupt"
let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    .appendingPathComponent("Interrupt.sqlite")
```

**Why**: Ensures consistency across all UI surfaces without cloud sync.

### 2. **WatchConnectivity Sync**
iPhone-Watch sync via `WatchConnectivity` framework with fallback to `transferUserInfo()`:

- **Reachable**: Use `sendMessage()` (instant)
- **Not Reachable**: Use `transferUserInfo()` (delivers when watch wakes)

Syncs:
- Emotion triggers (visible/hidden state)
- Message library (active/inactive state)
- Breathing settings (which emotions need breathing)

### 3. **Analytics-First Design**
All user actions log to Firebase Analytics:
- App launch
- Interrupt triggered (by emotion)
- Purchase completed/cancelled/failed
- Breathing toggled
- Settings changed

```swift
Analytics.logEvent("interrupt_triggered", parameters: [
    "emotion": categoryName,
    "timestamp": Date().timeIntervalSince1970
])
```

### 4. **Three-Phase Breathing UX**
1. **Countdown (3-2-1)** - Prepares mind
2. **Breathing (Inhale/Exhale)** - Guided 10 seconds, haptic pulses
3. **Quote** - Display cognitive reframe

Controlled via `currentPhase` state machine in `MessageCardView.swift`.

### 5. **Quote Pack System**
- **Core Pack** (`"core"`) - Free, always available
- **Custom Pack** (`"custom"`) - User-created notes
- **Received Pack** (`"received"`) - Quotes shared by friends
- **Premium Packs** (`"pack.stoic"`, etc.) - StoreKit products

Packs are gated by `ContentPack.isPurchased` flag.

### 6. **Error Logging Pattern**
Always log both locally and to Firebase:

```swift
do {
    try context.save()
} catch {
    print("❌ Save failed: \(error)")
    Analytics.logEvent("save_error", parameters: ["error": error.localizedDescription])
}
```

---

## 🚀 Critical Systems

### Database Schema (SwiftData)
```swift
@Model final class EmotionTrigger {
    @Attribute(.unique) var id: UUID
    var name: String              // e.g., "Stress", "Overthinking"
    var isDefault: Bool           // Can't delete default triggers
    var isHidden: Bool            // User can hide without deleting
}

@Model final class InterruptMessage {
    var id: UUID
    var text: String              // The cognitive reframe
    var typeRaw: String           // "Affirmation", "Quote", "Future Self", "Proof of Win"
    var categoryName: String      // Which emotion triggers this
    var packID: String            // Which pack owns this message
    var isActive: Bool            // User can toggle messages on/off
}

@Model final class InterruptLog {
    var id: UUID
    var timestamp: Date           // When was interrupt triggered
    var categoryName: String      // Which emotion was interrupted
}

@Model final class ContentPack {
    @Attribute(.unique) var id: String  // StoreKit product ID
    var title: String
    var subtitle: String
    var isPurchased: Bool         // StoreKit verification
    var isPremium: Bool           // Purchasable pack vs. free
}
```

### Firebase Integration
**Current State (v0.20260820):**
- ✅ FirebaseCore + FirebaseCrashlytics only, in the main `Interrupt` iOS target
- ✅ `FirebaseApp.configure()` + Crashlytics collection enabled in the iOS app `init()`
- ❌ **FirebaseAnalytics is intentionally NOT included.** As of firebase-ios-sdk 12.17.0, the SPM
  `FirebaseAnalytics` product unconditionally links `GoogleAppMeasurementIdentitySupport`, which
  references `ATTrackingManager` — there is no working SPM product in this SDK version that provides
  `Analytics.logEvent()` without shipping that reference (`FirebaseAnalyticsWithoutAdIdSupport` no
  longer exists; `FirebaseAnalyticsCore` exists but is missing the actual `FIRAnalytics` symbols and
  fails to link). App Store Connect's automated privacy check does not accept "ship the ATT-capable
  code but declare no tracking" — it requires either declaring Tracking=Yes (not true for this app) or
  the binary to genuinely not reference ATT. Verified at the binary level (otool/nm/strings on the
  actual built app) that with FirebaseAnalytics removed, zero `ATTrackingManager` references and zero
  `AdSupport`/`AppTrackingTransparency` framework linkage remain anywhere in the shipped bundle, and
  `NSUserTrackingUsageDescription` is absent from Info.plist. In App Store Connect, App Privacy should
  be answered "Data Not Used to Track You."
- **Tradeoff accepted**: no `interrupt_triggered` / `purchase_completed` / `breathing_toggled` custom
  event analytics. Crash reporting (Crashlytics) still fully works. If product analytics are wanted
  later, re-adding FirebaseAnalytics means re-accepting the ATT flag — there's no way around it in
  this SDK line without pinning to a much older, unsupported firebase-ios-sdk version.

**Next Steps (Future Releases):**
- [ ] Custom user properties (free vs. premium, usage tier)
- [ ] Funnel analysis (free → purchase conversion)
- [ ] A/B testing for quote effectiveness
- [ ] Remote config for feature flags

### StoreKit 2 Setup
Products defined in `InterruptStore.storekit`:
- `pack.stoic` - Premium Stoic philosophy quotes ($0.99)

Purchase flow:
1. User taps "Unlock Pack"
2. `StoreManager.purchase()` triggers Apple Pay
3. On success: unlock in database, sync to watch, log to Firebase
4. Purchase is persistent across app reinstalls (StoreKit handles this)

---

## 📱 Multi-Platform Considerations

### iOS App
- Full-featured, primary UI
- Handles purchase flow
- Sends sync messages to watch
- Receives logs from watch

### watchOS App
- Lightweight, quick-access UI
- Read-only quote access (limited by watch memory)
- Sends interrupt logs back to iPhone
- Watches for sync messages from iPhone

### Home Screen Widget
- Configured via `InterruptIntent` (App Intents API)
- Displays configurable emotion shortcut
- Deep-links to main app: `interrupt://trigger?emotion=Stress`
- Falls back to hardcoded defaults if database locked

### Watch Complication
- Similar to widget but optimized for small watch face
- Circular + rectangular layouts
- Same deep-link behavior

---

## 🔄 Data Flow Diagrams

### Interrupt Triggered (iOS)
```
User Taps Emotion
    ↓
InterruptView.triggerInterrupt()
    ├→ Insert InterruptLog (timestamp + category)
    ├→ Save to SwiftData
    ├→ Log to Firebase Analytics
    ├→ Fetch random message from pack
    └→ Show MessageCardView (breathing + quote)
        ↓
    WatchSyncManager.syncLibraryToWatch()
        └→ Send library state to watch
```

### Interrupt Triggered (Watch)
```
User Taps Emotion
    ↓
WatchContentView.triggerInterrupt()
    ├→ Insert InterruptLog locally (backup)
    ├→ Log to Firebase Analytics
    ├→ Send log to iPhone via WatchConnectivity
    ├→ Fetch random message from watch's local copy
    └→ Show WatchMessageCardView (breathing + quote)
        ↓
    iPhone Receives Log
        └→ Insert InterruptLog with exact timestamp
           (for accurate time-of-day analytics)
```

### Purchase Flow
```
User Taps "Unlock Pack"
    ↓
StoreManager.purchase(product, pack, context)
    ├→ Trigger Apple Pay
    ├→ Verify transaction signature
    ├→ Unlock pack in SwiftData
    ├→ Log "purchase_completed" to Firebase
    ├→ Sync library to watch
    └→ Update UI (show content)
```

### Settings Sync to Watch
```
User Toggles "Breathing on iPhone"
    ↓
BreathingSettings.toggleBreathing(emotion)
    ├→ Update UserDefaults (shared app group)
    ├→ Log "breathing_toggled" to Firebase
    └→ BreathingSettings.syncToWatch()
        └→ Send breathing_settings dict via WatchConnectivity
            ↓
        Watch Receives Settings
            └→ Update local UserDefaults
               (used by WatchMessageCardView)
```

---

## 🐛 Known Issues & Workarounds

### Issue 1: Widget Database Locking
**Problem**: If iPhone app is writing to database, widget can't read.  
**Solution**: Widget uses `allowsSave: false` in `ModelConfiguration`.  
**Behavior**: Widget displays cached emotion list from widget complication options provider.

### Issue 2: Watch Complication Outdated Emotions
**Problem**: Complication might show stale emotions if phone not recently synced.  
**Solution**: Save emotion list to `UserDefaults` key `"WidgetEmotions"` on watch; complication reads from UserDefaults, not database.

### Issue 3: WatchConnectivity Message Loss
**Problem**: `sendMessage()` fails if watch unreachable; message is silently dropped.  
**Solution**: Use `transferUserInfo()` as fallback; watch receives it on next wake.

---

## ✅ Testing Checklist

### Before Each Release
- [ ] Trigger interrupt on iOS app (all 3+ emotions)
- [ ] Trigger interrupt on watch (all 3+ emotions)
- [ ] Toggle breathing on/off for each emotion
- [ ] Verify breathing animation plays correctly
- [ ] Test widget on home screen (tapping emotion)
- [ ] Test watch complication (tapping emotion)
- [ ] Check Firebase Analytics dashboard (events logged)
- [ ] Test purchase flow (if testing against sandbox)
- [ ] Share a quote via URL and accept it on another device
- [ ] Check AnalyticsView shows correct log counts
- [ ] Rotate phone and verify UI adapts

### After Major Changes
- [ ] Full clean build (`Cmd+Shift+K`)
- [ ] Archive for distribution
- [ ] Verify app groups entitlements match
- [ ] Check Firebase config is deployed

---

## 📋 Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.20260907 | Sep 7, 2026 | Fixed the quote-pack purchase flow: auto-restore entitlements on launch (reinstalls/new devices no longer require a manual "Restore Purchases" tap); pack cards now show the real StoreKit price instead of a hardcoded "Free" label; fixed the sandbox `.storekit` price ($0.00 → $0.99); retagged an orphaned Stoic quote's category so all 7 premium quotes are reachable; purchase failures/pending states now surface an alert instead of failing silently; added a Ko-fi support link in Settings |
| 0.20260820 | Aug 20, 2026 | Verified full clean build (all 4 targets) for the first time; fixed missing `import WatchKit` in 2 Watch App files (pre-existing bug); removed FirebaseAnalytics entirely (kept Crashlytics only) after confirming App Store Connect's tracking-permission check requires zero ATT-referencing code in the binary, not just an honest usage string — verified zero `ATTrackingManager` references at the binary level after removal; fixed Decimal→Double price bug |
| 0.20260819 | Aug 19, 2026 | Firebase initialization, analytics logging, dead code cleanup |
| 0.20260422 | Apr 22, 2026 | Purchase system, watch sync, breathing animations |
| 0.20260415 | Apr 15, 2026 | Initial multi-platform release |

---

## 🚀 Future Roadmap

### Phase 2 (Fall 2026)
- [ ] Imposter Syndrome premium pack
- [ ] Emotion statistics (pie chart by category)
- [ ] Favorite quotes bookmarking
- [ ] Watch-only app (no iPhone required)

### Phase 3 (2027)
- [ ] CloudKit sync for quotes across devices
- [ ] iCloud backup of custom notes
- [ ] Family Sharing for premium packs
- [ ] Siri Shortcuts integration

### Phase 4 (Long-term)
- [ ] Android version (Flutter/Compose)
- [ ] Web dashboard for analytics
- [ ] Community quote submissions
- [ ] Mental health provider integrations

---

## 📞 Support & Contact

**Developer**: Michael Brockman  
**Email**: mbrockman1@gmail.com  
**GitHub**: See `Interrupt.xcodeproj` for repository setup

---

**Last Reviewed**: September 7, 2026  
**Next Review Due**: December 2026
