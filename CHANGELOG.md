# Changelog

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
