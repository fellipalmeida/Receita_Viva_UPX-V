import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tema/tema_app.dart';
import '../servicos/servico_armazenamento.dart';
import '../servicos/servico_auth.dart';
import '../widgets/rv_logo.dart';
import '../main.dart';
import 'tela_cadastro.dart';
import 'tela_onboarding.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _storage = StorageService();
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _enter() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Preencha e-mail e senha');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService().entrar(email, password);
      if (!mounted) return;
      final done = await _storage.isOnboardingDone();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => done ? const MainApp() : const OnboardingScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _snack(_authError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) => switch (code) {
    'user-not-found' => 'E-mail não encontrado',
    'wrong-password' => 'Senha incorreta',
    'invalid-email' => 'E-mail inválido',
    'invalid-credential' => 'E-mail ou senha inválidos',
    'user-disabled' => 'Conta desativada',
    'network-request-failed' => 'Sem conexão com a internet',
    _ => 'Erro ao entrar. Tente novamente.',
  };

  void _goSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
                        Positioned(
              top: -60, left: -40,
              child: Container(
                width: 200, height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x18D4623A),
                ),
              ),
            ),
            Positioned(
              top: 60, right: -50,
              child: Container(
                width: 150, height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x14F5A34E),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height
                      - MediaQuery.of(context).padding.top
                      - MediaQuery.of(context).padding.bottom
                      - 64,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Center(child: RVLogo(size: 'lg')),
                    const SizedBox(height: 8),
                    Text(
                      'Descubra receitas feitas para você',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 40),
                    _InputField(
                      controller: _emailCtrl,
                      placeholder: 'E-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      controller: _passwordCtrl,
                      placeholder: 'Senha',
                      icon: Icons.lock_outline,
                      obscure: !_showPassword,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GradientButton(label: 'Entrar', onTap: _enter, loading: _loading),
                    const SizedBox(height: 32),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        'Não tem conta? ',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
                      ),
                      GestureDetector(
                        onTap: _goSignup,
                        child: Text(
                          'Criar conta',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        suffixIcon: suffix,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _GradientButton({required this.label, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x55D4623A), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
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

