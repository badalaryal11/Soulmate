import 'package:flutter/material.dart';
import '../../core/utils/image_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'chat_screen.dart';
import '../../domain/entities/user.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/image_generation_service.dart';
import 'login_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Matches & Chats',
          style: GoogleFonts.poppins(
            color: const Color(0xFFFE3C72),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ServiceLocator.authRepository.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          final matches = provider.matches;
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No matches yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep swiping to find your soulmate!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Text(
                    'New Matches',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFE3C72),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: _MatchAvatarItem(
                          user: matches[index],
                          onTap: () => _openChat(context, matches[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Messages',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFE3C72),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = matches[index];
                    return RepaintBoundary(
                      child: Column(
                        children: [
                          _MessageListItem(
                            user: user,
                            onTap: () => _openChat(context, user),
                          ),
                          if (index < matches.length - 1)
                            const Divider(height: 1), // Separator
                        ],
                      ),
                    );
                  }, childCount: matches.length),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, User user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(user: user)),
    );
  }
}

class _MatchAvatarItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _MatchAvatarItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            ClipOval(
              child: ImageUtils.getImageWidget(
                (user.imageUrl.isNotEmpty &&
                        !user.imageUrl.startsWith('assets/'))
                    ? user.imageUrl
                    : ImageGenerationService.generateProfileImageUrl(user),
                width: 60,
                height: 60,
                memCacheWidth: 200,
                memCacheHeight: 200,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.firstName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _MessageListItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            ClipOval(
              child: ImageUtils.getImageWidget(
                (user.imageUrl.isNotEmpty &&
                        !user.imageUrl.startsWith('assets/'))
                    ? user.imageUrl
                    : ImageGenerationService.generateProfileImageUrl(user),
                width: 56,
                height: 56,
                memCacheWidth: 200,
                memCacheHeight: 200,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.firstName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user.streak > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${user.streak}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Say hello!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
