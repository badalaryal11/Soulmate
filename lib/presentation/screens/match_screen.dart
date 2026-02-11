import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../providers/user_provider.dart';
import 'chat_screen.dart';

class MatchScreen extends StatelessWidget {
  final User user;

  const MatchScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'It\'s a Match!',
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
            children: [
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final currentUser = userProvider.currentUser;
                  return _Avatar(
                    imageUrl: currentUser?.imageUrl ?? '',
                    isAsset: currentUser?.imageUrl.isEmpty ?? true,
                  );
                },
              ),
              const SizedBox(width: 20),
              _Avatar(imageUrl: user.imageUrl, isAsset: false),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'You and ${user.firstName} like each other.',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
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
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final bool isAsset;

  const _Avatar({required this.imageUrl, required this.isAsset});

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
        backgroundImage: (isAsset || imageUrl.isEmpty)
            ? (imageUrl.isEmpty && !isAsset
                  ? const AssetImage(
                      'assets/images/logo_transparent.png',
                    ) // Fallback if url empty
                  : AssetImage(
                      imageUrl == ''
                          ? 'assets/images/logo_transparent.png'
                          : imageUrl,
                    ))
            : NetworkImage(imageUrl) as ImageProvider,
      ),
    );
  }
}
