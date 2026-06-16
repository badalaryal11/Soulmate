# Soulmate Release Notes

---

## v1.9.4 — Google Sign-In & Stability Fixes (June 16, 2026)

### 🔑 Authentication
* **Google Sign-In Resolved** — Fixed a critical issue that caused Google Sign-In to fail on newer Android devices (`Error 16: Account reauth failed`). We've updated our authentication flow to fully support the modern Android Credential Manager by explicitly providing the backend server client ID during initialization.
* **Streamlined Login Flow** — Cleaned up the authentication codebase to properly handle synchronous token retrieval and cancellation states in the latest Google Sign-In SDK.

---

## v1.9.3 — Google Sign-In Fix (June 13, 2026)

### 🔑 Authentication
* **Google Sign-In Resolved** — Fixed a `PlatformException` that prevented Google Sign-In from completing on Android. The root cause was a hardcoded `serverClientId` in the `GoogleSignIn` constructor that conflicted with the auto-detected web client ID from `google-services.json`.
* **Explicit OAuth Scopes** — Added explicit `email` and `profile` scopes to the Google Sign-In configuration for reliable user information retrieval across all build types.

### ⚙️ Under-the-Hood
* **Production-Safe Configuration** — Verified ProGuard keep rules, release keystore SHA-1 registration, and signing config to ensure the fix works identically in both debug and release builds.

---

## v1.9.2 — Privacy Policy Styling & Android SDK Update (June 12, 2026)

### 📄 Branding & Styling
* **Privacy Policy Branding:** Redesigned the external privacy policy webpage with the official custom logo, favicon, and cursive `Lobster` font styling to match the Soulmate brand.

### 🤖 Android SDK & Immersive UI
* **Android SDK Upgrade:** Bumped the compile and target SDK versions to API 36.
* **Edge-to-Edge Display:** Enabled native edge-to-edge layouts (via `enableEdgeToEdge()`) in `MainActivity` for a modern, bezel-less visual experience.
* **MainActivity Refactoring:** Updated `MainActivity` to extend `FlutterFragmentActivity` to provide enhanced support compatibility.

---

## v1.9.1 — Multilingual AI Chat (June 12, 2026)

### 💬 Multilingual AI Chat
* **Language-Aware Conversations:** Configured the AI matching partner to automatically detect and respond in the same language or dialect that the user is currently using, ensuring full multilingual support (Spanish, French, Nepali, Hindi, Japanese, etc.) without losing persona consistency.

---

## v1.9.0 — Performance, Imagery & Smarter Discovery (June 9, 2026)

### 🖼️ Image & Avatar Optimizations
* **WebP Image Migration:** Profile image uploads are now converted to WebP format, drastically reducing file sizes while maintaining high quality. This saves user bandwidth and improves load times.
* **Memory-Constrained Caching:** Revamped image caching logic to respect strict memory constraints, preventing out-of-memory crashes on older devices during heavy swiping.
* **Instant Portrait Loading:** Implemented timestamp-based unique portraits and background image prefetching so the next profile is always ready to view instantly.
* **Storage Cleanup:** Added automated storage cleanup to properly remove old profile pictures when new ones are uploaded.
* **Background Uploads:** Profile picture uploads now process smoothly in the background without locking the UI.

### 🔍 Smarter Discovery Deck
* **Shared Interest Priority:** The discovery logic has been significantly improved to prioritize showing you profiles of users who share similar interests.
* **Increased Fetch Limit:** Expanded the batch size for fetching profiles, reducing the frequency of loading screens while swiping.

### 🛠️ Stability & Polish
* **Simplified Password Resets:** Streamlined the password reset flow by removing redundant action code configurations.
* **Landing Page Support:** Added new external landing pages with proper cross-browser styling and site verification tags.
* **General Refactoring:** Simplified avatar URL resolution logic and optimized profile card rendering performance.

---

## v1.8.0 — Google Sign-In Fixes & UI Polish (June 8, 2026)

### 🔑 Authentication
* **Google Sign-In Resolution** — Fixed an issue causing production logins to fail (Error 12500) by enabling the People API on the backend.
* **Improved Error Messaging** — Added clearer, human-readable error messages for authentication failures instead of generic raw exceptions.

### 🎨 Visuals & UI
* **Glassmorphic Login Screen** — Redesigned the authentication screen with a modern, glassmorphic layout for a premium feel.
* **Profile Card Performance** — Optimized image rendering and gradient overlays to keep swiping butter-smooth.

### ⚙️ Under-the-Hood
* **Modernized Android Build** — Migrated Gradle build configuration from Groovy to Kotlin DSL (`build.gradle.kts`) for better maintainability and modern standard adherence.

---

## v1.7.0 — Immersive Display, Authentication & Startup Polish (June 4, 2026)

### 🎨 Visuals & Styling
* **Edge-to-Edge Screen Support** — Enabled native edge-to-edge layouts on Android, letting application content flow beautifully behind status and navigation bars.
* **UI Typography & Theming** — Unified AppBar titles and text styling across multiple screens using centralized theme tokens for consistent light/dark mode experiences.

### 🔑 Authentication & Login Flow
* **Google Sign-In Configuration** — Updated client ID configuration to ensure stable authentication.
* **Optimized Login Experience** — Removed redundant sign-out prompts before Google Sign-In, and updated last login timestamp writes asynchronously to prevent startup delays.

### ❤️ Matching & Chat Enhancements
* **Dynamic Swipe Thresholds** — Fine-tuned matching simulation logic and swipe thresholds for a more responsive deck experience.
* **Persistent Age Filters** — Swiping preferences like age filters are now saved persistently across sessions.
* **Chat Persistence & Reliability** — Re-engineered chat stream initialization to run asynchronously. Added `InitializeChatUseCase` to secure match storage on initial pairing.
* **Message Collapsing** — Consecutive chat messages from the same sender are now collapsed for cleaner chat layouts.

### ⚡ Performance & System Optimization
* **Faster Startup** — Deferred notification initialization to post-mount, preventing start-up blocks and accelerating initial load times.
* **Improved Build & Launch Speed** — Optimized Gradle configurations (enabled daemon, parallel compilation, and caching) for faster build speeds.
* **Resource Management** — Improved memory safety by implementing proper cleanup for active stream controllers and rate-limiter entries.

---

## v1.6.1 — Match Reliability & Favorites Fix (April 19, 2026)

### ❤️ Matching & Match Screen
* **Reliable Match Popup** — Fixed an issue where the match screen could fail to open because image precaching errors interrupted navigation.
* **Safer Image Precache Flow** — Match avatar precaching now runs in the background and safely supports local files, assets, and network URLs without blocking UI transitions.
* **Improved Right-Swipe Matching** — Right swipes now use mutual-like-aware logic with tuned fallback behavior to prevent "no matches ever" dead-ends.

### ⭐ Favorites Correction
* **Favorites No Longer Includes Every Match** — Fixed a regression where all matched users appeared in Favorites.
* **Separated Data Fields** — Introduced dedicated `pinnedUserIds` for Favorites, while swipe-like/match logic continues using `favoriteUserIds`.
* **Updated Favorites UI Wiring** — Favorites in Matches and Chat now read from explicit pinned users only.

### 🛠 Stability
* **Swipe Index Guard** — Added defensive swipe index checks to avoid edge-case card callback errors.
* **Local Match Cache Update** — Newly added matches are cached immediately for more consistent match-list persistence.

---

## v1.6.0 — Discovery & Login Overhaul (March 19, 2026)

### 🔍 Smarter Discovery Deck
* **RandomUser API Integration** — The discovery deck now merges real Firestore users with profiles fetched from the RandomUser API, giving you a richer and more diverse set of cards to swipe through.
* **Offline-Ready Fallback** — When the external API is unavailable, the app seamlessly generates local user profiles so the card deck never runs dry.
* **Swiped Profile Tracking** — Already-swiped profiles are now tracked to ensure you never see the same card twice, even across mixed data sources.
* **Proactive User Loading** — New profiles are loaded proactively in the background, keeping the swipe experience buttery smooth with zero wait times.

### 🔑 Modernized Login Screen
* **Provider-Based Auth** — Introduced a dedicated `LoginProvider` to centralize all authentication logic (Google, Apple, Email/Password), replacing scattered state management with a clean, testable architecture.
* **Form Validation** — Added real-time validation for email and password fields, giving users instant feedback before submission.
* **Modular Widget Architecture** — Refactored the login screen into focused, reusable sub-widgets (header, email input, password input) for improved maintainability and consistency.
* **Optimized State Handling** — Migrated toggle states (Remember Me, Show Password) to `ValueNotifier` for granular, efficient rebuilds.

### 🖼️ Avatar & Image Enhancements
* **Centralized Image Loading** — Introduced `ImageUtils` to unify image loading and precaching logic across local, asset, and network sources.
* **Refined Avatar Shapes** — Evolved user avatars through multiple design iterations, settling on a polished look with gradient borders, box shadows, and smooth round shapes across all screens.
* **Verification Badges & Upload Progress** — The `UserAvatar` widget now supports verification badge overlays, hero animations, and upload progress indicators.

### 📄 Other Improvements
* **Updated Privacy Policy** — Refreshed the privacy policy with a new "Device Permissions" section and updated dates.
* **Theme Consistency** — Removed explicit font and widget styling overrides from the login screen in favor of the global theme, ensuring a unified look across the app.

---

## v1.5.0 — Core Features & Deep Optimization (March 17, 2026)

### ✨ New Features
* **Profile Picture Upload** — Users can now seamlessly upload custom profile pictures during the login and registration process.
* **Custom Currency Input** — Enhanced the "Add Expense" screen by allowing users to select "Other" and input their own custom currency codes.

### ⚡ Performance & Bug Fixes
* **Instant Chat Loading** — Fixed an issue causing an infinite loading spinner when returning to inactive chats. Your messages now load and stream instantly.
* **Lightning Fast Stickers** — Dramatically sped up the sticker fetching process, significantly improving typing speed and responsiveness in the chat screen.
* **Memory & UI Optimizations** — Implemented strict image compression for new uploads and optimized widget rendering to eliminate unnecessary UI rebuilds on the HomeScreen.

---

## v1.4.0 — Personalization & Aesthetics (March 11, 2026)

### 🎨 Theme Customization
* **Dark & Light Mode Toggle** — Introduced a new theme mode toggle in the settings, allowing users to seamlessly switch between Dark and Light modes to suit their visual preferences.

---

## v1.3.0 — Architecture & Scalability Refactor (March 10, 2026)

### 🏗️ Provider Scalability Refactoring
* **Segregated Monolithic Provider** — Replaced the massive monolithic `UserProvider` with four highly focused providers (`CurrentUserProvider`, `ProfileManagementProvider`, `DiscoveryProvider`, and `MatchProvider`), deeply adhering to the Interface Segregation Principle.
* **Reduced UI Rebuilds** — By decoupling state domains, UI components now solely rebuild when *their* specific state changes, completely eliminating cross-contamination rebuilds (e.g., swiping on a profile no longer rebuilds the Chat or Settings screens).

### ⚡ Advanced Performance & Network Polish
* **Smarter Image Prefetching** — Reduced the look-ahead image buffer from 8 cards to 3 cards, drastically saving network bandwidth and preventing excessive background HTTP requests while maintaining a buttery-smooth swipe experience.
* **Strict Image Memory Caching** — Enforced hard limits on downsampling 4K photos inside `CachedNetworkImage` and bounded the global Flutter `imageCache` to 100MB, eliminating Out-Of-Memory (OOM) crashes on older devices.
* **Race Condition Fixes** — Added robust locking mechanisms (`_isLoadingUsers`, `_SimpleMutex`) to prevent duplicate backend calls when users swipe too quickly, and fortified concurrent read/write logic to the local `FlutterSecureStorage` chat database.
* **Optimized Rendering & Fonts** — Enabled the new Impeller rendering engine for Android in `AndroidManifest.xml` to squash shader compilation jank, and restricted `GoogleFonts` runtime HTTP fetching to ensure rapid offline font loading natively.

---

## v1.2.0 — Favorites & UI Streamlining (March 9, 2026)

### ⭐ New Favorites Feature
* **Save your top matches** — You can now add users to your Favorites directly from the chat screen to keep track of your best connections.
* **Dedicated Favorites Section** — Easily access your saved profiles through the new Favorites section added to the Matches screen.

### 🧹 UI Cleanups & Removals
* **Removed Undo Button** — The undo action button and its associated logic have been removed from the home tab for a cleaner swiping experience.
* **Removed Profile Sharing** — The profile sharing functionality has been removed from the chat screen to focus on private conversations.

### ⚙️ Under-the-Hood Improvements
* **Smarter Profile Loading** — The app now prioritizes loading your current user profile first. This ensures your gender preferences are correctly applied before fetching and displaying other users, improving the relevance of your initial matches.

---

## v1.1.0 — Performance & Network Optimization (March 3, 2026)

### ⚡ Faster Card Loading
* **Parallel startup** — Matching cards now begin loading immediately instead of waiting for your profile to load first, cutting initial load time in half.
* **Concurrent data fetching** — Firestore and API calls now run simultaneously via `Future.wait` instead of sequentially.
* **Removed precache gate** — Cards render instantly; images load inline with smooth placeholders instead of a full-screen spinner.

### 🌐 Network Optimizations
* **Faster timeouts** — API request timeouts reduced from 10s to 5s so failing endpoints unblock sooner.
* **Quicker retries** — Retry delay between failed API attempts reduced from 2s to 500ms.
* **Non-blocking streak update** — Daily login streak/coin updates no longer block the entire startup flow.
* **Cache-first profile reads** — Returning users load their profile from local Firestore cache, skipping a network round trip.

### 🎭 Unique Profiles
* **Diverse bios** — Each profile now shows a unique bio from a pool of 24 options instead of the same hardcoded text on every card.
* **No duplicate cards** — Added ID-based deduplication to prevent the same user from appearing twice in the card deck.

---

## v1.0.0 — Initial Release

Welcome to the latest release of Soulmate! This major update focuses on bringing you a richer chat experience, a refined user interface, and a much faster, optimized application underneath.

## ✨ New Features & Enhancements

### **Refined Chat Experience**
* **Instant Feedback:** Replaced the legacy loading spinner with a rich, animated "typing..." indicator (`TypingBubble`) for AI responses.
* **Message Receipts:** Added "Seen ✓✓" read receipts for your outbound chat messages.
* **Contextual Conversations:** The other user's avatar now appears directly next to incoming messages for better visual flow.
* **Undo Swipes:** Accidentally dismissed a match? We've introduced an undo swipe functionality.
* **Fresh Profiles:** Added a manual swipe-to-refresh capability to ensure your match data is always up-to-date.
* **Share and Discover:** Easily share profiles with friends through our integrated `SharePlus` social sharing capabilities.

### **User Interface Optimization**
* **Focused View:** Locked screen orientation to portrait mode, ensuring the app's layout stays pristine.
* **Streamlined UI:** Removed the "daily picks" feature to focus heavily on core matching and authentic chats.

## 🚀 Performance & Optimizations

* **Blazing Fast Networking:** Parallel fetching implemented for matching logic, resulting in faster discovery of local users and quicker UI rendering on your Matches and Chat screens.
* **Smoother Image Loading:**
  * Adopted `CachedNetworkImage` extensively across user profiles to prevent repetitive network calls.
  * We now aggressively precache matched user images *before* you see them, enhancing your browsing performance.
  * Fixed an edge-case bug where local images (`file://`) were incorrectly treated as network requests, avoiding unnecessary timeouts.
  * Integrated on-device image compression for a smoother user photo upload experience.
* **Optimized State Management:**
  * Reduced memory footprint by intelligently limiting historical message rendering.
  * Cached core instances (`ThemeData`, `SharedPreferences`, etc.) to minimize unnecessary UI rebuilds and provider dependency overhead.

## 🛠️ Under The Hood (Architecture & Refactoring)

* **Clean Architecture:** Significant refactoring efforts have modernized the codebase to use "Clean Architecture" principles. The app now leverages standard Use Cases and Repositories via Dependency Injection (Service Locator).
* **Robust Error Handling:** Re-introduced typed failure and exception handling to gracefully recover from network and server errors.
* **Rock-Solid Authentication:** Fully refactored our `AuthService` with robust unit tests mapping to mocked `FlutterSecureStorage` and internal user verification logic.
