import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../tema/tema_app.dart';
import 'tela_publicar.dart';

class RecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeScreen({super.key, required this.recipe});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final _storage = StorageService();
  bool _isFavorite = false;
  bool _tab = true; 
  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await _storage.isFavorite(widget.recipe.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _storage.removeFavorite(widget.recipe.id);
    } else {
      await _storage.addFavorite(widget.recipe);
    }
    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? '❤️ Salvo nos favoritos!' : 'Removido dos favoritos',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final hasStructured = recipe.ingredients.isNotEmpty || recipe.steps.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
                    SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _hexToColor(recipe.colorStart),
                        _hexToColor(recipe.colorEnd),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(recipe.emoji, style: const TextStyle(fontSize: 100)),
                  ),
                ),
                                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x66000000)],
                      ),
                    ),
                  ),
                ),
                                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: _HeroButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF333333)),
                  ),
                ),
                                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: _HeroButton(
                    onTap: _toggleFavorite,
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _isFavorite ? AppColors.primary : const Color(0xFF333333),
                    ),
                  ),
                ),
                                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 64,
                  child: _HeroButton(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublishScreen(recipe: recipe),
                      ),
                    ),
                    child: const Icon(Icons.people_outline, size: 18, color: Color(0xFF333333)),
                  ),
                ),
              ],
            ),
          ),
                    SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                                Text(
                  recipe.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
                                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      _InfoStat(label: '⏱ Tempo', value: recipe.time),
                      _divider(),
                      _InfoStat(label: '👤 Porções', value: recipe.servings),
                      _divider(),
                      _InfoStat(label: '📊 Nível', value: recipe.difficulty),
                      _divider(),
                      _InfoStat(label: '⭐ Nota', value: recipe.rating.toString()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (hasStructured) ...[
                                    Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _TabBtn(
                          label: 'Ingredientes',
                          active: _tab,
                          onTap: () => setState(() => _tab = true),
                        ),
                        _TabBtn(
                          label: 'Modo de preparo',
                          active: !_tab,
                          onTap: () => setState(() => _tab = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_tab)
                    ...recipe.ingredients.map((ing) => _IngredientCard(text: ing))
                  else
                    ...recipe.steps.asMap().entries.map(
                          (e) => _StepCard(index: e.key + 1, text: e.value),
                        ),
                ] else if (recipe.content != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      recipe.content!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.text,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: AppColors.border,
      );
}

class _HeroButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HeroButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 34,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final String text;

  const _IngredientCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x1AD4623A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final String text;

  const _StepCard({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1AD4623A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.text,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
