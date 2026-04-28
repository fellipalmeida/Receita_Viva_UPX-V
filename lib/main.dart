import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema/tema_app.dart';
import 'servicos/servico_armazenamento.dart';
import 'telas/tela_onboarding.dart';
import 'telas/tela_login.dart';
import 'telas/tela_inicio.dart';
import 'telas/tela_busca.dart';
import 'telas/tela_chat.dart';
import 'telas/tela_comunidade.dart';
import 'telas/tela_favoritos.dart';
import 'telas/tela_perfil.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final tabNotifier = ValueNotifier<int>(0);
final searchNotifier = ValueNotifier<String>('');
final favoritesNotifier = ValueNotifier<int>(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  themeNotifier.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', themeNotifier.value == ThemeMode.dark);
  });
  runApp(const ReceitaVivaApp());
}

class ReceitaVivaApp extends StatelessWidget {
  const ReceitaVivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'ReceitaViva',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: const _Splash(),
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final storage = StorageService();
    final profile = await storage.getProfile();
    if (!mounted) return;
    if (profile != null) {
      final done = await storage.isOnboardingDone();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => done ? const MainApp() : const OnboardingScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(72 * 0.28),
                boxShadow: const [
                  BoxShadow(color: Color(0x55D4623A), blurRadius: 20, offset: Offset(0, 6)),
                ],
              ),
              child: const Icon(Icons.local_fire_department, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'Receita',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
                TextSpan(
                  text: ' Viva',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static const _screens = [
    HomeScreen(),
    CommunityScreen(),
    ChatScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabNotifier,
      builder: (_, index, __) {
        final isSearching = index == 5;
        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: isSearching ? 0 : index,
                children: _screens,
              ),
              if (isSearching)
                ValueListenableBuilder<String>(
                  valueListenable: searchNotifier,
                  builder: (_, query, __) => SearchScreen(
                    key: ValueKey(query),
                    initialQuery: query,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            activeIndex: isSearching ? 0 : index,
            onTap: (i) => tabNotifier.value = i,
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.activeIndex, required this.onTap});

  static const _items = [
    _NavItem(id: 0, label: 'Início'),
    _NavItem(id: 1, label: 'Comunidade'),
    _NavItem(id: 2, label: 'Chef IA'),
    _NavItem(id: 3, label: 'Favoritos'),
    _NavItem(id: 4, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: _items.map((item) {
              final active = activeIndex == item.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(item.id),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(item.id, active),
                        size: 22,
                        color: active ? AppColors.primary : context.mutedColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? AppColors.primary : context.mutedColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (active)
                        Container(
                          width: 4, height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(int id, bool active) {
    return switch (id) {
      0 => active ? Icons.home : Icons.home_outlined,
      1 => active ? Icons.people : Icons.people_outline,
      2 => active ? Icons.chat_bubble : Icons.chat_bubble_outline,
      3 => active ? Icons.favorite : Icons.favorite_border,
      4 => active ? Icons.person : Icons.person_outline,
      _ => Icons.circle,
    };
  }
}

class _NavItem {
  final int id;
  final String label;

  const _NavItem({required this.id, required this.label});
}
