import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class ImageGenerationService {
  /// Generates a dynamic image URL based on the user's profile.
  /// Uses a prompt-based image generation API (Pollinations.ai as a reliable, free, no-auth proxy for "Nanobanana").
  /// Fast generation for feeds/cards (LoremFlickr)
  static String generateProfileImageUrl(User user) {
    final List<String> keywords = [];
    keywords.add(user.gender.toLowerCase());
    keywords.add('portrait');
    if (user.interests.isNotEmpty) {
      keywords.add(user.interests.first.toLowerCase());
    }

    final String keywordString = keywords.join(',');
    final int lock = user.id.hashCode.abs() % 10000;

    return 'https://loremflickr.com/350/525/$keywordString?lock=$lock';
  }

  /// High-quality generation for user profile (LoremFlickr with specific keywords)
  static String generateHighQualityPortrait(User user) {
    try {
      final List<String> keywords = [];

      // Gender-specific keywords for better results
      if (user.gender.toLowerCase() == 'male' ||
          user.gender.toLowerCase() == 'man') {
        keywords.add('handsome');
        keywords.add('boy');
        keywords.add('man');
      } else if (user.gender.toLowerCase() == 'female' ||
          user.gender.toLowerCase() == 'woman') {
        keywords.add('beautiful');
        keywords.add('girl');
        keywords.add('woman');
      } else {
        keywords.add('portrait');
        keywords.add('person');
      }

      // Add interests for variety
      if (user.interests.isNotEmpty) {
        keywords.add(user.interests.first.toLowerCase());
      }

      final String keywordString = keywords.join(',');

      // Use timestamp as lock to ensure a NEW image on every click
      final int lock = DateTime.now().millisecondsSinceEpoch % 10000;

      // Request a high-quality resolution
      return 'https://loremflickr.com/800/1200/$keywordString?lock=$lock';
    } catch (e) {
      debugPrint('Error generating HQ image URL: $e');
      return generateProfileImageUrl(user); // Fallback to fast
    }
  }
}
