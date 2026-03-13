import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/image_utils.dart';

/// A reusable avatar widget that shows:
/// 1. The user's image (network/file/asset) if available
/// 2. The user's initials on a gradient background as fallback
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String firstName;
  final String lastName;
  final double radius;
  final ImageProvider? overrideImage;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.firstName,
    required this.lastName,
    this.radius = 60,
    this.overrideImage,
  });

  String get _initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    if (f.isEmpty && l.isEmpty) return '?';
    return '$f$l';
  }

  /// Deterministic gradient based on the user's name
  List<Color> get _gradientColors {
    final hash = ('$firstName$lastName').hashCode.abs();
    final palettes = [
      [const Color(0xFFFF6B9D), const Color(0xFFFE3C72)],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFFFC5C7D), const Color(0xFF6A82FB)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
    ];
    return palettes[hash % palettes.length];
  }

  bool get _hasImage =>
      overrideImage != null ||
      (imageUrl != null &&
          imageUrl!.isNotEmpty &&
          !imageUrl!.contains('default_avatar'));

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ClipOval(
          child: ImageUtils.getImageWidget(
            imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            memCacheWidth: (radius * 4).toInt(),
            memCacheHeight: (radius * 4).toInt(),
          ),
        ),
      );
    }

    // Initials fallback
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: GoogleFonts.poppins(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
