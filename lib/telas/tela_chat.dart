import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../tema/tema_app.dart';
import '../modelos/receita.dart';
import '../servicos/servico_gemini.dart';
import '../servicos/servico_armazenamento.dart';
import '../config.dart';
import 'tela_receita.dart';
import 'tela_historico.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _gemini = GeminiService();
  final _storage = StorageService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _imagePicker = ImagePicker();
  final _speech = SpeechToText();

  final List<_Msg> _messages = [];
  bool _showTyping = false;
  bool _hasInput = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  List<String> _alergias = [];
  List<String> _dietas = [];

  late final List<AnimationController> _dotControllers;
  late final List<Animation<double>> _dotAnims;

  static const _suggestions = [
    'O que fazer com frango e limão?',
    'Receita vegetariana rápida',
    'Como fazer um bolo fofo?',
  ];

  bool get _apiKeySet => geminiApiKey != 'SUA_CHAVE_AQUI';

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(
      3,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 500)),
    );
    _dotAnims = List.generate(
      3,
      (i) => Tween<double>(begin: 0, end: -5).animate(
        CurvedAnimation(parent: _dotControllers[i], curve: Curves.easeInOut),
      ),
    );
    _messages.add(_Msg.ai(
      text:
          'Olá, Chef! 👨‍🍳 Sou o Chef IA. Posso criar receitas com os ingredientes que você tem, responder dúvidas e personalizar pratos para você. Como posso ajudar?',
    ));
    _loadPreferences();
    _initSpeech();
    tabNotifier.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (tabNotifier.value == 2) _loadPreferences();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (mounted && (status == 'done' || status == 'notListening')) {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadPreferences() async {
    final profile = await _storage.getProfile();
    if (mounted && profile != null) {
      setState(() {
        _alergias = profile.alergias;
        _dietas = profile.dietas;
      });
    }
  }

  @override
  void dispose() {
    tabNotifier.removeListener(_onTabChanged);
    for (final c in _dotControllers) c.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startDots() {
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _dotControllers[i].repeat(reverse: true);
      });
    }
  }

  void _stopDots() {
    for (final c in _dotControllers) {
      c.stop();
      c.reset();
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    await _sendImage(bytes);
  }

  Future<void> _sendImage(Uint8List imageBytes) async {
    if (!_apiKeySet) { _showApiKeyDialog(); return; }
    setState(() {
      _messages.add(_Msg.userImage(imageBytes: imageBytes));
      _showTyping = true;
    });
    _startDots();
    _scrollBottom();
    try {
      final recipe = await _gemini.analyzeImage(imageBytes, alergias: _alergias, dietas: _dietas);
      await _storage.addToHistory(recipe);
      await _storage.addNotification(icon: '🤖', text: 'Chef IA criou "${recipe.title}" para você!');
      if (mounted) {
        _stopDots();
        setState(() { _showTyping = false; _messages.add(_Msg.recipe(recipe: recipe)); });
        _scrollBottom();
      }
    } catch (_) {
      if (mounted) {
        _stopDots();
        setState(() { _showTyping = false; _messages.add(_Msg.ai(text: '⚠️ Não consegui analisar a imagem. Tente novamente.')); });
        _scrollBottom();
      }
    }
  }

  Future<void> _toggleMic() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Microfone não disponível', style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _inputCtrl.text = result.recognizedWords;
            _hasInput = result.recognizedWords.isNotEmpty;
          });
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _send([String? text]) async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
    final msg = (text ?? _inputCtrl.text).trim();
    if (msg.isEmpty) return;
    if (!_apiKeySet) {
      _showApiKeyDialog();
      return;
    }
    _inputCtrl.clear();
    setState(() {
      _hasInput = false;
      _messages.add(_Msg.user(text: msg));
      _showTyping = true;
    });
    _startDots();
    _scrollBottom();

    // Recarrega preferências antes de gerar para garantir que estão atualizadas
    await _loadPreferences();

    // 1. Verificar se é tema culinário (chamada rápida — só retorna sim/não)
    final isFood = await _gemini.isFoodQuery(msg);

    if (!isFood) {
      // Não é culinária — recusa sem gerar receita
      if (mounted) {
        _stopDots();
        setState(() {
          _showTyping = false;
          _messages.add(_Msg.ai(
            text: 'Sou o Chef IA e só posso ajudar com receitas e culinária! 🍳 Me pergunte sobre algum prato, ingrediente ou técnica de cozinha.',
          ));
        });
        _scrollBottom();
      }
      return;
    }

    // 2. É culinária — gerar card de receita (sem re-verificar o tema)
    try {
      final recipe = await _gemini.generateRecipe(
        msg,
        skipFoodCheck: true,
        alergias: _alergias,
        dietas: _dietas,
      );
      if (mounted) {
        _stopDots();
        if (recipe.ingredients.isNotEmpty) {
          await _storage.addToHistory(recipe);
          await _storage.addNotification(
            icon: '🤖',
            text: 'Chef IA criou "${recipe.title}" para você!',
          );
          setState(() {
            _showTyping = false;
            _messages.add(_Msg.recipe(recipe: recipe));
          });
        } else {
          // Receita veio vazia — responde em texto
          final reply = await _gemini.sendChatMessage(msg);
          setState(() {
            _showTyping = false;
            _messages.add(_Msg.ai(text: reply));
          });
        }
        _scrollBottom();
      }
    } catch (_) {
      // Falhou — fallback conversacional
      final reply = await _gemini.sendChatMessage(msg);
      if (mounted) {
        _stopDots();
        setState(() {
          _showTyping = false;
          _messages.add(_Msg.ai(text: reply));
        });
        _scrollBottom();
      }
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Chave da API necessária', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Configure sua chave Gemini no arquivo lib/config.dart.\n\nObtenha gratuitamente em:\naistudio.google.com/app/apikey',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatBg = context.isDark ? const Color(0xFF0F0705) : const Color(0xFFEAE0D8);
    return Scaffold(
      backgroundColor: chatBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                border: Border(bottom: BorderSide(color: context.borderColor)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x44D4623A), blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🤖', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chef IA',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Online agora',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: context.chipColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history, size: 20, color: context.mutedColor),
                    ),
                  ),
                ],
              ),
            ),
            // Mensagens
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                children: [
                  // Label HOJE
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'HOJE',
                        style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._messages.map((m) => _buildMessage(m)),
                  if (_showTyping) _buildTyping(),
                ],
              ),
            ),
            // Sugestões (apenas quando só existe 1 mensagem)
            if (_messages.length == 1)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _send(_suggestions[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x44D4623A), width: 1.5),
                      ),
                      child: Text(
                        _suggestions[i],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Input bar
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 6, 12, MediaQuery.of(context).padding.bottom + 6),
              decoration: BoxDecoration(
                color: context.cardColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: context.chipColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.attach_file, size: 18, color: context.mutedColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: context.inputColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.borderColor, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _inputCtrl,
                        style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Mensagem para o Chef IA...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: context.mutedColor,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 7),
                          suffixIconConstraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                        ),
                        onChanged: (v) => setState(() => _hasInput = v.trim().isNotEmpty),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _hasInput ? _send : _toggleMic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        gradient: _isListening
                            ? const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? const Color(0x55EF4444)
                                : const Color(0x55D4623A),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _hasInput
                            ? Icons.send_rounded
                            : (_isListening ? Icons.mic : Icons.mic_none),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_Msg msg) {
    if (msg.isUser && msg.imageBytes != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              child: Image.memory(
                msg.imageBytes!,
                width: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 2),
            Text('✓ Agora', style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor)),
          ],
        ),
      );
    }
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x44D4623A), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                msg.text!,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, height: 1.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '✓ Agora',
              style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor),
            ),
          ],
        ),
      );
    }
    if (msg.recipe != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AiAvatar(),
            const SizedBox(width: 6),
            Expanded(child: _RecipeBubble(recipe: msg.recipe!, storage: _storage)),
          ],
        ),
      );
    }
    // AI text bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AiAvatar(),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    msg.text!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: context.textColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Agora',
                  style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AiAvatar(),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _dotAnims[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _dotAnims[i].value),
                  child: Container(
                    width: 7, height: 7,
                    margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                    decoration: BoxDecoration(
                      color: context.mutedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text('🤖', style: TextStyle(fontSize: 14)),
    );
  }
}

class _RecipeBubble extends StatefulWidget {
  final Recipe recipe;
  final StorageService storage;

  const _RecipeBubble({required this.recipe, required this.storage});

  @override
  State<_RecipeBubble> createState() => _RecipeBubbleState();
}

class _RecipeBubbleState extends State<_RecipeBubble> {
  bool _saved = false;

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _save() async {
    await widget.storage.addFavorite(widget.recipe);
    favoritesNotifier.value++;
    if (mounted) setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❤️ Salvo nos favoritos!', style: GoogleFonts.poppins(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  topLeft: Radius.circular(4),
                ),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_hexToColor(r.colorStart), _hexToColor(r.colorEnd)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(r.emoji, style: const TextStyle(fontSize: 52)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      children: [
                        _MetaChip(text: '⏱ ${r.time}'),
                        _MetaChip(text: '👤 ${r.servings}'),
                        _MetaChip(text: '📊 ${r.difficulty}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => RecipeScreen(recipe: r)),
                            ),
                            child: Container(
                              height: 34,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Ver receita',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _saved ? null : _save,
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _saved
                                  ? const Color(0x1AD4623A)
                                  : context.chipColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _saved
                                    ? AppColors.primary
                                    : context.borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _saved ? Icons.favorite : Icons.favorite_border,
                                  size: 14,
                                  color: _saved ? AppColors.primary : context.mutedColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _saved ? 'Salvo' : 'Salvar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _saved ? AppColors.primary : context.mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text('Agora', style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor)),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;

  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
      ),
    );
  }
}

class _Msg {
  final bool isUser;
  final String? text;
  final Recipe? recipe;
  final Uint8List? imageBytes;

  const _Msg._({required this.isUser, this.text, this.recipe, this.imageBytes});

  factory _Msg.user({required String text}) => _Msg._(isUser: true, text: text);
  factory _Msg.userImage({required Uint8List imageBytes}) => _Msg._(isUser: true, imageBytes: imageBytes);
  factory _Msg.ai({required String text}) => _Msg._(isUser: false, text: text);
  factory _Msg.recipe({required Recipe recipe}) => _Msg._(isUser: false, recipe: recipe);
}
