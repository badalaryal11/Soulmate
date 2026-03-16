import 'package:flutter/foundation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/datasources/database_service.dart';
import '../../data/datasources/chat_service.dart';
import '../../data/datasources/notification_service.dart';
import '../../data/datasources/api_service.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_chat_id_usecase.dart';
import '../../domain/usecases/get_chat_stream_usecase.dart';
import '../../domain/usecases/get_message_history_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/mark_messages_as_read_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/get_active_chats_usecase.dart';
import '../../domain/usecases/delete_chat_usecase.dart';
import '../../domain/usecases/save_feedback_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import '../../domain/usecases/update_user_field_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/get_chat_metadata_stream_usecase.dart';
import '../../domain/usecases/send_ai_message_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_in_with_apple_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/confirm_password_reset_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';

import '../../presentation/providers/chat_provider.dart';
import '../../presentation/providers/current_user_provider.dart';
import '../../presentation/providers/profile_management_provider.dart';
import '../../presentation/providers/match_provider.dart';
import '../../presentation/providers/discovery_provider.dart';

/// Centralized dependency injection for the application.
///
/// All data-layer construction is contained here so presentation
/// layer code never needs to import concrete data-layer classes.
class ServiceLocator {
  // Singleton data-layer services (private — never exposed)
  static final DatabaseService _databaseService = DatabaseService();
  static final ApiService _apiService = ApiService();
  static AuthService? _authServiceInstance;
  static AuthService get _authService => _authServiceInstance ??= AuthService();
  static final NotificationService _notificationService = NotificationService();
  static final ChatService _chatService = ChatService();

  // Repositories (exposed as abstractions)
  static final ChatRepository _chatRepository = ChatRepositoryImpl(
    _databaseService,
  );
  static UserRepository _userRepository = UserRepositoryImpl(
    _databaseService,
    _apiService,
  );
  static AuthRepository _authRepository = AuthRepositoryImpl(_authService);
  static final AiChatRepository _aiChatRepository = AiChatRepositoryImpl(
    _chatService,
  );
  static final NotificationRepository _notificationRepository =
      NotificationRepositoryImpl(_notificationService);

  @visibleForTesting
  static void setMockRepositories({
    AuthRepository? authRepository,
    dynamic
    userRepository, // Use dynamic to avoid strict type coupling with UserRepositoryImpl
  }) {
    if (authRepository != null) _authRepository = authRepository;
    if (userRepository != null) _userRepository = userRepository;
  }

  /// Create a fully-wired [ChatProvider].
  static ChatProvider createChatProvider() {
    return ChatProvider(
      aiChatRepository: _aiChatRepository,
      notificationRepository: _notificationRepository,
      getChatIdUseCase: GetChatIdUseCase(_chatRepository),
      getChatStreamUseCase: GetChatStreamUseCase(_chatRepository),
      getMessageHistoryUseCase: GetMessageHistoryUseCase(_chatRepository),
      sendMessageUseCase: SendMessageUseCase(_chatRepository),
      markMessagesAsReadUseCase: MarkMessagesAsReadUseCase(_chatRepository),
      sendAiMessageUseCase: SendAiMessageUseCase(_aiChatRepository),
      getChatMetadataStreamUseCase: GetChatMetadataStreamUseCase(
        _chatRepository,
      ),
    );
  }

  /// Create [CurrentUserProvider]
  static CurrentUserProvider createCurrentUserProvider() {
    return CurrentUserProvider(
      authRepository: _authRepository,
      getCurrentUserUseCase: GetCurrentUserUseCase(_userRepository),
      userRepository: _userRepository,
    );
  }

  /// Create [ProfileManagementProvider]
  static ProfileManagementProvider createProfileManagementProvider(
    CurrentUserProvider currentUserProvider,
  ) {
    return ProfileManagementProvider(
      updateUserFieldUseCase: UpdateUserFieldUseCase(_userRepository),
      saveFeedbackUseCase: SaveFeedbackUseCase(_userRepository),
      uploadProfileImageUseCase: UploadProfileImageUseCase(_userRepository),
      currentUserProvider: currentUserProvider,
    );
  }

  /// Create [MatchProvider]
  static MatchProvider createMatchProvider(
    CurrentUserProvider currentUserProvider,
  ) {
    return MatchProvider(
      getActiveChatsUseCase: GetActiveChatsUseCase(_chatRepository),
      getChatIdUseCase: GetChatIdUseCase(_chatRepository),
      deleteChatUseCase: DeleteChatUseCase(_chatRepository),
      userRepository: _userRepository,
      currentUserProvider: currentUserProvider,
    );
  }

  /// Create [DiscoveryProvider]
  static DiscoveryProvider createDiscoveryProvider(
    CurrentUserProvider currentUserProvider,
  ) {
    return DiscoveryProvider(
      getUsersUseCase: GetUsersUseCase(_userRepository),
      currentUserProvider: currentUserProvider,
    );
  }

  /// Access shared repositories (for screens that need direct access).
  /// These expose abstract interfaces, not concrete implementations.
  static AuthRepository get authRepository => _authRepository;
  static NotificationRepository get notificationRepository =>
      _notificationRepository;

  /// Auth use cases for screens that need individual auth operations.
  static SignInWithGoogleUseCase get signInWithGoogleUseCase =>
      SignInWithGoogleUseCase(_authRepository);
  static SignInWithAppleUseCase get signInWithAppleUseCase =>
      SignInWithAppleUseCase(_authRepository);
  static SignInWithEmailUseCase get signInWithEmailUseCase =>
      SignInWithEmailUseCase(_authRepository);
  static RegisterUseCase get registerUseCase =>
      RegisterUseCase(_authRepository);
  static SignOutUseCase get signOutUseCase => SignOutUseCase(_authRepository);
  static SendPasswordResetUseCase get sendPasswordResetUseCase =>
      SendPasswordResetUseCase(_authRepository);
  static ConfirmPasswordResetUseCase get confirmPasswordResetUseCase =>
      ConfirmPasswordResetUseCase(_authRepository);
  static DeleteAccountUseCase get deleteAccountUseCase =>
      DeleteAccountUseCase(_authRepository);

  /// User repository for screens that need direct user data operations.
  static UserRepository get userRepository => _userRepository;

  /// Debug-only: wipe all Firestore data.
  static Future<void> wipeAllData() => _databaseService.wipeAllData();
}
