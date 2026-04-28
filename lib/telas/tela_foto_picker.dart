import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';

class TelaFotoPicker extends StatefulWidget {
  final String titulo;

  const TelaFotoPicker({super.key, this.titulo = 'Foto de perfil'});

  static const fotos = [
    [Color(0xFFFFE0C4), Color(0xFFFFC080), '🍋'],
    [Color(0xFFD4B0E8), Color(0xFF9B6FC0), '🍄'],
    [Color(0xFFC8F7C5), Color(0xFF82E085), '🌮'],
    [Color(0xFFFFF3C4), Color(0xFFFFD980), '🧀'],
    [Color(0xFFC4E0FF), Color(0xFF6AA8FF), '🦐'],
    [Color(0xFFFFDED6), Color(0xFFFF9A85), '🫐'],
    [Color(0xFFFCE4EC), Color(0xFFF48FB1), '🎂'],
    [Color(0xFFE8F5E9), Color(0xFF81C784), '🥗'],
    [Color(0xFFFFF8E1), Color(0xFFFFCC02), '🍣'],
  ];

  @override
  State<TelaFotoPicker> createState() => _TelaFotoPickerState();
}

class _TelaFotoPickerState extends State<TelaFotoPicker> {
  String _aba = 'galeria';
  int? _selecionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.chipBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.titulo,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _selecionado != null
                        ? () => Navigator.pop(context, _selecionado)
                        : null,
                    child: Text(
                      'Usar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _selecionado != null
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x33D4623A), Color(0x22F5A34E)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x55D4623A),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tirar foto',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Usar câmera agora',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: ['galeria', 'arquivos'].map((aba) {
                    final ativa = _aba == aba;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _aba = aba),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 34,
                          decoration: BoxDecoration(
                            color: ativa ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            aba == 'galeria' ? '🖼️  Galeria' : '📁  Arquivos',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: ativa ? FontWeight.w600 : FontWeight.w400,
                              color: ativa ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: TelaFotoPicker.fotos.length,
                  itemBuilder: (_, i) {
                    final f = TelaFotoPicker.fotos[i];
                    final sel = _selecionado == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selecionado = sel ? null : i),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [f[0] as Color, f[1] as Color],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              f[2] as String,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          if (sel)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
