import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modelos/perfil_usuario.dart';
import '../servicos/servico_armazenamento.dart';
import '../servicos/servico_auth.dart';
import '../tema/tema_app.dart';
import 'tela_foto_picker.dart';
import 'tela_onboarding.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  int _step = 0;

    final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _termos = false;

    final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;

    final List<String> _alergias = [];
  final List<String> _dietas = [];
  final List<String> _cozinhas = [];
  int? _avatarIndex;

  final _storage = StorageService();
  bool _loading = false;

  static const _titles = ['Seus dados', 'Sua senha', 'Preferências', 'Foto de perfil'];

  static const _alergiasOpts = [
    {'id': 'gluten', 'label': 'Glúten', 'emoji': '🌾'},
    {'id': 'lactose', 'label': 'Lactose', 'emoji': '🥛'},
    {'id': 'amendoim', 'label': 'Amendoim', 'emoji': '🥜'},
    {'id': 'frutos_mar', 'label': 'Frutos do mar', 'emoji': '🦐'},
    {'id': 'ovo', 'label': 'Ovos', 'emoji': '🥚'},
    {'id': 'soja', 'label': 'Soja', 'emoji': '🫘'},
    {'id': 'nozes', 'label': 'Nozes', 'emoji': '🌰'},
    {'id': 'peixe', 'label': 'Peixe', 'emoji': '🐟'},
  ];

  static const _dietasOpts = [
    {'id': 'vegetariano', 'label': 'Vegetariano', 'emoji': '🥦'},
    {'id': 'vegano', 'label': 'Vegano', 'emoji': '🌱'},
    {'id': 'low_carb', 'label': 'Low Carb', 'emoji': '🥩'},
    {'id': 'sem_acucar', 'label': 'Sem açúcar', 'emoji': '🚫'},
    {'id': 'mediterranea', 'label': 'Mediterrânea', 'emoji': '🫒'},
    {'id': 'sem_restricao', 'label': 'Sem restrição', 'emoji': '✨'},
  ];

  static const _cozinhasOpts = [
    {'id': 'brasileira', 'label': 'Brasileira', 'emoji': '🇧🇷'},
    {'id': 'italiana', 'label': 'Italiana', 'emoji': '🍝'},
    {'id': 'japonesa', 'label': 'Japonesa', 'emoji': '🍣'},
    {'id': 'mexicana', 'label': 'Mexicana', 'emoji': '🌮'},
    {'id': 'americana', 'label': 'Americana', 'emoji': '🍔'},
    {'id': 'francesa', 'label': 'Francesa', 'emoji': '🥐'},
    {'id': 'indiana', 'label': 'Indiana', 'emoji': '🍛'},
    {'id': 'arabe', 'label': 'Árabe', 'emoji': '🧆'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
        _snack('Preencha nome e e-mail');
        return;
      }
      if (!_termos) {
        _snack('Aceite os termos de uso para continuar');
        return;
      }
    }
    if (_step == 1) {
      if (_passwordCtrl.text.length < 6) {
        _snack('Senha deve ter ao menos 6 caracteres');
        return;
      }
      if (_passwordCtrl.text != _confirmCtrl.text) {
        _snack('As senhas não coincidem');
        return;
      }
    }
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _abrirFotoPicker() async {
    final index = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const TelaFotoPicker()),
    );
    if (index != null && mounted) {
      setState(() => _avatarIndex = index);
    }
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      await AuthService().cadastrar(_emailCtrl.text.trim(), _passwordCtrl.text);
      final profile = UserProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        alergias: List.from(_alergias),
        dietas: List.from(_dietas),
        cozinhas: List.from(_cozinhas),
        avatarIndex: _avatarIndex,
      );
      await _storage.saveProfile(profile);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _snack(_authError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) => switch (code) {
    'email-already-in-use' => 'Este e-mail já está em uso',
    'invalid-email' => 'E-mail inválido',
    'weak-password' => 'Senha muito fraca (mínimo 6 caracteres)',
    'network-request-failed' => 'Sem conexão com a internet',
    _ => 'Erro ao criar conta. Tente novamente.',
  };

  void _toggleChip(List<String> list, String id) {
    setState(() {
      if (list.contains(id)) {
        list.remove(id);
      } else {
        list.add(id);
      }
    });
  }

  String get _initials {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Criar conta'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                    Row(
                    children: List.generate(4, (i) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _titles[_step],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Passo ${_step + 1} de 4',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  if (_step == 0) _buildStep0(),
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_step == 3) _buildStep3(),
                ],
              ),
            ),
          ),
                    Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                _GradientBtn(
                  label: _step < 3 ? 'Continuar' : 'Criar conta 🎉',
                  onTap: _next,
                  loading: _loading,
                ),
                if (_step == 2) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _step++),
                    child: Text(
                      'Pular por agora',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        _Field(
          controller: _nameCtrl,
          placeholder: 'Nome completo',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _emailCtrl,
          placeholder: 'E-mail',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => _termos = !_termos),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18, height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: _termos ? AppColors.primary : Colors.transparent,
                ),
                child: _termos
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: 'Concordo com os '),
                      TextSpan(
                        text: 'Termos de Uso',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' e a '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _Field(
          controller: _passwordCtrl,
          placeholder: 'Senha',
          icon: Icons.lock_outline,
          obscure: !_showPass,
          suffix: IconButton(
            icon: Icon(
              _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _confirmCtrl,
          placeholder: 'Confirmar senha',
          icon: Icons.lock_outline,
          obscure: !_showConfirm,
          suffix: IconButton(
            icon: Icon(
              _showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
            onPressed: () => setState(() => _showConfirm = !_showConfirm),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.chipBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use ao menos 6 caracteres com letras e números',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          title: 'Você tem alguma alergia alimentar?',
          subtitle: 'Selecione todas que se aplicam',
        ),
        const SizedBox(height: 10),
        _ChipGroup(
          items: _alergiasOpts,
          selected: _alergias,
          onToggle: (id) => _toggleChip(_alergias, id),
        ),
        const SizedBox(height: 22),
        _SectionLabel(
          title: 'Preferências alimentares',
          subtitle: 'Seguimos alguma dieta especial?',
        ),
        const SizedBox(height: 10),
        _ChipGroup(
          items: _dietasOpts,
          selected: _dietas,
          onToggle: (id) => _toggleChip(_dietas, id),
        ),
        const SizedBox(height: 22),
        _SectionLabel(
          title: 'Culinárias favoritas',
          subtitle: 'Quais tipos de cozinha você mais curte?',
        ),
        const SizedBox(height: 10),
        _ChipGroup(
          items: _cozinhasOpts,
          selected: _cozinhas,
          onToggle: (id) => _toggleChip(_cozinhas, id),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            '💡 Essas informações ajudam o Chef IA a sugerir\nreceitas perfeitas para você',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final hasAvatar = _avatarIndex != null;
    final foto = hasAvatar ? TelaFotoPicker.fotos[_avatarIndex!] : null;

    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _abrirFotoPicker,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: hasAvatar
                        ? LinearGradient(
                            colors: [foto![0] as Color, foto[1] as Color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44D4623A),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: hasAvatar
                      ? Text(
                          foto![2] as String,
                          style: const TextStyle(fontSize: 54),
                        )
                      : Text(
                          _initials,
                          style: GoogleFonts.poppins(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _abrirFotoPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        hasAvatar ? 'Trocar foto' : 'Escolher foto',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Opcional — você pode adicionar depois',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        suffixIcon: suffix,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<Map<String, String>> items;
  final List<String> selected;
  final void Function(String) onToggle;

  const _ChipGroup({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final id = item['id']!;
        final active = selected.contains(id);
        return GestureDetector(
          onTap: () => onToggle(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.chipBg,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
              boxShadow: active
                  ? const [BoxShadow(color: Color(0x44D4623A), blurRadius: 10, offset: Offset(0, 3))]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['emoji']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  item['label']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? Colors.white : AppColors.text,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check, size: 12, color: Colors.white),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _GradientBtn({required this.label, required this.onTap, this.loading = false});

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
