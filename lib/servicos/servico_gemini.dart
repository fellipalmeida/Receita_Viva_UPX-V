import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config.dart';
import '../modelos/receita.dart';
import 'servico_imagem.dart';

class NotFoodRelatedException implements Exception {}

class GeminiService {
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  late ChatSession _chatSession;

  static const _systemPrompt = '''Você é o Chef IA, um assistente virtual especializado exclusivamente em culinária, receitas, ingredientes, técnicas de preparo, nutrição e alimentação.

REGRAS OBRIGATÓRIAS:
- Responda APENAS perguntas relacionadas a comida, receitas, culinária, ingredientes, técnicas de cozinha, nutrição, dietas e alimentação em geral.
- Se o usuário enviar qualquer mensagem que não tenha relação com esses temas (matemática, programação, política, esportes, piadas, etc.), responda EXATAMENTE com: "Sou o Chef IA e só posso ajudar com assuntos de culinária e alimentação! 🍳 Que tal me perguntar sobre uma receita, ingredientes ou dicas na cozinha?"
- Nunca saia do tema culinário, independentemente do que o usuário pedir.
- Mantenha sempre um tom amigável, animado e apaixonado pela gastronomia.
- Responda sempre em Português Brasileiro.''';

  GeminiService() {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey.trim());
    _chatModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: geminiApiKey.trim(),
      systemInstruction: Content.system(_systemPrompt),
    );
    _resetChat();
  }

  void _resetChat() {
    _chatSession = _chatModel.startChat();
  }

  Future<bool> isFoodQuery(String query) => _isFoodQuery(query);

  Future<bool> _isFoodQuery(String query) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'Responda APENAS com "sim" ou "não", sem mais nada: '
          '"$query" está relacionado a comida, culinária, receitas, ingredientes ou alimentação?',
        ),
      ]);
      final text = (response.text ?? '').toLowerCase().trim();
      return text.startsWith('sim');
    } catch (_) {
      return true;
    }
  }

  Future<String> sendChatMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ?? 'Não consegui responder. Tente novamente!';
    } catch (e, stack) {
      print('[GeminiService] ERRO sendChatMessage: $e');
      print('[GeminiService] STACK: $stack');
      return 'Desculpe, tive um problema de conexão. Tente novamente! 🔌';
    }
  }

  Future<Recipe> generateRecipe(
    String query, {
    bool isIngredients = false,
    bool skipFoodCheck = false,
    List<String> alergias = const [],
    List<String> dietas = const [],
  }) async {
    final topic = isIngredients
        ? 'usando os ingredientes: $query'
        : 'de: $query';

    final restricoes = StringBuffer();
    if (alergias.isNotEmpty) {
      restricoes.writeln('\nRESTRIÇÕES OBRIGATÓRIAS: NÃO use nem mencione: ${alergias.join(', ')}. O usuário tem alergia a esses itens.');
    }
    const dietaDesc = {
      'vegetariano': 'VEGETARIANO — PROIBIDO usar carne, frango, peixe ou frutos do mar. Substitua obrigatoriamente por alternativas vegetarianas (palmito, grão-de-bico, tofu, cogumelos, berinjela, queijo, ovos, etc).',
      'vegano': 'VEGANO — PROIBIDO usar qualquer produto animal: carne, frango, peixe, frutos do mar, leite, manteiga, queijo, ovos ou mel. Use apenas ingredientes 100% vegetais.',
      'low_carb': 'LOW CARB — Evite farinha de trigo, arroz, macarrão, pão, batata e açúcar. Prefira proteínas, gorduras boas e vegetais.',
      'sem_acucar': 'SEM AÇÚCAR — NÃO use açúcar, mel, açúcar mascavo ou adoçantes calóricos em nenhum ingrediente.',
      'mediterranea': 'DIETA MEDITERRÂNEA — Use azeite, peixes, leguminosas, grãos integrais e vegetais. Pouca carne vermelha.',
    };
    final dietasAtivas = dietas.where((d) => d != 'sem_restricao').toList();
    if (dietasAtivas.isNotEmpty) {
      final desc = dietasAtivas.map((d) => dietaDesc[d] ?? d).join('\n');
      restricoes.writeln('\nDIETA OBRIGATÓRIA DO USUÁRIO:\n$desc\nMESMO que o pedido mencione ingredientes proibidos pela dieta, substitua-os obrigatoriamente por alternativas adequadas. NUNCA inclua ingredientes vetados.');
    }

    final prompt = '''Você é um Chef de Cozinha especialista em culinária brasileira e internacional.
Crie uma receita completa em Português Brasileiro $topic.${restricoes.isNotEmpty ? '\n${restricoes.toString().trim()}' : ''}

Responda SOMENTE com JSON válido, sem texto extra, markdown ou explicações:
{
  "title": "Nome da Receita em Português (curto e direto, sem adjetivos como 'fofinho', 'cremoso', 'delicioso')",
  "title_en": "Dish Name in English",
  "time": "X min",
  "servings": "X porções",
  "difficulty": "Fácil",
  "emoji": "🍳",
  "category": "Carnes",
  "ingredients": ["ingrediente 1 com quantidade", "ingrediente 2"],
  "steps": ["Passo 1 completo e detalhado", "Passo 2"]
}

Categorias válidas: Carnes, Massas, Bebidas, Lanches, Doces, Frutos do Mar, Saladas, Sopas, Outros
Dificuldades válidas: Fácil, Médio, Difícil
Inclua pelo menos 4 ingredientes e 3 passos.
NÃO use markdown nos valores (sem asteriscos, sem negrito, texto puro).
''';

    if (!skipFoodCheck && !await _isFoodQuery(query)) throw NotFoodRelatedException();

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonStr = _extractJson(text);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final colors = _categoryColors(data['category'] as String? ?? 'Outros');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final title = data['title'] as String? ?? (isIngredients ? 'Receita com $query' : query);
      final titleEn = data['title_en'] as String?;
      final imageUrl = titleEn != null
          ? await FoodImageService().fetchImage(id, titleEn)
          : null;
      return Recipe(
        id: id,
        title: title,
        titleEn: titleEn,
        query: isIngredients ? 'Ingredientes: $query' : query,
        createdAt: DateTime.now(),
        time: data['time'] as String? ?? '30 min',
        servings: data['servings'] as String? ?? '4 porções',
        difficulty: data['difficulty'] as String? ?? 'Médio',
        rating: 4.5,
        emoji: data['emoji'] as String? ?? '🍳',
        colorStart: colors.$1,
        colorEnd: colors.$2,
        category: data['category'] as String? ?? 'Outros',
        ingredients: (data['ingredients'] as List<dynamic>?)?.cast<String>() ?? [],
        steps: (data['steps'] as List<dynamic>?)?.cast<String>() ?? [],
        imageUrl: imageUrl,
      );
    } catch (_) {
      return Recipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: isIngredients ? 'Receita com $query' : query,
        query: isIngredients ? 'Ingredientes: $query' : query,
        createdAt: DateTime.now(),
        content: '⚠️ Não foi possível gerar a receita. Verifique sua conexão e tente novamente.',
      );
    }
  }

  Future<Recipe> analyzeImage(
    Uint8List imageBytes, {
    List<String> alergias = const [],
    List<String> dietas = const [],
  }) async {
    final restricoes = StringBuffer();
    if (alergias.isNotEmpty) {
      restricoes.writeln('RESTRIÇÕES OBRIGATÓRIAS: NÃO use: ${alergias.join(', ')}.');
    }
    if (dietas.isNotEmpty) {
      restricoes.writeln('DIETA: ${dietas.join(', ')}.');
    }

    final prompt = '''Você é um Chef de Cozinha. Analise a imagem, identifique os ingredientes visíveis e crie uma receita completa em Português Brasileiro.${restricoes.isNotEmpty ? '\n${restricoes.toString().trim()}' : ''}

Responda SOMENTE com JSON válido, sem texto extra:
{
  "title": "Nome da Receita em Português",
  "title_en": "Dish Name in English",
  "time": "X min",
  "servings": "X porções",
  "difficulty": "Fácil",
  "emoji": "🍳",
  "category": "Carnes",
  "ingredients": ["ingrediente 1 com quantidade", "ingrediente 2"],
  "steps": ["Passo 1 completo", "Passo 2"]
}

Categorias válidas: Carnes, Massas, Bebidas, Lanches, Doces, Frutos do Mar, Saladas, Sopas, Outros
Dificuldades válidas: Fácil, Médio, Difícil''';

    try {
      final imagePart = DataPart('image/jpeg', imageBytes);
      final textPart = TextPart(prompt);
      final response = await _model.generateContent([Content.multi([textPart, imagePart])]);
      final text = response.text ?? '';
      final jsonStr = _extractJson(text);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final colors = _categoryColors(data['category'] as String? ?? 'Outros');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      return Recipe(
        id: id,
        title: data['title'] as String? ?? 'Receita da Imagem',
        titleEn: data['title_en'] as String?,
        query: 'Receita por imagem',
        createdAt: DateTime.now(),
        time: data['time'] as String? ?? '30 min',
        servings: data['servings'] as String? ?? '4 porções',
        difficulty: data['difficulty'] as String? ?? 'Médio',
        rating: 4.5,
        emoji: data['emoji'] as String? ?? '🍳',
        colorStart: colors.$1,
        colorEnd: colors.$2,
        category: data['category'] as String? ?? 'Outros',
        ingredients: (data['ingredients'] as List<dynamic>?)?.cast<String>() ?? [],
        steps: (data['steps'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (_) {
      return Recipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Receita da Imagem',
        query: 'Receita por imagem',
        createdAt: DateTime.now(),
        content: '⚠️ Não consegui analisar a imagem. Tente novamente.',
      );
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) return text.substring(start, end + 1);
    return text;
  }

  (String, String) _categoryColors(String category) {
    return switch (category) {
      'Carnes' => ('#FFF3C4', '#FFD980'),
      'Massas' => ('#E8D5C4', '#C9A882'),
      'Bebidas' => ('#D4B0E8', '#9B6FC0'),
      'Lanches' => ('#FFF8DC', '#F5D769'),
      'Doces' => ('#FFE4E1', '#FFB0A0'),
      'Frutos do Mar' => ('#FFE4C0', '#FF9E5E'),
      'Saladas' => ('#C8F7C5', '#82E085'),
      'Sopas' => ('#FFE0A0', '#FFC040'),
      _ => ('#FFE0B2', '#FF8A65'),
    };
  }
}
