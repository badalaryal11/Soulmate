import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class ImageGenerationService {
  // Source 1: xsgames.co (High quality, ~50KB per image, 500x500+)
  static const String _xsgamesBase =
      'https://xsgames.co/randomusers/assets/avatars';

  // Source 2: randomuser.me (Low res 128x128 but reliable)
  static const String _randomUserBase = 'https://randomuser.me/api/portraits';

  /// Generates a profile image URL.
  /// Randomly distributes users between xsgames (50%) and randomuser.me (50%)
  /// using the user ID hash for deterministic results (so it doesn't flicker on scroll).
  static String generateProfileImageUrl(User user) {
    // 50/50 split based on ID
    final bool useXsGames = user.id.hashCode.abs() % 2 == 0;
    return useXsGames
        ? _generateXsGamesUrl(user)
        : _generateRandomUserUrl(user);
  }

  /// Returns the alternate URL validation source in case the primary fails.
  static String getFallbackUrl(User user, String failedUrl) {
    if (failedUrl.contains('xsgames.co')) {
      return _generateRandomUserUrl(user);
    } else {
      return _generateXsGamesUrl(user);
    }
  }

  static String _generateXsGamesUrl(User user) {
    final String genderFolder = _getXsGamesGenderFolder(user.gender);
    // xsgames 0-75 safe range
    final int index = user.id.hashCode.abs() % 76;
    return '$_xsgamesBase/$genderFolder/$index.jpg';
  }

  static String _generateRandomUserUrl(User user) {
    final String genderFolder = _getRandomUserGenderFolder(user.gender);
    // randomuser 0-99 range
    final int index = user.id.hashCode.abs() % 100;
    return '$_randomUserBase/$genderFolder/$index.jpg';
  }

  // --- Helpers ---

  static String _getXsGamesGenderFolder(String gender) {
    final g = gender.toLowerCase();
    if (g == 'male' || g == 'man') return 'male';
    if (g == 'female' || g == 'woman') return 'female';
    return 'male';
  }

  static String _getRandomUserGenderFolder(String gender) {
    final g = gender.toLowerCase();
    if (g == 'male' || g == 'man') return 'men';
    if (g == 'female' || g == 'woman') return 'women';
    return 'men';
  }

  /// High-quality portrait — picks a different image for variety (using xsgames).
  static String generateHighQualityPortrait(User user) {
    try {
      final String genderFolder = _getXsGamesGenderFolder(user.gender);
      final int index = DateTime.now().millisecondsSinceEpoch % 76;
      return '$_xsgamesBase/$genderFolder/$index.jpg';
    } catch (e) {
      debugPrint('Error generating HQ image URL: $e');
      return generateProfileImageUrl(user);
    }
  }
}
