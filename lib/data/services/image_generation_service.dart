import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class ImageGenerationService {
  /// Generates a dynamic image URL based on the user's profile.
  /// Uses a prompt-based image generation API (Pollinations.ai as a reliable, free, no-auth proxy for "Nanobanana").
  static String generateProfileImageUrl(User user) {
    try {
      // Switch to LoremFlickr for reliable, keyword-based images.
      // Pollinations.ai is returning 530 errors (server overloaded/blocked).
      // LoremFlickr matches keywords (Gender, Interests) to stock photos.

      final List<String> keywords = [];
      keywords.add(
        user.gender.toLowerCase(),
      ); // 'male' or 'female' or 'man'/'woman'
      keywords.add('portrait'); // Ensure it's a person
      if (user.interests.isNotEmpty) {
        keywords.add(user.interests.first.toLowerCase());
      }

      final String keywordString = keywords.join(',');

      // Use a random cache buster lock (based on ID) to keep the image consistent for the user
      // LoremFlickr uses ?lock= to persist the image for the same ID.
      final int lock = user.id.hashCode.abs() % 10000;

      // optimization: Request 350x525 images.
      // Reduced further for maximum speed as requested.
      // 350px width is sufficient for most phone screens (density adds up).
      return 'https://loremflickr.com/350/525/$keywordString?lock=$lock';

      // Fallback to Picsum for immediate verification (Pollinations might be slow/blocked)
      // This ensures we see SOMETHING.
      // return 'https://picsum.photos/seed/${user.id}/800/1200';
    } catch (e) {
      debugPrint('Error generating image URL: $e');
      return 'https://via.placeholder.com/1024x1024.png?text=Error+Generating+Image';
    }
  }
}
