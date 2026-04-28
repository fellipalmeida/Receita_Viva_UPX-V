import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import '../modelos/receita.dart';
import '../servicos/servico_imagem.dart';

class FoodImage extends StatefulWidget {
  final Recipe recipe;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double emojiFontSize;

  const FoodImage({
    required this.recipe,
    this.width,
    this.height,
    this.borderRadius,
    this.emojiFontSize = 36,
    super.key,
  });

  @override
  State<FoodImage> createState() => _FoodImageState();
}

class _FoodImageState extends State<FoodImage> {
  String? _url;

  static Color _hex(String h) {
    final c = h.replaceAll('#', '');
    return Color(int.parse('FF$c', radix: 16));
  }

  String _proxied(String url) {
    if (kIsWeb) return 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    return url;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    if (r.imageUrl != null) {
      _url = r.imageUrl;
    } else if (r.titleEn != null) {
      if (FoodImageService.cache.containsKey(r.id)) {
        _url = FoodImageService.cache[r.id];
      } else {
        _loadImage();
      }
    }
    // sem titleEn → usa emoji fallback direto, sem buscar
  }

  Future<void> _loadImage() async {
    final r = widget.recipe;
    final url = await FoodImageService().fetchImage(r.id, r.titleEn!);
    if (mounted) setState(() => _url = url);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    Widget inner;

    if (_url != null) {
      inner = Image.network(
        _proxied(_url!),
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          if (kDebugMode) print('[FoodImage] erro: $error | url: $_url');
          return _emoji(r);
        },
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: widget.width,
            height: widget.height,
            color: _hex(r.colorStart).withValues(alpha: 0.3),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      inner = _emoji(r);
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: inner);
    }
    return inner;
  }

  Widget _emoji(Recipe r) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hex(r.colorStart), _hex(r.colorEnd)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(r.emoji, style: TextStyle(fontSize: widget.emojiFontSize)),
    );
  }
}
