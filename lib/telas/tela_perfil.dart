import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import 'tela_receita.dart';
import 'tela_editar_perfil.dart';
import 'tela_configuracoes.dart';
import 'tela_suporte.dart';
import 'tela_login.dart';
import 'tela_foto_picker.dart';
import '../main.dart';
import '../servicos/servico_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = StorageService();
  String _name = 'Chef';
  String _email = '';
  String _bio = '';
  int? _avatarIndex;
  List<Recipe> _publishedRecipes = [];
  bool _loading = true;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _storage.getProfile();
    final published = await _storage.getCommunityRecipes();
    if (mounted) {
      setState(() {
        _name = profile?.name ?? 'Chef';
        _email = profile?.email ?? '';
        _bio = profile?.bio ?? '';
        _avatarIndex = profile?.avatarIndex;
        _publishedRecipes = published;
        _loading = false;
      });
    }
  }

  String get _handle => _email.isNotEmpty ? '@${_email.split('@').first}' : '@chef';

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'C';
  }

  Future<void> _logout() async {
    await AuthService().sair();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _openEditProfile() {
    setState(() => _showMenu = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil()))
        .then((updated) { if (updated == true) _load(); });
  }

  void _openSettings() {
    setState(() => _showMenu = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaConfiguracoes()));
  }

  void _openSupport() {
    setState(() => _showMenu = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSuporte()));
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildContent(),
          if (_showMenu) _buildMenuOverlay(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCover(),
          _buildAvatar(),
          const SizedBox(height: 14),
          _buildNameBio(),
          const SizedBox(height: 14),
          _buildEditarBtn(),
          const SizedBox(height: 18),
          _buildMinhasReceitas(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return SizedBox(
      height: 75,
      child: Stack(
        children: [
          Container(
            height: 75,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Stack(
              children: [
                Positioned(
                  top: -10, right: -20,
                  child: Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1EFFFFFF),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30, left: 20,
                  child: Container(
                    width: 60, height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x14FFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 14, top: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _showMenu = true),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(56),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Container(
          width: 108, height: 108,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: context.appBg,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(51), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: _avatarIndex != null
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TelaFotoPicker.fotos[_avatarIndex!][0] as Color,
                        TelaFotoPicker.fotos[_avatarIndex!][1] as Color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    TelaFotoPicker.fotos[_avatarIndex!][2] as String,
                    style: const TextStyle(fontSize: 52),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: GoogleFonts.poppins(fontSize: 38, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNameBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(
            _name,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: context.textColor, letterSpacing: -0.3),
          ),
          const SizedBox(height: 2),
          Text(
            _handle,
            style: GoogleFonts.poppins(fontSize: 12, color: context.mutedColor),
          ),
          if (_bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _bio,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: context.textColor, height: 1.55),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditarBtn() {
    return GestureDetector(
      onTap: _openEditProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Editar perfil',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildMinhasReceitas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Minhas Receitas',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: context.textColor)),
              const Spacer(),
              Text('${_publishedRecipes.length} publicadas',
                  style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor)),
            ],
          ),
          const SizedBox(height: 14),
          _publishedRecipes.isEmpty
              ? _buildEmptyGrid()
              : _buildGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyGrid() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'Você ainda não publicou nenhuma receita',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: _publishedRecipes.length,
      itemBuilder: (_, i) {
        final recipe = _publishedRecipes[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x1AD4623A), blurRadius: 8, offset: Offset(0, 2))],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_hexToColor(recipe.colorStart), _hexToColor(recipe.colorEnd)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(recipe.emoji, style: const TextStyle(fontSize: 48)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: context.textColor, height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '⏱ ${recipe.time} · 🔥 ${recipe.difficulty}',
                        style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOverlay() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showMenu = false),
          child: Container(color: Colors.black.withAlpha(102)),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _MenuSheet(
            isDark: themeNotifier.value == ThemeMode.dark,
            onClose: () => setState(() => _showMenu = false),
            onToggleDark: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              setState(() {});
            },
            onEditarPerfil: _openEditProfile,
            onConfiguracoes: _openSettings,
            onSuporte: _openSupport,
            onLogout: _logout,
          ),
        ),
      ],
    );
  }
}

class _MenuSheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onToggleDark;
  final VoidCallback onEditarPerfil;
  final VoidCallback onConfiguracoes;
  final VoidCallback onSuporte;
  final VoidCallback onLogout;

  const _MenuSheet({
    required this.isDark,
    required this.onClose,
    required this.onToggleDark,
    required this.onEditarPerfil,
    required this.onConfiguracoes,
    required this.onSuporte,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
            ),
            // Dark mode toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.borderColor))),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: context.chipColor, shape: BoxShape.circle),
                      child: Icon(Icons.dark_mode_outlined, size: 18, color: context.textColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Modo escuro',
                          style: GoogleFonts.poppins(fontSize: 14, color: context.textColor)),
                    ),
                    GestureDetector(
                      onTap: onToggleDark,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48, height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isDark ? AppColors.primary : context.borderColor,
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 22, height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Menu items
            _MenuItem(icon: Icons.settings_outlined, label: 'Configurações', onTap: onConfiguracoes),
            _MenuItem(icon: Icons.chat_bubble_outline, label: 'Suporte', onTap: onSuporte),
            // Logout
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: context.borderColor))),
              child: _MenuItem(
                icon: Icons.logout,
                label: 'Sair da conta',
                color: const Color(0xFFEF4444),
                onTap: onLogout,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.textColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color != null ? const Color(0x22EF4444) : context.chipColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: c),
              ),
              const SizedBox(width: 14),
              Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 14, color: c,
                    fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
