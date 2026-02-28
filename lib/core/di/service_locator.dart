import '../../data/datasources/auth_service.dart';
import '../../data/datasources/database_service.dart';
import '../../data/datasources/chat_service.dart';
import '../../data/datasources/notification_service.dart';
import '../../data/datasources/api_service.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
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
import '../../presentation/providers/user_provider.dart';
import '../../presentation/providers/chat_provider.dart';

/// Centralized dependency injection for the application.
///
/// All data-layer construction is contained here so presentation
/// layer code never needs to import concrete data-layer classes.
class ServiceLocator {
  // Singleton services
  static final DatabaseService _databaseService = DatabaseService();
  static final ApiService _apiService = ApiService();
  static final AuthService _authService = AuthService();
  static final NotificationService _notificationService = NotificationService();
  static final ChatService _chatService = ChatService();

  // Repositories
  static final ChatRepositoryImpl _chatRepository = ChatRepositoryImpl(
    _databaseService,
  );
  static final UserRepositoryImpl _userRepository = UserRepositoryImpl(
    _databaseService,
    _apiService,
  );

  /// Create a fully-wired [ChatProvider].
  static ChatProvider createChatProvider() {
    return ChatProvider(
      chatService: _chatService,
      notificationService: _notificationService,
      getChatIdUseCase: GetChatIdUseCase(_chatRepository),
      getChatStreamUseCase: GetChatStreamUseCase(_chatRepository),
      getMessageHistoryUseCase: GetMessageHistoryUseCase(_chatRepository),
      sendMessageUseCase: SendMessageUseCase(_chatRepository),
      markMessagesAsReadUseCase: MarkMessagesAsReadUseCase(_chatRepository),
    );
  }

  /// Create a fully-wired [UserProvider].
  static UserProvider createUserProvider() {
    return UserProvider(
      userRepository: _userRepository,
      getUsersUseCase: GetUsersUseCase(_userRepository),
      authService: _authService,
      getActiveChatsUseCase: GetActiveChatsUseCase(_chatRepository),
      deleteChatUseCase: DeleteChatUseCase(_chatRepository),
      getChatIdUseCase: GetChatIdUseCase(_chatRepository),
      saveFeedbackUseCase: SaveFeedbackUseCase(_userRepository),
      uploadProfileImageUseCase: UploadProfileImageUseCase(_userRepository),
      updateUserFieldUseCase: UpdateUserFieldUseCase(_userRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(_userRepository),
    );
  }

  /// Access shared services (for screens that need direct service access).
  static DatabaseService get databaseService => _databaseService;
  static AuthService get authService => _authService;
  static NotificationService get notificationService => _notificationService;
}
