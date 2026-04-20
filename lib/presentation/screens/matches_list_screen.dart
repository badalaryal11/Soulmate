import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../providers/current_user_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class MatchesListScreen extends StatefulWidget {
  /// Whether this tab is currently the active/visible tab.
  /// Set by the parent [HomeScreen] so we can skip needless
  /// Firestore reloads when the user is on a different tab.
  final bool isActive;

  const MatchesListScreen({super.key, this.isActive = true});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MatchProvider>().restoreFromCacheIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && widget.isActive) {
      // Ensure match data survives any lifecycle transition
      final matchProvider = context.read<MatchProvider>();
      matchProvider.restoreFromCacheIfNeeded();
      matchProvider.loadMatches();
    }
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      return user.firstName.toLowerCase().contains(query) ||
          user.lastName.toLowerCase().contains(query) ||
          user.fullName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Matches & Chats',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: isDark ? 0.78 : 0.9,
        ),
        surfaceTintColor: Colors.transparent,
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
              return const [
                PopupMenuItem<String>(
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
            icon: Icon(Icons.more_vert_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Consumer2<MatchProvider, CurrentUserProvider>(
        builder: (context, matchProvider, currentUserProvider, child) {
          final allMatches = matchProvider.matches;
          final filteredMatches = _filterUsers(allMatches);

          final favorites = filteredMatches.where((user) {
            return currentUserProvider.currentUser?.pinnedUserIds.contains(
                  user.id,
                ) ??
                false;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(
                        alpha: isDark ? 0.75 : 0.95,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppThemeTokens.radiusLg,
                      ),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.55),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search matches...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: _SectionHeading(
                  title: 'Favorites',
                  subtitle: 'Pinned matches for quick access',
                ),
              ),
              if (favorites.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No favorites matching "$_searchQuery"'
                          : 'No favorites yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.62,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 104,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        return RepaintBoundary(
                          child: _MatchAvatarItem(
                            user: favorites[index],
                            onTap: () => _openChat(context, favorites[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: _SectionHeading(
                  title: 'Messages',
                  subtitle: 'Recent conversations',
                ),
              ),
              if (filteredMatches.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyMatchesState(
                    isSearchEmpty: _searchQuery.isEmpty,
                    searchQuery: _searchQuery,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final user = filteredMatches[index];
                      return RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MessageListItem(
                            user: user,
                            onTap: () => _openChat(context, user),
                          ),
                        ),
                      );
                    }, childCount: filteredMatches.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ServiceLocator.createChatProvider(),
          child: ChatScreen(user: user),
        ),
      ),
    );
    // Only reload matches when this tab is actually visible.
    // If the user is on the Home or Profile tab, skip the Firestore round-trip.
    if (context.mounted && widget.isActive) {
      context.read<MatchProvider>().loadMatches();
    }
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMatchesState extends StatelessWidget {
  final bool isSearchEmpty;
  final String searchQuery;

  const _EmptyMatchesState({
    required this.isSearchEmpty,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusLg),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSearchEmpty
                  ? Icons.favorite_border_rounded
                  : Icons.search_off_rounded,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.62),
            ),
            const SizedBox(height: 14),
            Text(
              isSearchEmpty ? 'No matches yet' : 'No matches found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearchEmpty
                  ? 'Keep swiping to start more conversations.'
                  : 'No results for "$searchQuery". Try a different name.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchAvatarItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _MatchAvatarItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              UserAvatar(
                radius: 28,
                imageUrl: user.imageUrl,
                firstName: user.firstName,
                lastName: user.lastName,
                heroTag: 'user-avatar-${user.id}-fav',
                isVerified: user.badges.contains('verified'),
                showGlow: false,
                useRoundShape: true,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 64,
                child: Text(
                  user.firstName,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _MessageListItem({required this.user, required this.onTap});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLastMessage =
        user.lastMessage != null && user.lastMessage!.isNotEmpty;
    final subtitleText = hasLastMessage ? user.lastMessage! : 'Say hello! 👋';

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              UserAvatar(
                radius: 26,
                imageUrl: user.imageUrl,
                firstName: user.firstName,
                lastName: user.lastName,
                heroTag: 'user-avatar-${user.id}-msg',
                isVerified: user.badges.contains('verified'),
                showGlow: false,
                useRoundShape: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.firstName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (user.streak > 0) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF9D3D),
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${user.streak}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF9D3D),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasLastMessage
                            ? theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.68,
                              )
                            : colorScheme.primary,
                        fontWeight: hasLastMessage
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (hasLastMessage && user.lastMessageTime != null)
                Text(
                  _formatTime(user.lastMessageTime),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.labelSmall?.color?.withValues(
                      alpha: 0.58,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.iconTheme.color?.withValues(alpha: 0.42),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
