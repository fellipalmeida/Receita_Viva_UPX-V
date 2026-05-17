import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';

class RVLogo extends StatelessWidget {
  /// 'sm' = 28px icon / 16px font
  /// 'md' = 38px icon / 20px font  (padrão)
  /// 'lg' = 52px icon / 26px font
  final String size;

  const RVLogo({super.key, this.size = 'md'});

  @override
  Widget build(BuildContext context) {
    final s = size == 'sm' ? 28.0 : size == 'lg' ? 52.0 : 38.0;
    final fs = size == 'sm' ? 16.0 : size == 'lg' ? 26.0 : 20.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(s * 0.28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55D4623A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: Size(s * 0.55, s * 0.55),
              painter: _FlamePainter(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Receita',
                style: GoogleFonts.poppins(
                  fontSize: fs,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: ' Viva',
                style: GoogleFonts.poppins(
                  fontSize: fs,
                  fontWeight: FontWeight.w400,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Escala do viewBox 24×24 para o tamanho real
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // Path 1 — ponta da chama
    final path1 = Path()
      ..moveTo(12, 3)
      ..cubicTo(12, 3, 8.5, 7.5, 8.5, 11.5)
      ..cubicTo(8.5, 12.8, 8.9, 14, 9.6, 14.9)
      ..cubicTo(9.2, 14.1, 9, 13.3, 9, 12.5)
      ..cubicTo(9, 10, 11, 7, 12, 5.5)
      ..cubicTo(13, 7, 15, 10, 15, 12.5)
      ..cubicTo(15, 13.3, 14.8, 14.1, 14.4, 14.9)
      ..cubicTo(15.1, 14, 15.5, 12.8, 15.5, 11.5)
      ..cubicTo(15.5, 7.5, 12, 3, 12, 3)
      ..close();
    canvas.drawPath(path1, Paint()..color = Colors.white);

    // Path 2 — corpo da chama (opacity 0.85)
    final path2 = Path()
      ..moveTo(12, 21)
      ..cubicTo(9.2, 21, 7, 18.8, 7, 16)
      ..cubicTo(7, 13.5, 8.8, 11.5, 10.5, 10.5)
      ..cubicTo(10.2, 11.3, 10, 12.1, 10, 13)
      ..cubicTo(10, 14.9, 11.3, 16.5, 13, 17.1)
      ..cubicTo(13.3, 16.5, 13.5, 15.8, 13.5, 15)
      ..cubicTo(13.5, 14.2, 13.2, 13.5, 12.8, 13)
      ..cubicTo(14.1, 13.6, 15, 14.9, 15, 16.4)
      ..cubicTo(15, 16.5, 15, 16.7, 15, 16.8)
      ..cubicTo(15.6, 15.9, 16, 14.8, 16, 13.7)
      ..cubicTo(16, 12.6, 15.7, 11.6, 15.2, 10.8)
      ..cubicTo(16.9, 12, 18, 13.9, 18, 16)
      ..cubicTo(18, 18.8, 15.3, 21, 12, 21)
      ..close();
    canvas.drawPath(path2, Paint()..color = Colors.white.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
