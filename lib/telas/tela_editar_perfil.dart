import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../modelos/perfil_usuario.dart';
import '../servicos/servico_armazenamento.dart';
import 'tela_foto_picker.dart';

class TelaEditarPerfil extends StatefulWidget {
  const TelaEditarPerfil({super.key});

  @override
  State<TelaEditarPerfil> createState() => _TelaEditarPerfilState();
}

class _TelaEditarPerfilState extends State<TelaEditarPerfil> {
  final _storage = StorageService();
  final _nomeCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  List<String> _alergias = [];
  int? _avatarIndex;
  bool _salvando = false;
  UserProfile? _perfilOriginal;

  static const _opcoesAlergias = [
    {'id': 'gluten', 'label': 'Glúten', 'emoji': '🌾'},
    {'id': 'lactose', 'label': 'Lactose', 'emoji': '🥛'},
    {'id': 'amendoim', 'label': 'Amendoim', 'emoji': '🥜'},
    {'id': 'frutos_mar', 'label': 'Frutos do mar', 'emoji': '🦐'},
    {'id': 'ovo', 'label': 'Ovos', 'emoji': '🥚'},
    {'id': 'soja', 'label': 'Soja', 'emoji': '🫘'},
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final perfil = await _storage.getProfile();
    if (perfil != null && mounted) {
      _perfilOriginal = perfil;
      setState(() {
        _nomeCtrl.text = perfil.name;
        _usernameCtrl.text =
            perfil.email.isNotEmpty ? perfil.email.split('@').first : '';
        _alergias = List<String>.from(perfil.alergias);
        _avatarIndex = perfil.avatarIndex;
      });
    }
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

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final atualizado = UserProfile(
      name: _nomeCtrl.text.trim().isEmpty
          ? (_perfilOriginal?.name ?? 'Chef')
          : _nomeCtrl.text.trim(),
      email: _perfilOriginal?.email ?? '',
      alergias: _alergias,
      dietas: _perfilOriginal?.dietas ?? [],
      cozinhas: _perfilOriginal?.cozinhas ?? [],
      avatarIndex: _avatarIndex,
    );
    await _storage.saveProfile(atualizado);
    if (mounted) {
      setState(() => _salvando = false);
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _siteCtrl.dispose();
    super.dispose();
  }

  String get _iniciais {
    final nome = _nomeCtrl.text.trim();
    final partes = nome.split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nome.isNotEmpty ? nome[0].toUpperCase() : 'C';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.chipColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: context.textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Editar Perfil',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ),
                  _salvando
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : GestureDetector(
                          onTap: _salvar,
                          child: Text(
                            'Salvar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _abrirFotoPicker,
                                child: Container(
                                  width: 90,
                                  height: 90,
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
                                  ),
                                  alignment: Alignment.center,
                                  child: _avatarIndex != null
                                      ? Text(
                                          TelaFotoPicker.fotos[_avatarIndex!][2] as String,
                                          style: const TextStyle(fontSize: 40),
                                        )
                                      : AnimatedBuilder(
                                          animation: _nomeCtrl,
                                          builder: (_, __) => Text(
                                            _iniciais,
                                            style: GoogleFonts.poppins(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _abrirFotoPicker,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: context.appBg,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _abrirFotoPicker,
                            child: Text(
                              'Alterar foto',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Campo(label: 'Nome', controller: _nomeCtrl),
                    const SizedBox(height: 16),
                    _Campo(label: 'Nome de usuário', controller: _usernameCtrl),
                    const SizedBox(height: 16),
                    _Campo(label: 'Bio', controller: _bioCtrl, multiline: true),
                    const SizedBox(height: 16),
                    _Campo(label: 'Site', controller: _siteCtrl),
                    const SizedBox(height: 20),
                    Divider(color: context.borderColor),
                    const SizedBox(height: 20),
                    Text(
                      'Alergias alimentares',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'O Chef IA usa essas informações para filtrar sugestões',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.mutedColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _opcoesAlergias.map((a) {
                        final ativo = _alergias.contains(a['id']);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (ativo) {
                              _alergias.remove(a['id']);
                            } else {
                              _alergias.add(a['id']!);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: ativo ? AppColors.primary : context.chipColor,
                              borderRadius: BorderRadius.circular(100),
                              border: ativo
                                  ? null
                                  : Border.all(
                                      color: context.borderColor,
                                      width: 1.5,
                                    ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  a['emoji']!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  a['label']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: ativo
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: ativo
                                        ? Colors.white
                                        : context.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: context.borderColor),
                    const SizedBox(height: 20),
                    Text(
                      'Zona de perigo',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0x1AEF4444),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0x55EF4444),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {},
                          child: Center(
                            child: Text(
                              'Excluir conta',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool multiline;

  const _Campo({
    required this.label,
    required this.controller,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.mutedColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: multiline ? 3 : 1,
          style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: multiline ? 12 : 0,
            ),
          ),
        ),
      ],
    );
  }
}
