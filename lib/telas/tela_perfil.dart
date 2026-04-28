import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import 'tela_receita.dart';
import 'tela_favoritos.dart';
import 'tela_historico.dart';
import 'tela_editar_perfil.dart';
import 'tela_configuracoes.dart';
import 'tela_suporte.dart';
import 'tela_login.dart';
import 'tela_foto_picker.dart';
import 'menu_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = StorageService();
  String _name = 'Chef';
  String _email = '';
  int? _avatarIndex;
  int _recipesCount = 0;
  int _favoritesCount = 0;
  int _publishedCount = 0;
  List<Recipe> _publishedRecipes = [];
  String _tab = 'receitas';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _storage.getProfile();
    final history = await _storage.getHistory();
    final favorites = await _storage.getFavorites();
    final published = await _storage.getCommunityRecipes();
    if (mounted) {
      setState(() {
        _name = profile?.name ?? 'Chef';
        _email = profile?.email ?? '';
        _avatarIndex = profile?.avatarIndex;
        _recipesCount = history.length;
        _favoritesCount = favorites.length;
        _publishedCount = published.length;
        _publishedRecipes = published;
        _loading = false;
      });
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'C';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  Positioned(
                    bottom: -44,
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        gradient: _avatarIndex != null
                            ? LinearGradient(
                                colors: [
                                  TelaFotoPicker.fotos[_avatarIndex!][0] as Color,
                                  TelaFotoPicker.fotos[_avatarIndex!][1] as Color,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.appBg, width: 4),
                      ),
                      alignment: Alignment.center,
                      child: _avatarIndex != null
                          ? Text(
                              TelaFotoPicker.fotos[_avatarIndex!][2] as String,
                              style: const TextStyle(fontSize: 40),
                            )
                          : Text(
                              _initials,
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              // Nome
              Text(
                _name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _email.isNotEmpty ? '@${_email.split('@').first}' : '@chef',
                style: GoogleFonts.poppins(fontSize: 12, color: context.mutedColor),
              ),
              const SizedBox(height: 16),
              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(value: '$_recipesCount', label: 'Receitas'),
                    _statDivider(context),
                    _Stat(value: '$_favoritesCount', label: 'Favoritos'),
                    _statDivider(context),
                    _Stat(value: '$_publishedCount', label: 'Publicadas'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Botão editar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33D4623A),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TelaEditarPerfil(),
                              ),
                            ).then((atualizado) {
                              if (atualizado == true) _load();
                            }),
                            child: Center(
                              child: Text(
                                'Editar perfil',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => mostrarMenuSheet(
                        context,
                        nome: _name,
                        email: _email,
                        onLogout: () => Navigator.of(context)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        ),
                        onHistorico: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        ).then((_) => _load()),
                        onFavoritos: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        ).then((_) => _load()),
                        onConfiguracoes: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaConfiguracoes()),
                        ),
                        onSuporte: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaSuporte()),
                        ),
                        onEditarPerfil: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaEditarPerfil()),
                        ).then((atualizado) {
                          if (atualizado == true) _load();
                        }),
                      ),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Icon(Icons.more_horiz, size: 18, color: context.textColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Atalhos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ShortcutBtn(
                        label: 'Favoritos ❤️',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        ).then((_) => _load()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ShortcutBtn(
                        label: 'Histórico 📋',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        ).then((_) => _load()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Abas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _TabItem(
                      label: 'receitas',
                      active: _tab == 'receitas',
                      onTap: () => setState(() => _tab = 'receitas'),
                    ),
                    _TabItem(
                      label: 'curtidas',
                      active: _tab == 'curtidas',
                      onTap: () => setState(() => _tab = 'curtidas'),
                    ),
                  ],
                ),
              ),
              Divider(color: context.borderColor, height: 1),
              // Grid de receitas
              _publishedRecipes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Text('🍳', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma receita publicada ainda',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: context.mutedColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _publishedRecipes.length,
                      itemBuilder: (_, i) {
                        final recipe = _publishedRecipes[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RecipeScreen(recipe: recipe)),
                          ),
                          child: Container(
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
                            alignment: Alignment.center,
                            child: Text(
                              recipe.emoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: context.borderColor,
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
        ),
      ],
    );
  }
}

class _ShortcutBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ShortcutBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.textColor,
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.primary : context.mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}
