import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../servicos/servico_comunidade_firebase.dart';
import '../tema/tema_app.dart';

class PublishScreen extends StatefulWidget {
  final Recipe? recipe;

  const PublishScreen({super.key, this.recipe});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authorCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _storage = StorageService();
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _titleCtrl.text = widget.recipe!.title;
      if (widget.recipe!.steps.isNotEmpty) {
        _contentCtrl.text = widget.recipe!.steps.join('\n');
      } else {
        _contentCtrl.text = widget.recipe!.content ?? '';
      }
    }
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _publishing = true);
    try {
      final base = widget.recipe;
      final recipe = Recipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        query: _titleCtrl.text.trim(),
        createdAt: DateTime.now(),
        isCommunity: true,
        author: _authorCtrl.text.trim().isEmpty ? 'Anônimo' : _authorCtrl.text.trim(),
        time: base?.time ?? '30 min',
        servings: base?.servings ?? '4 porções',
        difficulty: base?.difficulty ?? 'Médio',
        rating: base?.rating ?? 4.5,
        emoji: base?.emoji ?? '🍳',
        colorStart: base?.colorStart ?? '#FFE0B2',
        colorEnd: base?.colorEnd ?? '#FF8A65',
        category: base?.category ?? 'Outros',
        ingredients: base?.ingredients ?? [],
        steps: base?.steps ?? [],
      );
      await ComunidadeService().publicar(recipe);
      await _storage.addNotification(
        icon: '🍳',
        text: 'Receita "${recipe.title}" publicada na comunidade!',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Receita publicada!', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Receita')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.recipe != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x66C8E6C9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Você está publicando uma receita da IA. Edite à vontade!',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _Label('Seu nome'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _authorCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ex: Maria Silva (opcional)',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              _Label('Título da receita'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ex: Frango assado com ervas',
                  prefixIcon: Icon(Icons.restaurant, color: AppColors.primary, size: 20),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Informe o título' : null,
              ),
              const SizedBox(height: 20),
              _Label('Receita'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentCtrl,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Ingredientes, modo de preparo, dicas...',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (v) => v?.trim().isEmpty == true ? 'Informe a receita' : null,
              ),
              const SizedBox(height: 28),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: _publishing ? null : AppColors.primaryGradient,
                  color: _publishing ? AppColors.chipBg : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _publishing
                      ? null
                      : const [
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
                    onTap: _publishing ? null : _publish,
                    child: Center(
                      child: _publishing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            )
                          : Text(
                              'Publicar na Comunidade',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }
}
