import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../main.dart';

Future<void> mostrarMenuSheet(
  BuildContext context, {
  required String nome,
  required String email,
  required VoidCallback onLogout,
  VoidCallback? onHistorico,
  VoidCallback? onFavoritos,
  VoidCallback? onConfiguracoes,
  VoidCallback? onSuporte,
  VoidCallback? onEditarPerfil,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MenuSheet(
      nome: nome,
      email: email,
      onLogout: onLogout,
      onHistorico: onHistorico,
      onFavoritos: onFavoritos,
      onConfiguracoes: onConfiguracoes,
      onSuporte: onSuporte,
      onEditarPerfil: onEditarPerfil,
    ),
  );
}

class _MenuSheet extends StatefulWidget {
  final String nome;
  final String email;
  final VoidCallback onLogout;
  final VoidCallback? onHistorico;
  final VoidCallback? onFavoritos;
  final VoidCallback? onConfiguracoes;
  final VoidCallback? onSuporte;
  final VoidCallback? onEditarPerfil;

  const _MenuSheet({
    required this.nome,
    required this.email,
    required this.onLogout,
    this.onHistorico,
    this.onFavoritos,
    this.onConfiguracoes,
    this.onSuporte,
    this.onEditarPerfil,
  });

  @override
  State<_MenuSheet> createState() => _MenuSheetState();
}

class _MenuSheetState extends State<_MenuSheet> {
  bool get _modoEscuro => themeNotifier.value == ThemeMode.dark;

  String get _username =>
      widget.email.isNotEmpty ? '@${widget.email.split('@').first}' : '@chef';

  String get _iniciais {
    final partes = widget.nome.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return widget.nome.isNotEmpty ? widget.nome[0].toUpperCase() : 'C';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _iniciais,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nome,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: context.textColor,
                      ),
                    ),
                    Text(
                      _username,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.chipColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dark_mode_outlined,
                    size: 18,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Modo escuro',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: context.textColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    themeNotifier.value = _modoEscuro ? ThemeMode.light : ThemeMode.dark;
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _modoEscuro ? AppColors.primary : context.borderColor,
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: _modoEscuro
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ItemMenu(
            icone: Icons.person_outline,
            label: 'Meu perfil',
            onTap: () {
              Navigator.pop(context);
              widget.onEditarPerfil?.call();
            },
          ),
          _ItemMenu(
            icone: Icons.access_time_outlined,
            label: 'Histórico',
            onTap: () {
              Navigator.pop(context);
              widget.onHistorico?.call();
            },
          ),
          _ItemMenu(
            icone: Icons.favorite_border,
            label: 'Receitas salvas',
            onTap: () {
              Navigator.pop(context);
              widget.onFavoritos?.call();
            },
          ),
          _ItemMenu(
            icone: Icons.settings_outlined,
            label: 'Configurações',
            onTap: () {
              Navigator.pop(context);
              widget.onConfiguracoes?.call();
            },
          ),
          _ItemMenu(
            icone: Icons.chat_bubble_outline,
            label: 'Suporte',
            onTap: () {
              Navigator.pop(context);
              widget.onSuporte?.call();
            },
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: _ItemMenu(
              icone: Icons.logout,
              label: 'Sair da conta',
              cor: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color? cor;
  final VoidCallback onTap;

  const _ItemMenu({
    required this.icone,
    required this.label,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final c = cor ?? context.textColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cor != null
                      ? const Color(0x22EF4444)
                      : context.chipColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 18, color: c),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: c,
                  fontWeight: cor != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
