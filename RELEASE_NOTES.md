# Soulmate Release Notes

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
