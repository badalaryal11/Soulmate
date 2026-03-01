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
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/send_ai_message_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_in_with_apple_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/confirm_password_reset_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../data/datasources/daily_picks_service.dart';
import '../../presentation/providers/user_provider.dart';
import '../../presentation/providers/chat_provider.dart';

/// Centralized dependency injection for the application.
///
/// All data-layer construction is contained here so presentation
/// layer code never needs to import concrete data-layer classes.
class ServiceLocator {
  // Singleton data-layer services (private — never exposed)
  static final DatabaseService _databaseService = DatabaseService();
  static final ApiService _apiService = ApiService();
  static final AuthService _authService = AuthService();
  static final NotificationService _notificationService = NotificationService();
  static final ChatService _chatService = ChatService();

  // Repositories (exposed as abstractions)
  static final ChatRepositoryImpl _chatRepository = ChatRepositoryImpl(
    _databaseService,
  );
  static final UserRepositoryImpl _userRepository = UserRepositoryImpl(
    _databaseService,
    _apiService,
  );
  static final AuthRepository _authRepository = AuthRepositoryImpl(
    _authService,
  );
  static final AiChatRepository _aiChatRepository = AiChatRepositoryImpl(
    _chatService,
  );
  static final NotificationRepository _notificationRepository =
      NotificationRepositoryImpl(_notificationService);

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
    );
  }

  /// Create a fully-wired [UserProvider].
  static UserProvider createUserProvider() {
    return UserProvider(
      userRepository: _userRepository,
      getUsersUseCase: GetUsersUseCase(_userRepository),
      authRepository: _authRepository,
      getActiveChatsUseCase: GetActiveChatsUseCase(_chatRepository),
      deleteChatUseCase: DeleteChatUseCase(_chatRepository),
      getChatIdUseCase: GetChatIdUseCase(_chatRepository),
      saveFeedbackUseCase: SaveFeedbackUseCase(_userRepository),
      uploadProfileImageUseCase: UploadProfileImageUseCase(_userRepository),
      updateUserFieldUseCase: UpdateUserFieldUseCase(_userRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(_userRepository),
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

  /// DailyPicksService — exposed via ServiceLocator only.
  static DailyPicksService get dailyPicksService => DailyPicksService();

  /// Debug-only: wipe all Firestore data.
  static Future<void> wipeAllData() => _databaseService.wipeAllData();
}
