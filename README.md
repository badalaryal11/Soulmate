# Soulmate

**Soulmate** is a modern Flutter-based dating and social application designed to help users find meaningful connections. With a sleek user interface, comprehensive security measures, and robust AI integration, it offers a highly engaging experience for discovering and chatting with potential matches.

## Features

- **Authentication & Security**: 
    - Secure sign-up/login using Email/Password and Google Sign-In.
    - Protected session management with local data encrypted via `flutter_secure_storage`.
    - Secure account wiping and strict Firestore cross-validation rules.
- **Smart Matching & Discovery**:
    - **Custom Filters**: Filter potential matches by age and gender preference.
    - **Daily Picks**: A curated selection of standout users just for you.
    - **Interactive Home Screen**: Highly optimized, buttery-smooth tinder-like card-swiping interface.
- **Gamified Chat Experience**:
    - **Relationship Levels**: Earn XP for chatting and maintaining streaks to unlock levels like "Acquaintance," "Friend," and "Soulmate."
    - **Dynamic AI Personas**: Interact with highly advanced, context-aware AI personas acting as your matches.
    - **In-Chat Games**: Challenge your matches to quick games like Rock, Paper, Scissors!
- **User Profiles**:
    - **Comprehensive Management**: A dedicated unified Profile Tab to update bios, interests, and preferences effortlessly.
    - **Device Uploads & AI Avatars**: Upload your own profile pictures directly from your device, or let our AI generate a unique avatar proxy image for you.
- **Performance Optimized**:
    - Strict memory cache constraints to prevent Out-Of-Memory (OOM) crashes on mobile devices.
    - Streamlined memory handling with leak-proof chat streams.

## Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Services**: [Firebase](https://firebase.google.com/)
  - **Firebase Auth**: User authentication securely handled.
  - **Cloud Firestore**: Real-time database for user metadata and activity tracking.
  - **Firebase Storage**: For user uploaded images.
- **Local Storage**: `flutter_secure_storage` for encrypted on-device message caching.
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Key Packages**:
  - `flutter_card_swiper`: For fluid swipe animations.
  - `cached_network_image`: Efficient, aggressively-optimized image loading and caching.
  - `google_generative_ai`: Powering the conversational matchmaking AI.

## Getting Started

Follow these steps to set up the project locally.

### Prerequisites

- **Flutter SDK**: Ensure you have Flutter installed. [Install Flutter](https://docs.flutter.dev/get-started/install).
- **Firebase Project**: Configure a Firebase project with Authentication, Firestore, and Storage enabled.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/soulmate.git
    cd soulmate
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Environment:**
    - Create a `.env` file in the root directory and specify your AI keys and API config.
    - Ensure `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are correctly placed.

4.  **Run the App:**
    ```bash
    flutter run
    ```

## Security & Privacy
Security is a top priority. For information on responsible disclosure and supported versions, please refer to [SECURITY.md](SECURITY.md).

## License
Soulmate includes a proprietary [LICENSE](LICENSE) file. Please review it for terms regarding distribution and use.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a Pull Request.
