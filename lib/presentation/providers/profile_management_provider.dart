import 'package:flutter/material.dart';
import '../../domain/usecases/update_user_field_usecase.dart';
import '../../domain/usecases/save_feedback_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import 'current_user_provider.dart';

class ProfileManagementProvider extends ChangeNotifier {
  final UpdateUserFieldUseCase _updateUserFieldUseCase;
  final SaveFeedbackUseCase _saveFeedbackUseCase;
  final UploadProfileImageUseCase _uploadProfileImageUseCase;
  // Needs access to the current user to update it locally when changing fields
  final CurrentUserProvider _currentUserProvider;

  ProfileManagementProvider({
    required UpdateUserFieldUseCase updateUserFieldUseCase,
    required SaveFeedbackUseCase saveFeedbackUseCase,
    required UploadProfileImageUseCase uploadProfileImageUseCase,
    required CurrentUserProvider currentUserProvider,
  }) : _updateUserFieldUseCase = updateUserFieldUseCase,
       _saveFeedbackUseCase = saveFeedbackUseCase,
       _uploadProfileImageUseCase = uploadProfileImageUseCase,
       _currentUserProvider = currentUserProvider;

  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    await _updateUserFieldUseCase(uid, data);

    // Also update the local state so UI instantly reflects
    final current = _currentUserProvider.currentUser;
    if (current != null && current.id == uid) {
      // Very basic local copy updates for common fields
      var updatedUser = current;
      if (data.containsKey('bio')) {
        updatedUser = updatedUser.copyWith(bio: data['bio']);
      }
      if (data.containsKey('interests')) {
        updatedUser = updatedUser.copyWith(
          interests: List<String>.from(data['interests']),
        );
      }
      if (data.containsKey('name')) {
        // Simple heuristic for splitting name, assuming space
        final parts = data['name'].toString().split(' ');
        updatedUser = updatedUser.copyWith(
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        );
      }
      if (data.containsKey('gender')) {
        updatedUser = updatedUser.copyWith(gender: data['gender']);
      }
      if (data.containsKey('genderPreference')) {
        updatedUser = updatedUser.copyWith(
          genderPreference: data['genderPreference'],
        );
      }
      if (data.containsKey('age')) {
        updatedUser = updatedUser.copyWith(age: data['age']);
      }
      if (data.containsKey('city') || data.containsKey('country')) {
        updatedUser = updatedUser.copyWith(
          city: data['city'] ?? updatedUser.city,
          country: data['country'] ?? updatedUser.country,
        );
      }
      if (data.containsKey('favoriteUserIds')) {
        updatedUser = updatedUser.copyWith(
          favoriteUserIds: List<String>.from(data['favoriteUserIds']),
        );
      }
      if (data.containsKey('imageUrl')) {
        updatedUser = updatedUser.copyWith(imageUrl: data['imageUrl'] as String);
      }
      if (data.containsKey('lastLoginDate')) {
        updatedUser = updatedUser.copyWith(
          lastLoginDate: data['lastLoginDate'],
        );
      }
      _currentUserProvider.updateLocalUser(updatedUser);
    }
  }

  Future<void> toggleFavorite(String targetUserId) async {
    final currentUser = _currentUserProvider.currentUser;
    if (currentUser == null) return;

    final currentFavorites = List<String>.from(currentUser.favoriteUserIds);
    if (currentFavorites.contains(targetUserId)) {
      currentFavorites.remove(targetUserId);
    } else {
      currentFavorites.add(targetUserId);
    }

    await updateUserField(currentUser.id, {
      'favoriteUserIds': currentFavorites,
    });
  }

  Future<void> saveFeedback(String userId, String message) async {
    await _saveFeedbackUseCase(userId, message);
  }

  Future<String> uploadProfileImage(String userId, dynamic imageFile) async {
    return await _uploadProfileImageUseCase(userId, imageFile);
  }
}
