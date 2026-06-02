import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../dados/dados_mock.dart';
import '../servicos/servico_gemini.dart';
import '../servicos/servico_armazenamento.dart';
import '../config.dart';
import '../main.dart';
import 'tela_receita.dart';
import '../widgets/food_image.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _gemini = GeminiService();
  final _storage = StorageService();

  String _query = '';
  List<String> _alergias = [];
  List<String> _dietas = [];
  String _diffFilter = 'Todos';
  final _diffs = ['Todos', 'Fácil', 'Médio', 'Difícil'];

  Recipe? _aiRecipe;
  bool _aiLoading = false;
  String _submittedQuery = '';

  bool get _apiKeySet => geminiApiKey != 'SUA_CHAVE_AQUI';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    tabNotifier.addListener(_onTabChanged);
    if (widget.initialQuery.isNotEmpty) {
      _query = widget.initialQuery;
      _ctrl.text = widget.initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitSearch());
    }
  }

  void _onTabChanged() {
    if (tabNotifier.value == 5) _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final profile = await _storage.getProfile();
    if (mounted && profile != null) {
      setState(() {
        _alergias = profile.alergias;
        _dietas = profile.dietas;
      });
    }
  }

  @override
  void dispose() {
    tabNotifier.removeListener(_onTabChanged);
    _ctrl.dispose();
    super.dispose();
  }

  List<Recipe> get _results {
    return mockRecipes.where((r) {
      final matchQ = _query.isEmpty ||
          r.title.toLowerCase().contains(_query.toLowerCase()) ||
          r.category.toLowerCase().contains(_query.toLowerCase());
      final matchD = _diffFilter == 'Todos' || r.difficulty == _diffFilter;
      return matchQ && matchD;
    }).toList();
  }

  Future<void> _submitSearch() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _query = q;
      _submittedQuery = q;
      _aiRecipe = null;
      _aiLoading = false;
    });
    if (_results.isEmpty) {
      _generateWithAI(q);
    }
  }

  Future<void> _generateWithAI(String query) async {
    if (!_apiKeySet) {
      _showApiKeyDialog();
      return;
    }
    setState(() {
      _aiLoading = true;
      _aiRecipe = null;
    });
    // Recarrega preferências antes de gerar para garantir que estão atualizadas
    await _loadPreferences();
    try {
      final recipe = await _gemini.generateRecipe(query, alergias: _alergias, dietas: _dietas);
      await _storage.addToHistory(recipe);
      if (mounted) {
        setState(() {
          _aiRecipe = recipe;
          _aiLoading = false;
        });
      }
    } on NotFoodRelatedException {
      if (mounted) {
        setState(() => _aiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sou o Chef IA! Só consigo criar receitas sobre comida e culinária 🍳',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Chave da API necessária',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Configure sua chave Gemini no arquivo lib/config.dart.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _openRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => tabNotifier.value = 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.chipColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 16, color: context.textColor),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Buscar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: context.mutedColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            autofocus: true,
                            style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Receitas, ingredientes, chef...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: context.mutedColor,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _query = v;
                                if (v != _submittedQuery) {
                                  _aiRecipe = null;
                                  _aiLoading = false;
                                }
                              });
                            },
                            onSubmitted: (_) => _submitSearch(),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _ctrl.clear();
                              setState(() {
                                _query = '';
                                _submittedQuery = '';
                                _aiRecipe = null;
                                _aiLoading = false;
                              });
                            },
                            child: Icon(Icons.close, size: 18, color: context.mutedColor),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _diffs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final d = _diffs[i];
                        final active = _diffFilter == d;
                        return GestureDetector(
                          onTap: () => setState(() => _diffFilter = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : context.chipColor,
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
                                color: active ? Colors.white : context.textColor,
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
            Expanded(
              child: _query.isEmpty && _diffFilter == 'Todos'
                  ? _buildPopular()
                  : _results.isEmpty
                      ? _buildEmptyOrAI()
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
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: mockRecipes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ResultCard(
                recipe: mockRecipes[i],
                onTap: () => _openRecipe(mockRecipes[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrAI() {
    if (_aiLoading) return _buildAILoading();
    if (_aiRecipe != null) return _buildAIResult();
    if (_submittedQuery.isNotEmpty && _submittedQuery == _query) {
      return _buildNoResultWithButton();
    }
    return _buildClassicEmpty();
  }

  Widget _buildAILoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gerando com IA...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Buscando a receita perfeita para você',
            style: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Gerado pela IA',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'para "$_submittedQuery"',
                  style: GoogleFonts.poppins(fontSize: 12, color: context.mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ResultCard(
            recipe: _aiRecipe!,
            onTap: () => _openRecipe(_aiRecipe!),
            isAI: true,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _aiRecipe = null;
                _aiLoading = false;
              });
              _generateWithAI(_submittedQuery);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Gerar outra receita',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultWithButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Não encontramos no catálogo',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mas a IA pode criar essa receita para você!',
            style: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _generateWithAI(_submittedQuery),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x44D4623A), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Gerar com IA',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Nenhuma receita encontrada',
            style: GoogleFonts.poppins(fontSize: 15, color: context.mutedColor),
          ),
          if (_query.isNotEmpty) ...[
            Text(
              'para "$_query"',
              style: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Pressione Enter para gerar com IA',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
            style: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ResultCard(
                recipe: _results[i],
                onTap: () => _openRecipe(_results[i]),
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
  final bool isAI;

  const _ResultCard({
    required this.recipe,
    required this.onTap,
    this.isAI = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isAI
              ? Border.all(color: const Color(0x55D4623A), width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            FoodImage(
              recipe: recipe,
              width: 70,
              height: 70,
              borderRadius: BorderRadius.circular(12),
              emojiFontSize: 32,
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
                      color: context.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⏱ ${recipe.time}  ·  👤 ${recipe.servings}',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
                  ),
                  Text(
                    '📊 ${recipe.difficulty}  ·  ⭐ ${recipe.rating}',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: context.mutedColor),
          ],
        ),
      ),
    );
  }
}
