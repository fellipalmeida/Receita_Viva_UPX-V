import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/perfil_usuario.dart';
import '../servicos/servico_armazenamento.dart';
import '../main.dart';
import 'tela_cadastro.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final email = _emailCtrl.text.trim();
    final name = email.isNotEmpty ? email.split('@').first : 'Chef';
    final profile = UserProfile(name: name, email: email);
    await _storage.saveProfile(profile);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainApp()),
      );
    }
  }

  void _goSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                                    Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(52 * 0.28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55D4623A),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'Receita',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          TextSpan(
                            text: ' Viva',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primary,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bem-vindo de volta! 👋',
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
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Esqueceu a senha?',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GradientButton(label: 'Entrar', onTap: _enter),
                  const SizedBox(height: 20),
                                    Row(children: [
                    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou continue com',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _SocialButton(label: 'Google', icon: 'G', onTap: _enter)),
                    const SizedBox(width: 12),
                    Expanded(child: _SocialButton(label: 'Apple', icon: '🍎', onTap: _enter)),
                  ]),
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
                  const SizedBox(height: 20),
                ],
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

  const _GradientButton({required this.label, required this.onTap});

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

class _SocialButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
