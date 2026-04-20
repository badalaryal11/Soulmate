import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/user.dart';
import '../../core/utils/image_generation_service.dart';
import '../../core/theme/app_theme.dart';
import '../screens/details_screen.dart';

class ProfileCard extends StatelessWidget {
  final User user;

  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsScreen(user: user)),
        );
      },
      child: Card(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Use AI Generated Image for Cards to match description
              // Handle local assets
              if (user.imageUrl.startsWith('assets/'))
                Image.asset(
                  user.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error));
                  },
                )
              else if (user.imageUrl.startsWith('file://'))
                Image.file(
                  File(user.imageUrl.substring(7)),
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  cacheHeight: 450,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.error)),
                )
              else
                CachedNetworkImage(
                  // Use original image if valid, otherwise generate one
                  imageUrl:
                      (user.imageUrl.isNotEmpty &&
                          !user.imageUrl.startsWith('assets/') &&
                          !user.imageUrl.startsWith('file://'))
                      ? user.imageUrl
                      : _generateAndLogUrl(user),
                  fit: BoxFit.cover,
                  // Optimization: Match cache dimensions to image source (300x450)
                  memCacheWidth: 300,
                  memCacheHeight: 450,
                  maxWidthDiskCache: 300,
                  // Optimization: Instant appearance (no fade-in) for faster "feel"
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFE3C72),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, errorUrl, error) {
                    // Try fallback URL if primary fails
                    final fallbackUrl = ImageGenerationService.getFallbackUrl(
                      user,
                      errorUrl,
                    );
                    debugPrint(
                      'Image failed: $errorUrl. Trying fallback: $fallbackUrl',
                    );

                    return CachedNetworkImage(
                      imageUrl: fallbackUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      memCacheHeight: 450,
                      maxWidthDiskCache: 300,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFE3C72),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.52, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(
                      AppThemeTokens.radiusMd,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName}, ${user.age}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.26),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.locationString,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                      if (user.interests.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interests
                              .take(3)
                              .map((interest) => _InterestChip(label: interest))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateAndLogUrl(User user) {
    final url = ImageGenerationService.generateProfileImageUrl(user);
    debugPrint('Generated Image URL for ${user.firstName}: $url');
    return url;
  }
}

class _InterestChip extends StatelessWidget {
  final String label;

  const _InterestChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
