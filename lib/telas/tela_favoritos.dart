import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../servicos/servico_comunidade_firebase.dart';
import '../tema/tema_app.dart';
import 'tela_receita.dart';
import '../widgets/food_image.dart';
import '../main.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _storage = StorageService();
  List<Recipe> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    favoritesNotifier.addListener(_load);
  }

  @override
  void dispose() {
    favoritesNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final favs = await _storage.getFavorites();
    if (mounted) setState(() { _favorites = favs; _loading = false; });
  }

  Future<void> _remove(Recipe recipe) async {
    await _storage.removeFavorite(recipe.id);

    // se for receita da comunidade, desfaz o like no Firestore e localmente
    if (recipe.isCommunity) {
      final liked = await _storage.getLikedPosts();
      if (liked.contains(recipe.id)) {
        await _storage.toggleLikedPost(recipe.id);
        await ComunidadeService().toggleLike(recipe.id, curtiu: false);
      }
    }

    favoritesNotifier.value++;
    setState(() => _favorites.removeWhere((r) => r.id == recipe.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removido dos favoritos', style: GoogleFonts.poppins(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Favoritos'),
            if (_favorites.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_favorites.length} salvas',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (_favorites.isNotEmpty) ...[
                    Text('RECEITAS SALVAS',
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: context.mutedColor, letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 10),
                    ..._favorites.asMap().entries.map((e) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: e.key < _favorites.length - 1 ? 12 : 0),
                        child: _buildCard(_favorites[e.key]),
                      );
                    }),
                  ] else
                    _buildEmpty(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❤️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(
            'Sem favoritos ainda',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Salve suas receitas preferidas\npara acessar rapidamente',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Recipe recipe) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            FoodImage(
              recipe: recipe,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(14),
              emojiFontSize: 40,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⏱ ${recipe.time}  ·  ${recipe.servings}',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
                  ),
                  Text(
                    '⭐ ${recipe.rating}  ·  ${recipe.difficulty}',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _remove(recipe),
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  color: Color(0x1AE53935),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Color(0xFFE53935), size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
