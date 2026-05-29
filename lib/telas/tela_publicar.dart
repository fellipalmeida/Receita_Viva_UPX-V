import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../modelos/receita.dart';
import '../servicos/servico_armazenamento.dart';
import '../servicos/servico_comunidade_firebase.dart';
import '../tema/tema_app.dart';
// Firebase Storage não é usado — imagens são salvas como base64 no Firestore

const _categorias = ['Carnes', 'Massas', 'Doces', 'Sopas', 'Saladas', 'Peixes', 'Frutos do mar', 'Outros'];
const _dificuldades = ['Fácil', 'Médio', 'Difícil'];

const _corsPorCategoria = {
  'Carnes':        ['#FFF3C4', '#FFD980'],
  'Massas':        ['#FFF8DC', '#F5D769'],
  'Doces':         ['#FFE0B2', '#FF8A65'],
  'Sopas':         ['#E8F5E9', '#81C784'],
  'Saladas':       ['#C8F7C5', '#82E085'],
  'Peixes':        ['#B3E5FC', '#4FC3F7'],
  'Frutos do mar': ['#B2EBF2', '#26C6DA'],
  'Outros':        ['#F3E5F5', '#CE93D8'],
};

const _emojiPorCategoria = {
  'Carnes':        '🍗',
  'Massas':        '🍝',
  'Doces':         '🍰',
  'Sopas':         '🍲',
  'Saladas':       '🥗',
  'Peixes':        '🐟',
  'Frutos do mar': '🦐',
  'Outros':        '🍳',
};

class PublishScreen extends StatefulWidget {
  final Recipe? recipe;

  const PublishScreen({super.key, this.recipe});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '30 min');
  final _servingsCtrl = TextEditingController(text: '4 porções');

  String _categoria = 'Outros';
  String _dificuldade = 'Médio';
  String _autorNome = '';

  final _categoriaPersonalizadaCtrl = TextEditingController();

  File? _imagemSelecionada;
  bool _carregandoImagem = false;

  final List<TextEditingController> _ingredientCtrls = [];
  final List<TextEditingController> _stepCtrls = [];

  bool _publishing = false;
  String _publishStatus = '';

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
    _categoriaPersonalizadaCtrl.addListener(() => setState(() {}));
    _carregarPerfil();

    final r = widget.recipe;
    if (r != null) {
      _titleCtrl.text = r.title;
      _timeCtrl.text = r.time;
      _servingsCtrl.text = r.servings;
      _categoria = _categorias.contains(r.category) ? r.category : 'Outros';
      _dificuldade = _dificuldades.contains(r.difficulty) ? r.difficulty : 'Médio';
      for (final ing in r.ingredients) {
        _ingredientCtrls.add(TextEditingController(text: ing));
      }
      for (final step in r.steps) {
        _stepCtrls.add(TextEditingController(text: step));
      }
    }

    if (_ingredientCtrls.isEmpty) _ingredientCtrls.add(TextEditingController());
    if (_stepCtrls.isEmpty) _stepCtrls.add(TextEditingController());
  }

  Future<void> _carregarPerfil() async {
    final profile = await StorageService().getProfile();
    if (mounted && profile != null) {
      setState(() => _autorNome = profile.name.isNotEmpty ? profile.name : 'Anônimo');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    _servingsCtrl.dispose();
    _categoriaPersonalizadaCtrl.dispose();
    for (final c in _ingredientCtrls) { c.dispose(); }
    for (final c in _stepCtrls) { c.dispose(); }
    super.dispose();
  }

  List<String> get _cores => _corsPorCategoria[_categoria] ?? _corsPorCategoria['Outros']!;
  String get _emoji => _emojiPorCategoria[_categoria] ?? '🍳';

  /// Categoria real que será salva — usa o texto personalizado quando "Outros" está selecionado.
  String get _categoriaFinal {
    if (_categoria == 'Outros') {
      final custom = _categoriaPersonalizadaCtrl.text.trim();
      if (custom.isNotEmpty) return custom;
    }
    return _categoria;
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  // ── Picker de imagem ──────────────────────────────────────────
  Future<void> _abrirPicker(ImageSource source) async {
    Navigator.pop(context); // fecha o bottom sheet
    setState(() => _carregandoImagem = true);
    try {
      // Qualidade baixa para manter o base64 abaixo de ~80 KB (limite Firestore: 1 MB)
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 40,
        maxWidth: 500,
      );
      if (picked != null && mounted) {
        setState(() => _imagemSelecionada = File(picked.path));
      }
    } finally {
      if (mounted) setState(() => _carregandoImagem = false);
    }
  }

  void _mostrarOpcoesImagem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              'Adicionar foto',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: context.textColor),
            ),
            const SizedBox(height: 16),
            _OpcaoPicker(
              icon: Icons.photo_library_outlined,
              label: 'Escolher da galeria',
              onTap: () => _abrirPicker(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            _OpcaoPicker(
              icon: Icons.camera_alt_outlined,
              label: 'Tirar foto',
              onTap: () => _abrirPicker(ImageSource.camera),
            ),
            if (_imagemSelecionada != null) ...[
              const SizedBox(height: 8),
              _OpcaoPicker(
                icon: Icons.delete_outline,
                label: 'Remover foto',
                cor: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagemSelecionada = null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Publicar ──────────────────────────────────────────────────
  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredientCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final steps = _stepCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    if (ingredients.isEmpty) { _snack('Adicione pelo menos 1 ingrediente'); return; }
    if (steps.isEmpty) { _snack('Adicione pelo menos 1 passo'); return; }

    setState(() { _publishing = true; _publishStatus = ''; });
    try {
      final postId = DateTime.now().millisecondsSinceEpoch.toString();

      // Codifica a imagem em base64 e salva direto no Firestore (sem Firebase Storage)
      String? imageUrl;
      if (_imagemSelecionada != null) {
        setState(() => _publishStatus = 'Processando imagem...');
        final bytes = await _imagemSelecionada!.readAsBytes();
        imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() => _publishStatus = 'Publicando receita...');
      }

      final recipe = Recipe(
        id: postId,
        title: _titleCtrl.text.trim(),
        query: _titleCtrl.text.trim(),
        createdAt: DateTime.now(),
        isCommunity: true,
        author: _autorNome.isEmpty ? 'Anônimo' : _autorNome,
        emoji: _emoji,
        time: _timeCtrl.text.trim().isEmpty ? '30 min' : _timeCtrl.text.trim(),
        servings: _servingsCtrl.text.trim().isEmpty ? '4 porções' : _servingsCtrl.text.trim(),
        difficulty: _dificuldade,
        rating: widget.recipe?.rating ?? 4.5,
        colorStart: _cores[0],
        colorEnd: _cores[1],
        category: _categoriaFinal,
        ingredients: ingredients,
        steps: steps,
        imageUrl: imageUrl,
      );

      await ComunidadeService().publicar(recipe);
      await StorageService().addNotification(
        icon: '🍳',
        text: 'Receita "${recipe.title}" publicada na comunidade!',
      );
      await StorageService().publishRecipe(recipe);

      if (mounted) {
        _snack('🎉 Receita publicada!', cor: Colors.green.shade600);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', cor: Colors.red.shade700);
    } finally {
      if (mounted) setState(() { _publishing = false; _publishStatus = ''; });
    }
  }

  void _snack(String msg, {Color? cor}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                      child: Text('Publicar receita',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: context.textColor)),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner IA
                      if (widget.recipe != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Receita gerada pela IA carregada. Edite à vontade!',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Título ────────────────────────────
                      _Label('Título da receita'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleCtrl,
                        style: GoogleFonts.poppins(fontSize: 14, color: context.textColor),
                        decoration: InputDecoration(
                          hintText: 'Ex: Frango assado com ervas',
                          hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.mutedColor),
                          prefixIcon: const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 18),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Informe o título' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Preview / foto ────────────────────
                      GestureDetector(
                        onTap: _mostrarOpcoesImagem,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Imagem ou gradiente
                              SizedBox(
                                height: 190,
                                width: double.infinity,
                                child: _carregandoImagem
                                    ? Container(
                                        color: context.chipColor,
                                        alignment: Alignment.center,
                                        child: const CircularProgressIndicator(color: AppColors.primary),
                                      )
                                    : _imagemSelecionada != null
                                        ? Image.file(_imagemSelecionada!, fit: BoxFit.cover)
                                        : Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [_hexToColor(_cores[0]), _hexToColor(_cores[1])],
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(_emoji, style: const TextStyle(fontSize: 88)),
                                          ),
                              ),
                              // Overlay escuro + título
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Color(0xCC000000)],
                                    ),
                                  ),
                                  child: Text(
                                    _titleCtrl.text.isEmpty ? 'Nome da receita' : _titleCtrl.text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.w700,
                                      color: _titleCtrl.text.isEmpty ? Colors.white54 : Colors.white),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // Badge de categoria
                              Positioned(
                                top: 10, right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(_categoriaFinal,
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                              // Botão editar foto
                              Positioned(
                                top: 10, left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _imagemSelecionada != null
                                            ? Icons.edit_outlined
                                            : Icons.add_a_photo_outlined,
                                        size: 14, color: Colors.white),
                                      const SizedBox(width: 5),
                                      Text(
                                        _imagemSelecionada != null ? 'Trocar foto' : 'Adicionar foto',
                                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Categoria ─────────────────────────
                      _Label('Categoria'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _categorias.map((c) {
                          final active = _categoria == c;
                          return GestureDetector(
                            onTap: () => setState(() => _categoria = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: active ? AppColors.primary : context.chipColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(c,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  color: active ? Colors.white : context.textColor)),
                            ),
                          );
                        }).toList(),
                      ),
                      // Campo de categoria personalizada (só aparece quando "Outros")
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: _categoria == 'Outros'
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TextField(
                                  controller: _categoriaPersonalizadaCtrl,
                                  maxLength: 30,
                                  style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Ex: Vegano, Fitness, Japonesa...',
                                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
                                    prefixIcon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // ── Tempo + Porções ───────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _CampoTexto(label: 'Tempo', controller: _timeCtrl,
                              hint: '30 min', icon: Icons.timer_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CampoTexto(label: 'Porções', controller: _servingsCtrl,
                              hint: '4 porções', icon: Icons.people_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Dificuldade ───────────────────────
                      _Label('Dificuldade'),
                      const SizedBox(height: 8),
                      Row(
                        children: _dificuldades.map((d) {
                          final active = _dificuldade == d;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _dificuldade = d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.primary : context.chipColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(d,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                    color: active ? Colors.white : context.textColor)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // ── Ingredientes ──────────────────────
                      _SecaoHeader(emoji: '🥦', titulo: 'Ingredientes'),
                      const SizedBox(height: 10),
                      ..._ingredientCtrls.asMap().entries.map((e) => _ItemIngrediente(
                        controller: e.value,
                        onRemover: _ingredientCtrls.length > 1
                            ? () => setState(() { e.value.dispose(); _ingredientCtrls.removeAt(e.key); })
                            : null,
                      )),
                      _BotaoAdicionar(
                        label: '+ Adicionar ingrediente',
                        onTap: () => setState(() => _ingredientCtrls.add(TextEditingController())),
                      ),
                      const SizedBox(height: 28),

                      // ── Passos ────────────────────────────
                      _SecaoHeader(emoji: '📝', titulo: 'Modo de preparo'),
                      const SizedBox(height: 10),
                      ..._stepCtrls.asMap().entries.map((e) => _ItemPasso(
                        numero: e.key + 1,
                        controller: e.value,
                        onRemover: _stepCtrls.length > 1
                            ? () => setState(() { e.value.dispose(); _stepCtrls.removeAt(e.key); })
                            : null,
                      )),
                      _BotaoAdicionar(
                        label: '+ Adicionar passo',
                        onTap: () => setState(() => _stepCtrls.add(TextEditingController())),
                      ),
                      const SizedBox(height: 36),

                      // ── Publicar ──────────────────────────
                      Container(
                        height: 52, width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: _publishing ? null : AppColors.primaryGradient,
                          color: _publishing ? context.chipColor : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _publishing ? null
                              : const [BoxShadow(color: Color(0x55D4623A), blurRadius: 20, offset: Offset(0, 6))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _publishing ? null : _publish,
                            child: Center(
                              child: _publishing
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 20, height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                        if (_publishStatus.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Text(_publishStatus,
                                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
                                        ],
                                      ],
                                    )
                                  : Text('Publicar na Comunidade',
                                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────

class _OpcaoPicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? cor;
  final VoidCallback onTap;

  const _OpcaoPicker({required this.icon, required this.label, required this.onTap, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? context.textColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cor != null ? const Color(0x11EF4444) : context.chipColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(width: 14),
              Text(label, style: GoogleFonts.poppins(fontSize: 14, color: c, fontWeight: FontWeight.w500)),
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
    return Text(text,
      style: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: context.mutedColor, letterSpacing: 0.3));
  }
}

class _CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _CampoTexto({required this.label, required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          ),
        ),
      ],
    );
  }
}

class _SecaoHeader extends StatelessWidget {
  final String emoji;
  final String titulo;

  const _SecaoHeader({required this.emoji, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(titulo,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: context.textColor)),
      ],
    );
  }
}

// Ingrediente: linha divisória embaixo, sem caixa
class _ItemIngrediente extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onRemover;

  const _ItemIngrediente({required this.controller, this.onRemover});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
              decoration: InputDecoration(
                hintText: 'Ex: 2 xícaras de farinha',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (onRemover != null)
            GestureDetector(
              onTap: onRemover,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: Icon(Icons.close, size: 16, color: context.mutedColor),
              ),
            ),
        ],
      ),
    );
  }
}

// Passo: número laranja + campo multilinha + linha divisória
class _ItemPasso extends StatelessWidget {
  final int numero;
  final TextEditingController controller;
  final VoidCallback? onRemover;

  const _ItemPasso({required this.numero, required this.controller, this.onRemover});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: 22,
            child: Text(
              '$numero.',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
            decoration: InputDecoration(
              hintText: 'Descreva o passo $numero...',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
          if (onRemover != null)
            GestureDetector(
              onTap: onRemover,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 0, 0),
                child: Icon(Icons.close, size: 16, color: context.mutedColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _BotaoAdicionar extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BotaoAdicionar({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
    );
  }
}
