import 'package:flutter/material.dart';

/// FeedScreen
/// -----------------------------------------------------------------------
/// A polished feed UI containing:
///   1. An enhanced search TextField (rounded, shadowed, with icons)
///   2. A ListView.builder rendering 20 beautifully styled cards
///
/// Drop this file into your project and use `const FeedScreen()` as a
/// route or inside a Scaffold/Navigator.
/// -----------------------------------------------------------------------

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<FeedItem> _allItems = FeedItem.generateDummyList(20);
  List<FeedItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = query.isEmpty
          ? _allItems
          : _allItems
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(query) ||
                      item.subtitle.toLowerCase().contains(query),
                )
                .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            _buildSearchField(),
            _filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return FeedCard(
                        item: item,
                        onTap: () => _showFeedDetailDialog(context, item),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  /// Enhanced search TextField:
  /// - Rounded pill shape
  /// - Soft elevation/shadow
  /// - Leading search icon, trailing clear button (shows only when typing)
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search posts, people, tags...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14.5),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                  onPressed: () => _searchController.clear(),
                );
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Shows an enhanced, animated detail dialog for the tapped feed item.
  void _showFeedDetailDialog(BuildContext context, FeedItem item) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Feed detail',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) => FeedDetailDialog(item: item),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return Opacity(
          opacity: curved.value,
          child: Transform.scale(
            scale: 0.88 + (0.12 * curved.value),
            child: child,
          ),
        );
      },
    );
  }
}

/// -----------------------------------------------------------------------
/// FeedCard — a single beautiful card in the list
/// -----------------------------------------------------------------------
class FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback? onTap;

  const FeedCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: item.color.withOpacity(0.15),
                      child: Text(
                        item.initials,
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.timeAgo,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        color: Colors.grey.shade500,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13.8,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.color.withOpacity(0.85),
                        item.color.withOpacity(0.45),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 40,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statChip(
                      Icons.favorite_rounded,
                      '${item.likes}',
                      Colors.redAccent,
                    ),
                    const SizedBox(width: 14),
                    _statChip(
                      Icons.chat_bubble_rounded,
                      '${item.comments}',
                      Colors.blueAccent,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.bookmark_border_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------------
/// FeedDetailDialog — enhanced dialog shown when a FeedCard is tapped
/// -----------------------------------------------------------------------
class FeedDetailDialog extends StatefulWidget {
  final FeedItem item;

  const FeedDetailDialog({super.key, required this.item});

  @override
  State<FeedDetailDialog> createState() => _FeedDetailDialogState();
}

class _FeedDetailDialogState extends State<FeedDetailDialog> {
  bool _liked = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth > 460 ? 420 : screenWidth,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient banner header
                Stack(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            item.color.withOpacity(0.9),
                            item.color.withOpacity(0.55),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          size: 56,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _RoundIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + name + time
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: item.color.withOpacity(0.15),
                            child: Text(
                              item.initials,
                              style: TextStyle(
                                color: item.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.timeAgo,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 16),

                      // Full description
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        children: [
                          _statPill(
                            icon: _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: '${item.likes + (_liked ? 1 : 0)}',
                            color: Colors.redAccent,
                            active: _liked,
                            onTap: () => setState(() => _liked = !_liked),
                          ),
                          const SizedBox(width: 10),
                          _statPill(
                            icon: Icons.chat_bubble_rounded,
                            label: '${item.comments}',
                            color: Colors.blueAccent,
                            onTap: null,
                          ),
                          const Spacer(),
                          _RoundIconButton(
                            icon: _saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            onTap: () => setState(() => _saved = !_saved),
                            iconColor: _saved
                                ? item.color
                                : Colors.grey.shade500,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required String label,
    required Color color,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round glassy icon button used in the dialog header / actions.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor == null
              ? Colors.black.withOpacity(0.28)
              : const Color(0xFFF5F6FA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor ?? Colors.white),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// FeedItem — simple data model + dummy generator (replace with your API)
/// -----------------------------------------------------------------------
class FeedItem {
  final String title;
  final String subtitle;
  final String timeAgo;
  final int likes;
  final int comments;
  final Color color;
  final IconData icon;

  FeedItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    required this.color,
    required this.icon,
  });

  String get initials {
    final parts = title.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return title.isNotEmpty ? title[0].toUpperCase() : '?';
  }

  static List<FeedItem> generateDummyList(int count) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00BFA6),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFA726),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
    ];
    final icons = [
      Icons.landscape_rounded,
      Icons.music_note_rounded,
      Icons.camera_alt_rounded,
      Icons.sports_basketball_rounded,
      Icons.restaurant_rounded,
      Icons.flight_takeoff_rounded,
      Icons.book_rounded,
      Icons.directions_bike_rounded,
    ];
    final titles = [
      'Sarah Khan',
      'Ahmed Ali',
      'Maria Lopez',
      'James Carter',
      'Fatima Noor',
      'David Kim',
      'Aisha Raza',
      'Tom Becker',
      'Hina Sheikh',
      'Carlos Mendez',
      'Layla Hussain',
      'Ethan Wright',
      'Zara Malik',
      'Noah Bennett',
      'Sana Tariq',
      'Lucas Romero',
      'Amna Yousaf',
      'Ryan Foster',
      'Mehak Iqbal',
      'Daniel Park',
    ];
    final subtitles = [
      'Just finished an amazing hiking trip in the mountains. The view was absolutely breathtaking!',
      'Working on a new music track, can\'t wait to share it with everyone soon.',
      'Captured this incredible sunset during my evening walk yesterday.',
      'Great game last night! Our team played really well in the final quarter.',
      'Tried a new recipe today and it turned out better than expected.',
      'Excited to announce I\'m heading to a new destination next week.',
      'Currently reading a fascinating book about modern architecture.',
      'Morning bike ride through the city was refreshing and peaceful.',
    ];
    final times = [
      '2m ago',
      '15m ago',
      '1h ago',
      '3h ago',
      '5h ago',
      'Yesterday',
      '2 days ago',
    ];

    return List.generate(count, (i) {
      return FeedItem(
        title: titles[i % titles.length],
        subtitle: subtitles[i % subtitles.length],
        timeAgo: times[i % times.length],
        likes: 12 + (i * 7) % 340,
        comments: 1 + (i * 3) % 58,
        color: colors[i % colors.length],
        icon: icons[i % icons.length],
      );
    });
  }
}
