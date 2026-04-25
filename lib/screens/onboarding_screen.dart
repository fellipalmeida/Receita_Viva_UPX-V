import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _storage = StorageService();

  static const _slides = [
    (
      emoji: '🍳',
      title: 'Descubra receitas incríveis',
      desc:
          'Milhares de receitas para todos os gostos, níveis e ocasiões — do café da manhã ao jantar especial.',
    ),
    (
      emoji: '🤖',
      title: 'Chef IA no seu bolso',
      desc:
          'Diga o que tem na geladeira e nossa IA cria uma receita personalizada só para você.',
    ),
    (
      emoji: '👥',
      title: 'Compartilhe sua paixão',
      desc:
          'Publique suas criações, curta receitas e conecte-se com uma comunidade apaixonada por culinária.',
    ),
  ];

  void _next() async {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      await _storage.setOnboardingDone();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _skip() async {
    await _storage.setOnboardingDone();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_step];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Blobs decorativos
            Positioned(
              top: -80, right: -80,
              child: Container(
                width: 220, height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x22D4623A),
                ),
              ),
            ),
            Positioned(
              bottom: 120, left: -60,
              child: Container(
                width: 160, height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x18F5A34E),
                ),
              ),
            ),
            // Conteúdo
            Column(
              children: [
                // Botão pular
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                    child: _step < 2
                        ? TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Pular',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : const SizedBox(height: 40),
                  ),
                ),
                // Ilustração + texto
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x22D4623A),
                        ),
                        alignment: Alignment.center,
                        child: Text(slide.emoji, style: const TextStyle(fontSize: 80)),
                      ),
                      const SizedBox(height: 36),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              slide.desc,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textMuted,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Dots + botão
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: i == _step ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: i == _step ? AppColors.primary : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _GradientButton(
                        label: _step < 2 ? 'Próximo' : 'Começar',
                        onTap: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55D4623A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
