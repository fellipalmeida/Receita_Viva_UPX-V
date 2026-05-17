import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/perfil_usuario.dart';
import '../servicos/servico_armazenamento.dart';

class TelaPreferencias extends StatefulWidget {
  const TelaPreferencias({super.key});

  @override
  State<TelaPreferencias> createState() => _TelaPreferenciasState();
}

class _TelaPreferenciasState extends State<TelaPreferencias> {
  final _storage = StorageService();
  List<String> _alergias = [];
  List<String> _dietas = [];
  List<String> _cozinhas = [];
  bool _loading = true;
  bool _salvando = false;
  bool _salvoComSucesso = false;

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final perfil = await _storage.getProfile();
    if (mounted && perfil != null) {
      setState(() {
        _alergias = List.from(perfil.alergias);
        _dietas = List.from(perfil.dietas);
        _cozinhas = List.from(perfil.cozinhas);
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final perfil = await _storage.getProfile();
    final atualizado = UserProfile(
      name: perfil?.name ?? 'Chef',
      email: perfil?.email ?? '',
      bio: perfil?.bio ?? '',
      alergias: _alergias,
      dietas: _dietas,
      cozinhas: _cozinhas,
      avatarIndex: perfil?.avatarIndex,
    );
    await _storage.saveProfile(atualizado);
    if (mounted) {
      setState(() { _salvando = false; _salvoComSucesso = true; });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _salvoComSucesso = false);
      });
    }
  }

  void _toggle(List<String> list, String id) {
    setState(() {
      if (list.contains(id)) {
        list.remove(id);
      } else {
        list.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoBox(),
                          const SizedBox(height: 20),
                          _buildGroup(
                            'Alergias alimentares',
                            'Selecione tudo que você não pode consumir',
                            _alergiasOpts,
                            _alergias,
                          ),
                          const SizedBox(height: 20),
                          _buildGroup(
                            'Dietas que você segue',
                            'Pode escolher mais de uma',
                            _dietasOpts,
                            _dietas,
                          ),
                          const SizedBox(height: 20),
                          _buildGroup(
                            'Cozinhas favoritas',
                            'Quais tipos de cozinha mais te interessam',
                            _cozinhasOpts,
                            _cozinhas,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_salvoComSucesso)
              Positioned(
                bottom: 30,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.textColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 6))],
                    ),
                    child: Text(
                      '✓ Preferências salvas',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.appBg),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: context.chipColor, shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_ios_new, size: 16, color: context.textColor),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Preferências',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: context.textColor)),
            ),
          ),
          _salvando
              ? const SizedBox(
                  width: 36, height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : GestureDetector(
                  onTap: _salvar,
                  child: Text('Salvar',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(20), AppColors.accent.withAlpha(12)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'O Chef IA usa essas preferências para personalizar receitas e filtrar ingredientes que você não pode consumir.',
              style: GoogleFonts.poppins(fontSize: 12, color: context.textColor, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    String title,
    String subtitle,
    List<Map<String, String>> opts,
    List<String> selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: context.textColor)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opts.map((opt) {
            final active = selected.contains(opt['id']);
            return GestureDetector(
              onTap: () => _toggle(selected, opt['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : context.chipColor,
                  borderRadius: BorderRadius.circular(100),
                  border: active ? null : Border.all(color: context.borderColor, width: 1.5),
                  boxShadow: active
                      ? [BoxShadow(color: AppColors.primary.withAlpha(68), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(opt['emoji']!, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      opt['label']!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active ? Colors.white : context.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
