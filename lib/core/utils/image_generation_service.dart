import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';

class ImageGenerationService {
  // Source 1: pravatar.cc (Fast, reliable, 300x300+)
  static const String _pravatarBase = 'https://i.pravatar.cc/300';

  // Source 2: randomuser.me (Low res 128x128 but reliable)
  static const String _randomUserBase = 'https://randomuser.me/api/portraits';

  /// Generates a profile image URL.
  /// Randomly distributes users between pravatar (50%) and randomuser.me (50%)
  static String generateProfileImageUrl(User user) {
    final bool usePravatar = user.id.hashCode.abs() % 2 == 0;
    return usePravatar
        ? _generatePravatarUrl(user)
        : _generateRandomUserUrl(user);
  }

  /// Returns the alternate URL validation source in case the primary fails.
  static String getFallbackUrl(User user, String failedUrl) {
    if (failedUrl.contains('pravatar.cc')) {
      return _generateRandomUserUrl(user);
    } else {
      return _generatePravatarUrl(user);
    }
  }

  static String _generatePravatarUrl(User user) {
    // use a deterministic hash for the user ID to prevent flickering
    final String hash = user.id.hashCode.abs().toString();
    return '$_pravatarBase?u=$hash';
  }

  static String _generateRandomUserUrl(User user) {
    final String genderFolder = _getRandomUserGenderFolder(user.gender);
    // randomuser 0-99 range
    final int index = user.id.hashCode.abs() % 100;
    return '$_randomUserBase/$genderFolder/$index.jpg';
  }

  // --- Helpers ---




  static String _getRandomUserGenderFolder(String gender) {
    final g = gender.toLowerCase();
    if (g == 'male' || g == 'man') return 'men';
    if (g == 'female' || g == 'woman') return 'women';
    return 'men';
  }

  /// High-quality portrait — picks a different image for variety.
  static String generateHighQualityPortrait(User user) {
    try {
      final String hash = (user.id.hashCode.abs() + 7).toString();
      return '$_pravatarBase?u=$hash';
    } catch (e) {
      debugPrint('Error generating HQ image URL: $e');
      return generateProfileImageUrl(user);
    }
  }
}
