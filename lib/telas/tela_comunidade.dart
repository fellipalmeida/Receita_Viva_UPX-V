import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../servicos/servico_comunidade_firebase.dart';
import '../main.dart';
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
  Set<String> _curtidasPosts = {};
  List<Recipe> _userPosts = [];
  final Map<String, int> _likesCount = {};
  final Map<String, int> _curtidasCount = {};
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
    try {
      final liked = await _storage.getLikedPosts();
      final curtidas = await _storage.getCurtidasPosts();
      await ComunidadeService().limparSeedsObsoletos();
      await ComunidadeService().seedSeNecessario();
      final firestorePosts = await ComunidadeService().getPosts();
      if (mounted) {
        setState(() {
          _likedPosts = liked;
          _curtidasPosts = curtidas;
          _userPosts = firestorePosts;
          for (final p in firestorePosts) {
            _likesCount[p.id] = p.likes;
            _curtidasCount[p.id] = p.curtidas;
          }
          _loading = false;
        });
      }
    } catch (e) {
      print('[Comunidade] erro ao carregar: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(Recipe post) async {
    final postId = post.id;
    final jaLikado = _likedPosts.contains(postId);

    // atualização otimista na UI
    setState(() {
      if (jaLikado) {
        _likedPosts.remove(postId);
        _likesCount[postId] = (_likesCount[postId] ?? 1) - 1;
      } else {
        _likedPosts.add(postId);
        _likesCount[postId] = (_likesCount[postId] ?? 0) + 1;
      }
    });

    // persiste localmente e sincroniza no Firestore
    await _storage.toggleLikedPost(postId);
    await ComunidadeService().toggleLike(postId, curtiu: !jaLikado);

    // sincroniza com favoritos: curtiu = salva, descurtiu = remove
    if (jaLikado) {
      await _storage.removeFavorite(postId);
    } else {
      await _storage.addFavorite(post);
    }
    favoritesNotifier.value++;
  }

  Future<void> _toggleCurtida(String postId) async {
    final jaCurtiu = _curtidasPosts.contains(postId);
    setState(() {
      if (jaCurtiu) {
        _curtidasPosts.remove(postId);
        _curtidasCount[postId] = (_curtidasCount[postId] ?? 1) - 1;
      } else {
        _curtidasPosts.add(postId);
        _curtidasCount[postId] = (_curtidasCount[postId] ?? 0) + 1;
      }
    });
    await _storage.toggleCurtidaPost(postId);
    await ComunidadeService().toggleCurtida(postId, curtiu: !jaCurtiu);
  }

  List<Recipe> get _filteredUserPosts {
    var posts = List<Recipe>.from(_userPosts);
    if (_filter == 'populares') {
      posts.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return posts;
  }

  void _openPublish() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishScreen()));
    _load();
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
    final posts = _filteredUserPosts;

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Nenhuma receita publicada ainda',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: context.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Seja o primeiro a compartilhar uma receita!',
              style: GoogleFonts.poppins(fontSize: 12, color: context.mutedColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final recipe = posts[i];
        return _RecipePostCard(
          recipe: recipe,
          liked: _likedPosts.contains(recipe.id),
          curtido: _curtidasPosts.contains(recipe.id),
          likesCount: _likesCount[recipe.id] ?? recipe.likes,
          curtidasCount: _curtidasCount[recipe.id] ?? recipe.curtidas,
          onLike: () => _toggleLike(recipe),
          onCurtir: () => _toggleCurtida(recipe.id),
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

// ── Card para receitas do usuário (Firestore) ──────────────────

class _RecipePostCard extends StatelessWidget {
  final Recipe recipe;
  final bool liked;
  final bool curtido;
  final int likesCount;
  final int curtidasCount;
  final VoidCallback onLike;
  final VoidCallback onCurtir;
  final VoidCallback onVerReceita;

  const _RecipePostCard({
    required this.recipe,
    required this.liked,
    required this.curtido,
    required this.likesCount,
    required this.curtidasCount,
    required this.onLike,
    required this.onCurtir,
    required this.onVerReceita,
  });

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Widget _buildImagemCard(Recipe recipe) {
    final url = recipe.imageUrl;
    if (url != null) {
      // base64 salvo direto no Firestore (sem Firebase Storage)
      if (url.startsWith('data:')) {
        final base64Str = url.split(',').last;
        try {
          final bytes = base64Decode(base64Str);
          return SizedBox(
            width: double.infinity,
            height: 180,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradienteEmoji(recipe),
            ),
          );
        } catch (_) {
          return _gradienteEmoji(recipe);
        }
      }
      // URL normal (ex: http/https)
      return SizedBox(
        width: double.infinity,
        height: 180,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  width: double.infinity, height: 180,
                  color: _hexToColor(recipe.colorStart).withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child: const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                ),
          errorBuilder: (_, __, ___) => _gradienteEmoji(recipe),
        ),
      );
    }
    return _gradienteEmoji(recipe);
  }

  Widget _gradienteEmoji(Recipe recipe) {
    return Container(
      width: double.infinity, height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_hexToColor(recipe.colorStart), _hexToColor(recipe.colorEnd)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(recipe.emoji, style: const TextStyle(fontSize: 90)),
    );
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
      likes: likesCount,
      curtidas: curtidasCount,
      liked: liked,
      curtido: curtido,
      onLike: onLike,
      onCurtir: onCurtir,
      onVerReceita: onVerReceita,
      imageWidget: _buildImagemCard(recipe),
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
  final int curtidas;
  final bool liked;
  final bool curtido;
  final VoidCallback onLike;
  final VoidCallback onCurtir;
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
    required this.curtidas,
    required this.liked,
    required this.curtido,
    required this.onLike,
    required this.onCurtir,
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
                    Text('publicou $posted', style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor)),
                  ],
                ),
              ],
            ),
          ),
          // Imagem
          imageWidget,
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
                      icon: curtido ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: '$curtidas',
                      active: curtido,
                      onTap: onCurtir,
                    )),
                    Container(width: 1, height: 18, color: context.borderColor),
                    Expanded(child: _ActionBtn(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      label: 'Salvar',
                      active: liked,
                      onTap: onLike,
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
