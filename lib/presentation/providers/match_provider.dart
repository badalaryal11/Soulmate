import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_active_chats_usecase.dart';
import '../../domain/usecases/get_chat_id_usecase.dart';
import '../../domain/usecases/delete_chat_usecase.dart';
import '../../domain/repositories/user_repository.dart';
import 'current_user_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

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
       _currentUserProvider = currentUserProvider {
    // Eagerly restore cached matches so the UI is never empty on cold start
    _loadMatchesFromCache();
  }

  final List<User> _matches = [];
  List<User> get matches => _matches;
  bool _isLoadingMatches = false;

  static const String _cachedMatchesKey = 'cached_matches_list';

  Future<void> _saveMatchesToCache(List<User> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encoded = matches.map((u) {
        final model = UserModel(
          id: u.id,
          email: u.email,
          firstName: u.firstName,
          lastName: u.lastName,
          age: u.age,
          city: u.city,
          country: u.country,
          imageUrl: u.imageUrl,
          gender: u.gender,
          interests: u.interests,
          genderPreference: u.genderPreference,
          bio: u.bio,
          streak: u.streak,
          coins: u.coins,
          lastLoginDate: u.lastLoginDate,
          prompts: u.prompts,
          badges: u.badges,
          favoriteUserIds: u.favoriteUserIds,
          pinnedUserIds: u.pinnedUserIds,
        );
        final map = model.toMap();
        map['lastMessage'] = u.lastMessage;
        map['lastMessageTime'] = u.lastMessageTime?.millisecondsSinceEpoch;
        return jsonEncode(map);
      }).toList();
      await prefs.setStringList(_cachedMatchesKey, encoded);
    } catch (e) {
      debugPrint("Error caching matches: $e");
    }
  }

  Future<void> _loadMatchesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encoded = prefs.getStringList(_cachedMatchesKey);
      if (encoded != null && encoded.isNotEmpty) {
        final cached = encoded.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          var user = UserModel.fromMap(map);
          return user.copyWith(
            lastMessage: map['lastMessage'] as String?,
            lastMessageTime: map['lastMessageTime'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    map['lastMessageTime'] as int,
                  )
                : null,
          );
        }).toList();

        // Only restore from cache if in-memory list is empty.
        // This prevents stale cache from overwriting a live network result.
        if (_matches.isEmpty) {
          _matches.addAll(cached);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error loading cached matches: $e");
    }
  }

  /// Lightweight restore for lifecycle transitions (e.g. app resume).
  /// Loads from cache only if the in-memory list is empty, then
  /// optionally triggers a full network refresh.
  Future<void> restoreFromCacheIfNeeded() async {
    if (_matches.isEmpty) {
      await _loadMatchesFromCache();
    }
  }

  Future<void> loadMatches() async {
    if (_isLoadingMatches) return;
    _isLoadingMatches = true;

    // Load cached matches instantly so the UI isn't empty on cold boot
    await _loadMatchesFromCache();

    final currentUser = _currentUserProvider.currentUser;
    if (currentUser == null) {
      _isLoadingMatches = false;
      return;
    }

    // STRICT OFFLINE GUARD
    // Prevent the provider from fetching empty lists when disconnected, which
    // would otherwise falsely appear as '0 matches' and wipe the local cache.
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint(
          'MatchProvider: Connection offline. Aborting fetch to preserve local cache.',
        );
        _isLoadingMatches = false;
        return;
      }
    } catch (_) {
      // If connectivity check fails for some reason, cautiously proceed.
    }

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

      // If chatDocs is empty, we must distinguish between a cold boot (where Firebase
      // might return [] before sync) and a genuine 0-match state.
      if (chatDocs.isEmpty) {
        // Clear if we're confident this isn't just a transient cold-boot state
        _matches.clear();
        notifyListeners();
        unawaited(_saveMatchesToCache([]));
        debugPrint("MatchProvider: 0 matches detected. Cache cleared.");
      } else {
        _matches.clear();
        _matches.addAll(newMatches);
        notifyListeners();
        unawaited(_saveMatchesToCache(newMatches));
      }
    } catch (e) {
      // Keep existing matches on error so the screen doesn't go blank.
      debugPrint("Error loading matches: $e");
    } finally {
      _isLoadingMatches = false;
    }
  }

  void addMatch(User user) {
    if (!_matches.any((m) => m.id == user.id)) {
      _matches.insert(0, user);
      notifyListeners();
      unawaited(_saveMatchesToCache(_matches));
    }
  }

  Future<void> unmatchUser(String userId) async {
    // Optimistic UI update
    final removedUser = _matches.firstWhereOrNull((u) => u.id == userId);
    _matches.removeWhere((user) => user.id == userId);
    notifyListeners();
    _saveMatchesToCache(_matches);

    final currentUser = _currentUserProvider.currentUser;
    if (currentUser != null) {
      try {
        final chatId = await _getChatIdUseCase(currentUser.id, userId);
        await _deleteChatUseCase(chatId);
      } catch (e) {
        // Rollback: re-insert the removed user so the UI stays consistent.
        debugPrint("Unmatch failed, rolling back: $e");
        if (removedUser != null) {
          _matches.insert(0, removedUser);
          notifyListeners();
        }
      }
    }
  }
}
