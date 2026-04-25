import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../dados/dados_mock.dart';
import 'tela_receita.dart';
import 'tela_publicar.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _storage = StorageService();
  Set<String> _likedPosts = {};
  List<Recipe> _userPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final liked = await _storage.getLikedPosts();
    final userPosts = await _storage.getCommunityRecipes();
    if (mounted) {
      setState(() {
        _likedPosts = liked;
        _userPosts = userPosts;
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike(String postId) async {
    await _storage.toggleLikedPost(postId);
    setState(() {
      if (_likedPosts.contains(postId)) {
        _likedPosts.remove(postId);
      } else {
        _likedPosts.add(postId);
      }
    });
  }

  void _openPublish() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublishScreen()),
    );
    _load();
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublish,
        icon: const Icon(Icons.add),
        label: Text('Publicar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                                        SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Comunidade',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _openPublish,
                              child: Container(
                                width: 36, height: 36,
                                decoration: const BoxDecoration(
                                  color: AppColors.cardBg,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x1AD4623A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add, size: 18, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                                        SliverToBoxAdapter(
                      child: SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                                                        _StoryItem(name: 'Você', emoji: '➕', isYou: true, onTap: _openPublish),
                            const SizedBox(width: 12),
                            ...mockStories.map((s) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _StoryItem(
                                    name: s['name']!,
                                    emoji: s['emoji']!,
                                    isYou: false,
                                    onTap: () {},
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                                        SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          if (i < mockCommunityPosts.length) {
                            final post = mockCommunityPosts[i];
                            final postId = post['id'] as String;
                            final liked = _likedPosts.contains(postId);
                            return _PostCard(
                              user: post['user'] as String,
                              time: '${post['time']} atrás',
                              emoji: post['emoji'] as String,
                              title: post['title'] as String,
                              likes: (post['likes'] as int) + (liked ? 1 : 0),
                              comments: post['comments'] as int,
                              colorStart: post['colorStart'] as String,
                              colorEnd: post['colorEnd'] as String,
                              liked: liked,
                              onLike: () => _toggleLike(postId),
                              hexToColor: _hexToColor,
                            );
                          }
                                                    final recipe = _userPosts[i - mockCommunityPosts.length];
                          final liked = _likedPosts.contains(recipe.id);
                          return _PostCard(
                            user: recipe.author ?? 'Você',
                            time: 'recentemente',
                            emoji: recipe.emoji,
                            title: recipe.title,
                            likes: liked ? 1 : 0,
                            comments: 0,
                            colorStart: recipe.colorStart,
                            colorEnd: recipe.colorEnd,
                            liked: liked,
                            onLike: () => _toggleLike(recipe.id),
                            hexToColor: _hexToColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)),
                            ),
                          );
                        },
                        childCount: mockCommunityPosts.length + _userPosts.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isYou;
  final VoidCallback onTap;

  const _StoryItem({
    required this.name,
    required this.emoji,
    required this.isYou,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: isYou ? AppColors.chipBg : const Color(0x33D4623A),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String user;
  final String time;
  final String emoji;
  final String title;
  final int likes;
  final int comments;
  final String colorStart;
  final String colorEnd;
  final bool liked;
  final VoidCallback onLike;
  final Color Function(String) hexToColor;
  final VoidCallback? onTap;

  const _PostCard({
    required this.user,
    required this.time,
    required this.emoji,
    required this.title,
    required this.likes,
    required this.comments,
    required this.colorStart,
    required this.colorEnd,
    required this.liked,
    required this.onLike,
    required this.hexToColor,
    this.onTap,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do post
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(user),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz, size: 20, color: AppColors.textMuted),
                ],
              ),
            ),
            // Imagem do post
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [hexToColor(colorStart), hexToColor(colorEnd)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 90)),
            ),
            // Ações
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ActionBtn(
                        icon: liked ? Icons.favorite : Icons.favorite_border,
                        label: '$likes',
                        active: liked,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline,
                        label: '$comments',
                        active: false,
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.share_outlined,
                        label: 'Compartilhar',
                        active: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

