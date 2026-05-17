import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../servicos/servico_comunidade_firebase.dart';
import '../dados/dados_mock.dart';
import 'tela_receita.dart';
import 'tela_publicar.dart';
import '../servicos/servico_imagem.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _storage = StorageService();
  Set<String> _likedPosts = {};
  final Set<String> _savedPosts = {};
  List<Recipe> _userPosts = [];
  bool _loading = true;
  String _filter = 'recentes';

  static const _filters = [
    {'id': 'recentes', 'label': 'Recentes'},
    {'id': 'populares', 'label': 'Populares'},
    {'id': 'rede', 'label': 'Da minha rede'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final liked = await _storage.getLikedPosts();
    final firestorePosts = await ComunidadeService().getPosts();
    if (mounted) {
      setState(() {
        _likedPosts = liked;
        _userPosts = firestorePosts;
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

  void _toggleSave(String postId) {
    setState(() {
      if (_savedPosts.contains(postId)) {
        _savedPosts.remove(postId);
      } else {
        _savedPosts.add(postId);
      }
    });
  }

  List<Map<String, dynamic>> get _filteredMockPosts {
    var posts = List<Map<String, dynamic>>.from(mockCommunityPosts);
    if (_filter == 'populares') {
      posts.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
    }
    return posts;
  }

  void _openPublish() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishScreen()));
    _load();
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: _buildFeed(),
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 24,
              right: 20,
              child: _buildFab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comunidade',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22, color: context.textColor, letterSpacing: -0.3)),
              Text('Receitas compartilhadas por cozinheiros',
                  style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(
        children: _filters.map((f) {
          final active = _filter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : context.chipColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  f['label']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? Colors.white : context.textColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      ),
    );
  }

  Widget _buildFeed() {
    final mockPosts = _filteredMockPosts;

    // Combine mock + user posts (user posts come after mocks)
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: mockPosts.length + _userPosts.length,
      itemBuilder: (_, i) {
        if (i < mockPosts.length) {
          final post = mockPosts[i];
          return _MockPostCard(
            post: post,
            liked: _likedPosts.contains(post['id'] as String),
            saved: _savedPosts.contains(post['id'] as String),
            onLike: () => _toggleLike(post['id'] as String),
            onSave: () => _toggleSave(post['id'] as String),
            hexToColor: _hexToColor,
          );
        }
        final recipe = _userPosts[i - mockPosts.length];
        return _RecipePostCard(
          recipe: recipe,
          liked: _likedPosts.contains(recipe.id),
          saved: _savedPosts.contains(recipe.id),
          onLike: () => _toggleLike(recipe.id),
          onSave: () => _toggleSave(recipe.id),
          onVerReceita: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)),
          ),
        );
      },
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _openPublish,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(102), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Publicar receita',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Card para posts do mock ─────────────────────────────────────

class _MockPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final Color Function(String) hexToColor;

  const _MockPostCard({
    required this.post,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.hexToColor,
  });

  @override
  State<_MockPostCard> createState() => _MockPostCardState();
}

class _MockPostCardState extends State<_MockPostCard> {
  String? _fetchedUrl;

  @override
  void initState() {
    super.initState();
    final imageSearchEn = widget.post['imageSearchEn'] as String?;
    if (imageSearchEn != null) _loadImage(imageSearchEn);
  }

  Future<void> _loadImage(String query) async {
    final url = await FoodImageService().fetchImage(widget.post['id'] as String, query);
    if (mounted) setState(() => _fetchedUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return _PostCard(
      id: post['id'] as String,
      user: post['user'] as String,
      posted: '${post['time']} atrás',
      emoji: post['emoji'] as String,
      title: post['title'] as String,
      desc: post['desc'] as String? ?? '',
      timeReceita: post['timeReceita'] as String? ?? '',
      diff: post['diff'] as String? ?? '',
      servings: post['servings'] as String? ?? '',
      rating: (post['rating'] as num?)?.toDouble() ?? 0,
      likes: (post['likes'] as int) + (widget.liked ? 1 : 0),
      liked: widget.liked,
      saved: widget.saved,
      onLike: widget.onLike,
      onSave: widget.onSave,
      onVerReceita: null,
      imageWidget: _buildImage(post),
    );
  }

  Widget _buildImage(Map<String, dynamic> post) {
    if (_fetchedUrl != null) {
      final displayUrl = kIsWeb
          ? 'https://corsproxy.io/?${Uri.encodeComponent(_fetchedUrl!)}'
          : _fetchedUrl!;
      return Image.network(
        displayUrl,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, error, __) {
          if (kDebugMode) print('[Comunidade] erro: $error');
          return _fallback(post);
        },
      );
    }
    return _fallback(post);
  }

  Widget _fallback(Map<String, dynamic> post) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.hexToColor(post['colorStart'] as String), widget.hexToColor(post['colorEnd'] as String)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(post['emoji'] as String, style: const TextStyle(fontSize: 90)),
    );
  }
}

// ── Card para receitas do usuário (Firestore) ──────────────────

class _RecipePostCard extends StatelessWidget {
  final Recipe recipe;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onVerReceita;

  const _RecipePostCard({
    required this.recipe,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.onVerReceita,
  });

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return _PostCard(
      id: recipe.id,
      user: recipe.author ?? 'Você',
      posted: 'recentemente',
      emoji: recipe.emoji,
      title: recipe.title,
      desc: '',
      timeReceita: recipe.time,
      diff: recipe.difficulty,
      servings: recipe.servings,
      rating: recipe.rating,
      likes: liked ? 1 : 0,
      liked: liked,
      saved: saved,
      onLike: onLike,
      onSave: onSave,
      onVerReceita: onVerReceita,
      imageWidget: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_hexToColor(recipe.colorStart), _hexToColor(recipe.colorEnd)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(recipe.emoji, style: const TextStyle(fontSize: 90)),
      ),
    );
  }
}

// ── Widget base de card ────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final String id;
  final String user;
  final String posted;
  final String emoji;
  final String title;
  final String desc;
  final String timeReceita;
  final String diff;
  final String servings;
  final double rating;
  final int likes;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback? onVerReceita;
  final Widget imageWidget;

  const _PostCard({
    required this.id,
    required this.user,
    required this.posted,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.timeReceita,
    required this.diff,
    required this.servings,
    required this.rating,
    required this.likes,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.onVerReceita,
    required this.imageWidget,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Autor
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(_initials(user),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: context.textColor)),
                    Text('publicou há $posted', style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor)),
                  ],
                ),
              ],
            ),
          ),
          // Imagem com badge de rating
          Stack(
            children: [
              imageWidget,
              if (rating > 0)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('⭐ $rating',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: context.textColor)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(desc,
                      style: GoogleFonts.poppins(fontSize: 12, color: context.mutedColor, height: 1.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (timeReceita.isNotEmpty || diff.isNotEmpty || servings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: [
                      if (timeReceita.isNotEmpty) _metaChip('⏱ $timeReceita', context),
                      if (diff.isNotEmpty) _metaChip('🔥 $diff', context),
                      if (servings.isNotEmpty) _metaChip('🍽 $servings', context),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _ActionBtn(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      label: '$likes',
                      active: liked,
                      onTap: onLike,
                    )),
                    Container(width: 1, height: 18, color: context.borderColor),
                    Expanded(child: _ActionBtn(
                      icon: saved ? Icons.bookmark : Icons.bookmark_border,
                      label: 'Salvar',
                      active: saved,
                      onTap: onSave,
                    )),
                    Container(width: 1, height: 18, color: context.borderColor),
                    Expanded(child: _ActionBtn(
                      icon: Icons.arrow_forward,
                      label: 'Ver receita',
                      active: false,
                      onTap: onVerReceita ?? () {},
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _metaChip(String label, BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: context.chipColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: context.textColor)),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : context.mutedColor;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
