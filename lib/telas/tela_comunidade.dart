import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../dados/dados_mock.dart';
import 'tela_receita.dart';
import 'tela_publicar.dart';
import '../widgets/food_image.dart';
import '../servicos/servico_imagem.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _storage = StorageService();
  final _searchCtrl = TextEditingController();
  Set<String> _likedPosts = {};
  List<Recipe> _userPosts = [];
  bool _loading = true;
  String _searchQuery = '';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMockPosts {
    if (_searchQuery.isEmpty) return mockCommunityPosts;
    final q = _searchQuery.toLowerCase();
    return mockCommunityPosts
        .where((p) =>
            (p['title'] as String).toLowerCase().contains(q) ||
            (p['user'] as String).toLowerCase().contains(q))
        .toList();
  }

  List<Recipe> get _filteredUserPosts {
    if (_searchQuery.isEmpty) return _userPosts;
    final q = _searchQuery.toLowerCase();
    return _userPosts
        .where((r) =>
            r.title.toLowerCase().contains(q) ||
            (r.author ?? '').toLowerCase().contains(q))
        .toList();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublish,
        icon: const Icon(Icons.add),
        label: Text(
          'Publicar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Comunidade',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _openPublish,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1AD4623A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 18, color: context.mutedColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar na comunidade...',
                                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(Icons.close, size: 16, color: context.mutedColor),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final mockPosts = _filteredMockPosts;
                          final userPosts = _filteredUserPosts;
                          if (i < mockPosts.length) {
                            final post = mockPosts[i];
                            final postId = post['id'] as String;
                            final liked = _likedPosts.contains(postId);
                            return _PostCard(
                              postId: postId,
                              user: post['user'] as String,
                              time: '${post['time']} atrás',
                              emoji: post['emoji'] as String,
                              title: post['title'] as String,
                              imageSearchEn: post['imageSearchEn'] as String?,
                              likes: (post['likes'] as int) + (liked ? 1 : 0),
                              comments: post['comments'] as int,
                              colorStart: post['colorStart'] as String,
                              colorEnd: post['colorEnd'] as String,
                              liked: liked,
                              onLike: () => _toggleLike(postId),
                              hexToColor: _hexToColor,
                            );
                          }
                          final recipe = userPosts[i - mockPosts.length];
                          final liked = _likedPosts.contains(recipe.id);
                          return _PostCard(
                            postId: recipe.id,
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
                            recipe: recipe,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeScreen(recipe: recipe),
                              ),
                            ),
                          );
                        },
                        childCount: _filteredMockPosts.length + _filteredUserPosts.length,
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

class _PostCard extends StatefulWidget {
  final String postId;
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
  final Recipe? recipe;
  final String? imageSearchEn;

  const _PostCard({
    required this.postId,
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
    this.recipe,
    this.imageSearchEn,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  String? _fetchedUrl;

  @override
  void initState() {
    super.initState();
    if (widget.recipe == null && widget.imageSearchEn != null) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = await FoodImageService().fetchImage(widget.postId, widget.imageSearchEn!);
    if (mounted) setState(() => _fetchedUrl = url);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _buildImage() {
    if (widget.recipe != null) {
      return FoodImage(
        recipe: widget.recipe!,
        width: double.infinity,
        height: 200,
        emojiFontSize: 90,
      );
    }

    if (_fetchedUrl != null) {
      final displayUrl = kIsWeb
          ? 'https://corsproxy.io/?${Uri.encodeComponent(_fetchedUrl!)}'
          : _fetchedUrl!;
      return Image.network(
        displayUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          if (kDebugMode) print('[Comunidade] erro: $error | url: $_fetchedUrl');
          return _fallback();
        },
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.hexToColor(widget.colorStart), widget.hexToColor(widget.colorEnd)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(widget.emoji, style: const TextStyle(fontSize: 90)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.borderColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.chipColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(widget.user),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          widget.time,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: context.mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz, size: 20, color: context.mutedColor),
                ],
              ),
            ),
            _buildImage(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: context.textColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ActionBtn(
                        icon: widget.liked ? Icons.favorite : Icons.favorite_border,
                        label: '${widget.likes}',
                        active: widget.liked,
                        onTap: widget.onLike,
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline,
                        label: '${widget.comments}',
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
            color: active ? AppColors.primary : context.mutedColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: active ? AppColors.primary : context.mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
