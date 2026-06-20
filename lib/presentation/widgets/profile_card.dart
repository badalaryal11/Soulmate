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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsScreen(user: user)),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        // hardEdge is much cheaper than antiAlias on the GPU
        clipBehavior: Clip.hardEdge,
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Background image ---
              _buildImage(),

              // --- Single merged gradient overlay (top vignette + bottom fade) ---
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x29000000), // 0.16 alpha
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xEB000000), // 0.92 alpha
                    ],
                    stops: [0.0, 0.25, 0.52, 1.0],
                  ),
                ),
              ),

              // --- Info overlay ---
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _InfoOverlay(user: user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final String targetUrl = user.imageUrl.isEmpty 
        ? ImageGenerationService.generateProfileImageUrl(user) 
        : user.imageUrl;

    if (targetUrl.startsWith('assets/')) {
      return Image.asset(
        targetUrl,
        fit: BoxFit.cover,
        cacheWidth: 600, // Optimize memory and decoding time
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.error)),
      );
    }

    if (targetUrl.startsWith('file://')) {
      return Image.file(
        File(targetUrl.substring(7)),
        fit: BoxFit.cover,
        cacheWidth: 600, // Optimize memory and decoding time
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.error)),
      );
    }

    return CachedNetworkImage(
      imageUrl: targetUrl,
      fit: BoxFit.cover,
      memCacheWidth: 600, // Optimize memory and decoding time
      maxWidthDiskCache: 600, // Resize before saving to disk cache
      maxHeightDiskCache: 900,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      // Lightweight placeholder — just a colored box, no spinner
      placeholder: (_, _) => const ColoredBox(color: Color(0xFFEEEEEE)),
      // Lightweight error — no nested CachedNetworkImage
      errorWidget: (_, _, _) => const ColoredBox(
        color: Color(0xFFE0E0E0),
        child: Center(
          child: Icon(Icons.person, color: Colors.grey, size: 48),
        ),
      ),
    );
  }
}

class _InfoOverlay extends StatelessWidget {
  final User user;
  const _InfoOverlay({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0x47000000), // 0.28 alpha
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
        border: Border.all(color: const Color(0x29FFFFFF)), // 0.16 alpha
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${user.firstName}, ${user.age}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Color(0x42000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
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
              style: const TextStyle(
                color: Color(0xE6FFFFFF), // 0.9 alpha
                fontSize: 14,
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
    );
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
        color: const Color(0x2EFFFFFF), // 0.18 alpha
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x40FFFFFF)), // 0.25 alpha
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
