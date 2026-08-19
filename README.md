# Interrupt 🛑

> A circuit breaker for your mind. Break negative thought loops in seconds.

**Interrupt** is an iOS + watchOS + widget app designed to help you escape spirals of stress, overthinking, and self-doubt through guided breathing and cognitive reframes.

![Version](https://img.shields.io/badge/version-0.20260819-blue)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B%2C%20watchOS%2011%2B-brightgreen)
![License](https://img.shields.io/badge/license-Proprietary-red)

---

## ✨ Features

### 🚀 **Instant Access**
- **iPhone app** - Full-featured interface with insights dashboard
- **Apple Watch app** - Quick interrupt from your wrist
- **Home Screen widget** - One-tap interrupt for your top emotion
- **Lock Screen widget** - Interrupt without unlocking phone
- **Watch complication** - Interrupt from any watch face

### 🧠 **Smart Interventions**
- **Customizable emotions** - Add your own triggers (Stress, Imposter Syndrome, etc.)
- **Guided breathing** - 10-second breathing with haptic feedback
- **Cognitive reframes** - Research-backed quotes and affirmations
- **Breathing personalization** - Toggle breathing per-emotion, adjust haptic strength

### 📊 **Private Insights**
- **Usage analytics** - See which emotions trigger most, time-of-day patterns
- **No cloud sync** - All data stays on your device (local-only)
- **Export-ready** - InterruptLog data for personal research

### 🎁 **Flexible Content**
- **Core pack** - Free, always available (stress, overthinking, imposter syndrome)
- **Custom notes** - Write your own affirmations and reframes
- **Received quotes** - Accept quotes shared by friends
- **Premium packs** - Optional Stoic philosophy pack ($0.99)
- **Shareable** - Send any quote to friends via URL (purchased or not)

---

## 🎯 How It Works

### The Interrupt Loop
1. **Notice** - Catch yourself in a negative thought pattern
2. **Open** - Tap the app, widget, or watch complication
3. **Select** - Choose the emotion you're experiencing
4. **Reset** - Guided breathing + cognitive reframe pulls you out

**Total time: < 30 seconds**

### Example Workflow
```
I'm overthinking a work presentation
    ↓ (tap watch complication)
"Overthinking" → Guided breathing for 10s
    ↓
Quote appears: "We suffer more often in imagination than in reality. — Seneca"
    ↓
Deep breath. Rational mind restored. Back to work.
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI Framework** | SwiftUI (iOS 17+, watchOS 11+) |
| **Data** | SwiftData + SQLite (local-only) |
| **Sync** | WatchConnectivity |
| **Purchases** | StoreKit 2 |
| **Analytics** | Firebase (Analytics + Crashlytics) |
| **Persistence** | App Group Container (`group.com.mbapps.interrupt`) |

---

## 📱 Platform Support

| Platform | Min Version | Features |
|----------|-------------|----------|
| iOS | 17.0 | Full app, widgets, analytics |
| watchOS | 11.6 | Quick access, breathing, complications |
| tvOS | — | Not supported |
| macOS | — | Not supported (future) |

---

## 🏗️ Project Structure

See [CLAUDE.md](./CLAUDE.md) for complete architecture guide.

**Quick overview:**
```
Interrupt/
├── Interrupt/                 # iOS app (main)
├── Interrupt Watch App/       # watchOS app
├── InterruptWidget/           # Home screen widget
├── Complications/             # Watch complications
├── Shared/                    # Cross-platform models & utilities
│   ├── Models/               # SwiftData models
│   ├── Utilities/            # Shared logic (sync, store, database)
│   ├── DefaultMessages/      # Core quote pack
│   └── PurchaseMessages/     # Premium packs
├── CLAUDE.md                 # Architecture deep-dive
└── README.md                 # This file
```

---

## 🚀 Getting Started (Development)

### Prerequisites
- **Xcode** 15.0+
- **iOS Deployment Target** 17.0+
- **watchOS Deployment Target** 11.6+
- **Apple Developer Account** (for provisioning)

### Setup
1. **Clone** the repository
2. **Open** `Interrupt.xcodeproj` in Xcode
3. **Configure signing** in Xcode (Signing & Capabilities tab)
   - Team ID: `L8A3PF8RFV`
   - Bundle ID: `org.mjbapps.Interrupt`
4. **Enable entitlements**
   - App Groups: `group.com.mbapps.interrupt` (for widget/watch sync)
   - Push Notifications: Yes (for Firebase)
5. **Download GoogleService-Info.plist** from Firebase Console
   - Place in project root (already configured in project.pbxproj)
6. **Build & run** on physical iPhone/Watch (widgets require real device)

### Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create/select your project
3. Download `GoogleService-Info.plist`
4. Ensure `FirebaseCore`, `FirebaseAnalytics`, `FirebaseCrashlytics` are in SPM
5. Check Analytics dashboard for real-time events

---

## 📊 Analytics Events

Interrupt logs the following events to Firebase:

| Event | Parameters | When |
|-------|-----------|------|
| `app_launch` | `version`, `build` | App opens |
| `interrupt_triggered` | `emotion`, `timestamp` | User triggers interrupt (iOS) |
| `watch_interrupt_triggered` | `emotion`, `timestamp` | User triggers interrupt (watch) |
| `purchase_completed` | `pack_id`, `product_id`, `price` | Purchase succeeds |
| `purchase_cancelled` | `pack` | User cancels purchase |
| `purchase_error` | `pack`, `error` | Purchase fails |
| `breathing_toggled` | `emotion`, `enabled` | Breathing setting changed |

View analytics in **Firebase Console** > **Analytics** > **Events**.

---

## 🔒 Privacy & Security

### What We Don't Track
- ❌ Your emotions or triggers (stays local on device)
- ❌ Your interrupt logs (stays local on device)
- ❌ Your custom notes (stays local on device)
- ❌ Any personally identifiable information

### What We Track
- ✅ Which quote pack you purchased (for license verification)
- ✅ Which emotion triggered an interrupt (for insights)
- ✅ App version and build number (for crash analysis)
- ✅ Crashes and errors (via Crashlytics, aggregated only)

**All data is aggregated and never shared with third parties.**

See full privacy policy in Settings app.

---

## 💰 Pricing

| Tier | Price | Includes |
|------|-------|----------|
| **Free** | — | Core pack (stress, overthinking, imposter syndrome), custom notes, analytics |
| **Stoic Pack** | $0.99 | 7 ancient philosophy quotes by Marcus Aurelius, Seneca, Epictetus |

**Note**: All quotes (free or purchased) can be shared with friends for free. We intentionally avoid a paywall on sharing because mental health support shouldn't be gatekept by price.

---

## 🐛 Troubleshooting

### Widget not updating
- **Solution**: Ensure app group entitlement is enabled (`group.com.mbapps.interrupt`)
- **Check**: Widgets settings > `Interrupt` > toggle off/on

### Watch not syncing
- **Solution**: Ensure both devices signed in to same Apple ID
- **Check**: Watch app > Settings > WatchConnectivity is reachable
- **Fallback**: Close watch app and re-open (triggers `transferUserInfo`)

### Purchase not working
- **Solution**: Ensure internet connection and signed into App Store
- **Check**: Settings > [Your Apple ID] > Media & Purchases > Sign out/in
- **Test**: Use TestFlight to test against sandbox environment

### Firebase events not appearing
- **Solution**: Events appear in Firebase Console with ~24 hour delay
- **Check**: App has internet; Firebase is initialized (check console logs)
- **Debug**: Run in Xcode; look for `FirebaseCore` logs

---

## 📞 Support

**Have a question or found a bug?**
- Email: mbrockman1@gmail.com
- File an issue (GitHub)

---

## 📜 License

**Proprietary** - This app is closed-source. All rights reserved to Michael Brockman.

---

## 🙏 Acknowledgments

- **Firebase** - Analytics, crash reporting, authentication
- **SwiftUI** - Modern UI framework
- **SwiftData** - Type-safe local persistence
- **Stoic Philosophers** - Quotes from Marcus Aurelius, Seneca, Epictetus

---

## 🚀 Version History

| Version | Release Date | Highlights |
|---------|--------------|-----------|
| **0.20260819** | Aug 19, 2026 | Firebase integration, analytics logging, architecture docs |
| **0.20260422** | Apr 22, 2026 | StoreKit 2, watch sync, breathing animations |
| **0.20260415** | Apr 15, 2026 | Initial release (iOS + watchOS + widgets) |

---

**Built with ❤️ to help you stay sane.**

*Interrupt is not a substitute for professional mental health care. If you're experiencing a crisis, please contact a mental health professional or emergency services.*
