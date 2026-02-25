import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/user_model.dart';
import '../../data/datasources/image_generation_service.dart';
import '../screens/details_screen.dart';

class ProfileCard extends StatelessWidget {
  final User user;

  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsScreen(user: user)),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.firstName}, ${user.age}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
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
                    const SizedBox(height: 12),
                    // Bio
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          user.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    // Interests Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: user.interests
                          .take(3)
                          .map((interest) => _InterestChip(label: interest))
                          .toList(),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
