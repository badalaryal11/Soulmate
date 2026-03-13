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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate vertical oval dimensions (1:1.2 ratio)
    final width = radius * 2;
    final height = width * 1.2;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Use a rounded rectangle with large radius to create an oval/stadium effect
        // or just use shape: BoxShape.rectangle + borderRadius.
        borderRadius: BorderRadius.all(Radius.elliptical(width / 2, height / 2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE3C72).withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          const borderThickness = 2.0;
          final innerW = w - (borderThickness * 2);
          final innerH = h - (borderThickness * 2);

          return Container(
            padding: const EdgeInsets.all(borderThickness),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFE3C72),
                  const Color(0xFFFE3C72).withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(
                  Radius.elliptical(innerW / 2, innerH / 2)),
              child: Center(
                child: _hasImage
                    ? ImageUtils.getImageWidget(
                        imageUrl,
                        width: innerW,
                        height: innerH,
                        fit: BoxFit.cover,
                        memCacheWidth: (innerW * 2).toInt(),
                        memCacheHeight: (innerH * 2).toInt(),
                      )
                    : Container(
                        width: innerW,
                        height: innerH,
                        decoration: BoxDecoration(
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
                              fontSize: innerW * 0.4,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
