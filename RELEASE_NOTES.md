# Soulmate Release Notes

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
