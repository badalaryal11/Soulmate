# Soulmate

**Soulmate** is a modern Flutter-based dating and social application designed to help users find meaningful connections. With a sleek user interface and robust features, it offers a seamless experience for discovering and chatting with potential matches.

## Features

- **Authentication**: Secure sign-up and login using Email/Password and **Google Sign-In**.
- **User Onboarding**: Personalized profile setup including gender selection and interest tagging.
- **Matchmaking**: Interactive card-swiping interface to discover potential matches.
- **Real-time Chat**: Instant messaging with matched users.
- **User Profiles**: Detailed profiles showcasing user interests and photos.
- **Modern UI/UX**: Built with Material 3 design principles, custom fonts (Poppins), and smooth animations.

## Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Services**: [Firebase](https://firebase.google.com/)
  - **Firebase Auth**: User authentication.
  - **Cloud Firestore**: Real-time database for user data and chat history.
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Key Packages**:
  - [`flutter_card_swiper`](https://pub.dev/packages/flutter_card_swiper): For the tinder-like swipe animation.
  - [`google_sign_in`](https://pub.dev/packages/google_sign_in): For Google authentication.
  - [`cached_network_image`](https://pub.dev/packages/cached_network_image): Efficient image loading and caching.
  - [`google_fonts`](https://pub.dev/packages/google_fonts): Custom typography.

## Getting Started

Follow these steps to set up the project locally.

### Prerequisites

- **Flutter SDK**: Ensure you have Flutter installed and set up. [Install Flutter](https://docs.flutter.dev/get-started/install).
- **Firebase Project**: You need a Firebase project configured for Android and iOS.

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
    - Create a `.env` file in the root directory (if required by the code, though `flutter_dotenv` is used).
    - Ensure `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are present (obtained from your Firebase console).

4.  **Run the App:**
    ```bash
    flutter run
    ```

## Folder Structure

The project follows a feature-based structure within `lib/`:

- `data/`: Data layer including services (e.g., `auth_service.dart`) and models.
- `presentation/`: UI layer.
  - `screens/`: Application screens (Login, Home, Chat, etc.).
  - `providers/`: State management providers (e.g., `user_provider.dart`).
  - `widgets/`: Reusable UI components.
- `utils/`: Utility classes and constants.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
