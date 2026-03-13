import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/utils/image_utils.dart';
import '../../domain/entities/user.dart';
import '../../core/utils/image_generation_service.dart';
import '../providers/current_user_provider.dart';
import 'chat_screen.dart';

class MatchScreen extends StatelessWidget {
  final User user;

  const MatchScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'It\'s a Match!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily:
                          'Pacifico', // Or any script font if available, or just standard
                      fontSize: 48,
                      color: Color(0xFFFE3C72),
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<CurrentUserProvider>(
                        builder: (context, userProvider, child) {
                          final currentUser = userProvider.currentUser;
                          return _Avatar(imageUrl: currentUser?.imageUrl ?? '');
                        },
                      ),
                      const SizedBox(width: 20),
                      _Avatar(
                        imageUrl: user.imageUrl.isNotEmpty
                            ? user.imageUrl
                            : ImageGenerationService.generateProfileImageUrl(
                                user,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'You and ${user.firstName} like each other.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(user: user),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFE3C72),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('SEND A MESSAGE'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Keep Swiping',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;

  const _Avatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child:
              imageUrl.isEmpty ||
                  imageUrl.startsWith('assets/') ||
                  imageUrl.startsWith('file://')
              ? ImageUtils.getImageWidget(
                  imageUrl.isEmpty
                      ? 'assets/images/logo_transparent.png'
                      : imageUrl,
                  width: 100,
                  height: 100,
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                  fadeInDuration: const Duration(milliseconds: 150),
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }
}
