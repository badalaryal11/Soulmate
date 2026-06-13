# Changelog

## [18.0.0] - 2026-06-13

### 🔑 Authentication
* **Google Sign-In Fix:** Resolved a `PlatformException` on Android caused by a hardcoded `serverClientId` conflicting with auto-detected configuration from `google-services.json`.
* **OAuth Scopes:** Added explicit `email` and `profile` scopes to the Google Sign-In configuration for reliable user data retrieval.

***

## [17.0.1] - 2026-06-12

### 📄 Branding & Styling
* **Privacy Policy Branding:** Redesigned the external privacy policy webpage with the official custom logo, favicon, and cursive `Lobster` font styling to match the Soulmate brand.

### 🤖 Android SDK & Immersive UI
* **Android SDK Upgrade:** Bumped compile and target SDK versions to API 36.
* **Edge-to-Edge Display:** Enabled native edge-to-edge layouts in `MainActivity` for a modern, bezel-less visual experience.
* **MainActivity Refactoring:** Updated `MainActivity` to extend `FlutterFragmentActivity` to provide enhanced support compatibility.

***

## [17.0.0] - 2026-06-12

### 💬 Multilingual AI Chat
* **Language-Aware Conversations:** Configured the AI matching partner to automatically detect and respond in the same language or dialect that the user is currently using, ensuring full multilingual support (Spanish, French, Nepali, Hindi, Japanese, etc.) without losing persona consistency.

***

## [16.0.0] - 2026-06-08

### 🎨 Visuals & UI
* **Glassmorphic Login**: Redesigned the authentication screen with a modern, premium glassmorphic layout.
* **Profile Rendering**: Optimized profile card image rendering and gradient overlays for smoother swiping.

### 🔑 Authentication
* **Sign-In Reliability**: Resolved a production bug (Error 12500) by enabling the required People API for Google Sign-In.
* **Error Handling**: Implemented specific error code parsing for clearer, user-friendly authentication failure messages.

### ⚙️ Under-the-Hood
* **Kotlin DSL Migration**: Migrated Android build scripts (`build.gradle`) from Groovy to Kotlin DSL for improved build maintainability.

***

## [15.0.0] - 2026-06-04

### 🎨 Visuals & Styling
* **Edge-to-Edge Support**: Enabled native edge-to-edge rendering in MainActivity for a bezel-less visual experience.
* **UI & Typography Consistency**: Consolidated screen titles and text styles across the app using centralized theme tokens.

### 🔑 Authentication
* **Google Sign-In**: Corrected server client ID settings for authentication.
* **Login Flow**: Defer login timestamp update asynchronously, avoiding UI-blocking, and removed redundant pre-signout triggers.

### ❤️ Matching & Chat
* **Age Filter Persistence**: Enabled local persistence of user age filtering configuration.
* **Dynamic Matching**: Integrated dynamic swipe thresholds for enhanced matching probability.
* **Streamlined Chat**: Implemented message collapsing logic for consecutive chat bubbles and resolved stream control thread safety.

### ⚡ Performance & Maintenance
* **Gradle Performance**: Activated parallel execution, daemon, and build caching for faster compiler speeds.
* **Startup Boost**: Postponed local notification initialization until post-mount to secure instantaneous startup.

***

## [14.0.0] - 2026-03-24

### 🚀 Performance & System Optimizations
* **API Connection Pooling**: Integrated a high-performance HTTP client for handling `RandomUser API` requests, drastically dropping transport latency by keeping TLS connections alive.
* **Invisible Caching**: Engineered a robust memory queue for the Discovery Deck. The application now silently fetches and prepares new card candidates in the background while you swipe.
* **Image Compression**: Automatically compresses local profile photos locally (to 800x800 at 70% quality) before pushing them to Firebase Storage. This heavily saves bandwidth costs and improves profile loading times across the application.
* **Memory Leaks Eliminated**: Overrode critical disposal logic within `LoginProvider` to halt background UI rebuild attempts (`notifyListeners()`) after a user navigates away from the login screen during an active authentication handshake.

### ❤️ Matching Algorithm Update
* **Interest Synergy**: The Discovery Deck candidate filter has been tightened. If the logged-in user has selected interests, candidate cards will *only* be presented if they share at least one mutual interest.

***
## [13.0.0] - 2026-02-26

### 🛡️ Security & Validation Improvements
* **Data Integrity**: Implemented robust Firestore cross-validation for chat messages.
* **Account Security**: Enforced email verification requirements and added secure session wiping capabilities.
* **Compliance**: Added a proprietary `LICENSE` file. Updated `SECURITY.md` with guidelines on supported versions and vulnerability reporting.

### 🚀 Performance & System Optimizations
* **Crash Prevention**: Drastically lowered the global image cache size limit (`maximumSizeBytes`) to prevent out-of-memory (OOM) crashes on older mobile devices.
* **Memory Leaks**: Fixed a critical memory leak in the database service by safely closing chat stream controllers when a chat is deleted.
* **Architecture Stress Tests**: Engineered an aggressive load-testing suite proving the state provider (`UserProvider`) can process 5000+ profiles and rapid swipe interactions in milliseconds without freezing the interface.

### 📝 Documentation
* **Comprehensive Detailing**: Exhaustively updated the `README.md` to showcase Soulmate's modern tech stack features, AI components, Gamification integration, and Performance metrics.

***

## [12.0.0] - 2026-02-26

### 🎉 New Features
* **Dedicated Profile Tab:** A new "Profile" tab has been added to the main navigation bar, centralizing your profile picture, bio, interests, and general account settings in one beautifully organized space.
* **Local Image Storage:** Taking control of your privacy and performance, photos you upload from your device gallery are now saved natively on your device rather than pushed to Firebase cloud storage.
* **Centralized Image Handling:** Restructured how images render globally across the app to seamlessly and intelligently load high-speed local images alongside online network avatars perfectly.

***

## [11.0.0] - 2026-02-25

### 🛡️ Critical Security & Privacy Enhancements
* **Ironclad Database Protection:** We have significantly hardened the cloud database rules. Chat histories are now strictly locked down so that only verified participants of a specific conversation can read or send messages, completely preventing unauthorized eavesdropping.
* **Encrypted Local Storage:** All chat messages and private conversation metadata saved to your device are now vaulted using military-grade AES encryption via Android Keystore and iOS Keychain. Your intimate conversations remain inaccessible to other apps, even on compromised devices.
* **Security Policy Published:** A comprehensive `SECURITY.md` policy has been added to our repository outlining our commitment to user data protection and vulnerability disclosure procedures.

### 🛠️ Performance & Stability
* **Routine Maintenance:** Resolved residual bugs within the test suites to ensure absolute stability and regression safety for future feature rollouts.

***

## [10.0.0] - 2026-02-25

### 🎉 New Features
* **Google Gemini AI Integration:** Chat completion is now powered by Google Gemini AI, delivering faster, smarter, and more contextual responses. It also features an optimized chat context message limit to 5.
* **Revamped Dating Persona:** The AI personas have been redefined to be more direct, highly flirtatious, and focused on quick physical escalation.
* **Soulmate Level Achievements:** Your relationship level is now integrated directly into the AI persona context. Unlock the special Soulmate level achievement dialog as your connection grows!
* **Local Chat Storage:** Chat data and messages are now migrated from Firebase Firestore to local on-device storage (SharedPreferences) for dramatically faster load times and enhanced privacy.

### 🚀 Performance & Memory Optimizations
* **Optimized Image Caching:** Vastly reduced the app's memory footprint by implementing strict `memCache` dimension bounds for network images on the Match, Chat, and Details screens. This eliminates out-of-memory crashes on older devices.
* **Silky Smooth Scrolling:** Chat histories now scroll consistently at 60 FPS thanks to the new `RepaintBoundary` rendering optimizations for message bubbles.

### 🛠 Enhancements & Fixes
* **Standardized App Name:** Ensured consistent capitalization ("Soulmate") across Android, iOS, and Web configurations.
* **Under the Hood:** Strengthened unit tests across `api_service` and `user_provider` to ensure robust app stability.
* **Home Screen Tooltips**: Added tooltips to the streak and coin displays on the home screen.
* **Filter Consolidation**: Consolidated filter and settings into a popup menu and enhanced icebreaker selection to prevent immediate repeats.
* **Daily Picks enhancement**: Implement dynamic daily pick counts (5-10) and enhance profile image borders with a gradient.
