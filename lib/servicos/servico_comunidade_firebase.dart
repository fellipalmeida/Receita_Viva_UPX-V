import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/receita.dart';

class ComunidadeService {
  static final ComunidadeService _instance = ComunidadeService._();
  factory ComunidadeService() => _instance;
  ComunidadeService._();

  final _db = FirebaseFirestore.instance;
  static const _colecao = 'posts';

  Future<void> publicar(Recipe receita) async {
    await _db.collection(_colecao).doc(receita.id).set({
      'id': receita.id,
      'title': receita.title,
      'content': receita.content ?? '',
      'author': receita.author ?? 'Anônimo',
      'emoji': receita.emoji,
      'colorStart': receita.colorStart,
      'colorEnd': receita.colorEnd,
      'category': receita.category,
      'time': receita.time,
      'servings': receita.servings,
      'difficulty': receita.difficulty,
      'rating': receita.rating,
      'ingredients': receita.ingredients,
      'steps': receita.steps,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'isCommunity': true,
    });
  }

  Future<List<Recipe>> getPosts() async {
    final snapshot = await _db
        .collection(_colecao)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final d = doc.data();
      return Recipe(
        id: d['id'] as String,
        title: d['title'] as String,
        content: d['content'] as String?,
        query: d['title'] as String,
        author: d['author'] as String?,
        emoji: d['emoji'] as String? ?? '🍳',
        colorStart: d['colorStart'] as String? ?? '#FFE0B2',
        colorEnd: d['colorEnd'] as String? ?? '#FF8A65',
        category: d['category'] as String? ?? 'Outros',
        time: d['time'] as String? ?? '30 min',
        servings: d['servings'] as String? ?? '4 porções',
        difficulty: d['difficulty'] as String? ?? 'Médio',
        rating: (d['rating'] as num?)?.toDouble() ?? 4.5,
        ingredients: List<String>.from(d['ingredients'] as List? ?? []),
        steps: List<String>.from(d['steps'] as List? ?? []),
        isCommunity: true,
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }
}
