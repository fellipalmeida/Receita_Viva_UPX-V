import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../dados/dados_mock.dart';
import 'tela_receita.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _diffFilter = 'Todos';
  final _diffs = ['Todos', 'Fácil', 'Médio', 'Difícil'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Recipe> get _results {
    var list = mockRecipes.where((r) {
      final matchQ = _query.isEmpty ||
          r.title.toLowerCase().contains(_query.toLowerCase()) ||
          r.category.toLowerCase().contains(_query.toLowerCase());
      final matchD = _diffFilter == 'Todos' || r.difficulty == _diffFilter;
      return matchQ && matchD;
    }).toList();
    return list;
  }

  void _openRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscar',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            autofocus: true,
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.text),
                            decoration: InputDecoration(
                              hintText: 'Receitas, ingredientes, chef...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _ctrl.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtros
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _diffs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final d = _diffs[i];
                        final active = _diffFilter == d;
                        return GestureDetector(
                          onTap: () => setState(() => _diffFilter = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.chipBg,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: active
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x44D4623A),
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              d,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                color: active ? Colors.white : AppColors.text,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            // Resultados
            Expanded(
              child: _query.isEmpty && _diffFilter == 'Todos'
                  ? _buildPopular()
                  : _results.isEmpty
                      ? _buildEmpty()
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopular() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Populares 🔥',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: mockRecipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ResultCard(
                recipe: mockRecipes[i],
                onTap: () => _openRecipe(mockRecipes[i]),
                hexToColor: _hexToColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Nenhuma receita encontrada',
            style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textMuted),
          ),
          if (_query.isNotEmpty)
            Text(
              'para "$_query"',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_results.length} resultado(s)',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ResultCard(
                recipe: _results[i],
                onTap: () => _openRecipe(_results[i]),
                hexToColor: _hexToColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final Color Function(String) hexToColor;

  const _ResultCard({required this.recipe, required this.onTap, required this.hexToColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      hexToColor(recipe.colorStart),
                      hexToColor(recipe.colorEnd),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(recipe.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⏱ ${recipe.time}  ·  👤 ${recipe.servings}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    '📊 ${recipe.difficulty}  ·  ⭐ ${recipe.rating}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
