import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_active_chats_usecase.dart';
import '../../domain/usecases/get_chat_id_usecase.dart';
import '../../domain/usecases/delete_chat_usecase.dart';
import '../../domain/repositories/user_repository.dart';
import 'current_user_provider.dart';

class MatchProvider extends ChangeNotifier {
  final GetActiveChatsUseCase _getActiveChatsUseCase;
  final GetChatIdUseCase _getChatIdUseCase;
  final DeleteChatUseCase _deleteChatUseCase;
  final UserRepository _userRepository;
  final CurrentUserProvider _currentUserProvider;

  User? get currentUser => _currentUserProvider.currentUser;

  MatchProvider({
    required GetActiveChatsUseCase getActiveChatsUseCase,
    required GetChatIdUseCase getChatIdUseCase,
    required DeleteChatUseCase deleteChatUseCase,
    required UserRepository userRepository,
    required CurrentUserProvider currentUserProvider,
  }) : _getActiveChatsUseCase = getActiveChatsUseCase,
       _getChatIdUseCase = getChatIdUseCase,
       _deleteChatUseCase = deleteChatUseCase,
       _userRepository = userRepository,
       _currentUserProvider = currentUserProvider;

  final List<User> _matches = [];
  List<User> get matches => _matches;

  Future<void> loadMatches() async {
    final currentUser = _currentUserProvider.currentUser;
    if (currentUser == null) return;

    try {
      final chatDocs = await _getActiveChatsUseCase(currentUser.id);

      final List<(String, int, String?, int?)> chatMeta = [];
      for (var chat in chatDocs) {
        final participants = List<String>.from(chat['participants'] ?? []);
        final otherUserId = participants.firstWhereOrNull(
          (id) => id != currentUser.id,
        );
        if (otherUserId != null && otherUserId.isNotEmpty) {
          chatMeta.add((
            otherUserId,
            chat['streak'] ?? 0,
            chat['lastMessage'] as String?,
            chat['lastMessageTime'] as int?,
          ));
        }
      }

      final futures = chatMeta.map((meta) async {
        try {
          final (userId, streak, lastMessage, lastMessageTime) = meta;
          final user = await _userRepository.getUser(userId);
          return user?.copyWith(
            streak: streak,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime != null
                ? DateTime.fromMillisecondsSinceEpoch(lastMessageTime)
                : null,
          );
        } catch (e) {
          debugPrint("Matched user load error: $e");
          return null;
        }
      });

      final results = await Future.wait(futures);
      final newMatches = results.whereType<User>().toList();

      // Only replace the list when we have real data back, or when it was
      // already empty. This prevents a Firestore race / transient empty
      // response from wiping the UI on every chat → back navigation.
      if (newMatches.isNotEmpty || _matches.isEmpty) {
        _matches.clear();
        _matches.addAll(newMatches);
        notifyListeners();
      }
    } catch (e) {
      // Keep existing matches on error so the screen doesn't go blank.
      debugPrint("Error loading matches: $e");
    }
  }

  void addMatch(User user) {
    if (!_matches.any((m) => m.id == user.id)) {
      _matches.insert(0, user);
      notifyListeners();
    }
  }

  Future<void> unmatchUser(String userId) async {
    _matches.removeWhere((user) => user.id == userId);
    notifyListeners();

    final currentUser = _currentUserProvider.currentUser;
    if (currentUser != null) {
      final chatId = await _getChatIdUseCase(currentUser.id, userId);
      await _deleteChatUseCase(chatId);
    }
  }
}
