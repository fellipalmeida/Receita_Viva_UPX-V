import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../modelos/receita.dart';

class ComunidadeService {
  static final ComunidadeService _instance = ComunidadeService._();
  factory ComunidadeService() => _instance;
  ComunidadeService._();

  final _db = FirebaseFirestore.instance;
  static const _colecao = 'posts';

  /// Remove documentos de seed que não devem mais existir.
  Future<void> limparSeedsObsoletos() async {
    const obsoletos = ['seed_5'];
    for (final id in obsoletos) {
      final ref = _db.collection(_colecao).doc(id);
      final doc = await ref.get();
      if (doc.exists) await ref.delete();
    }
  }

  /// Insere posts de exemplo no Firestore se ainda não existirem.
  Future<void> seedSeNecessario() async {
    // Checa pelo ID fixo — funciona mesmo se já houver outros posts na coleção
    final doc = await _db.collection(_colecao).doc('seed_1').get();
    if (doc.exists) return; // seed já foi feito

    final now = DateTime.now();

    final posts = [
      {
        'id': 'seed_1',
        'title': 'Bolo de Cenoura',
        'content': '',
        'author': 'Ana Lima',
        'emoji': '🥕',
        'colorStart': '#FFE0B2',
        'colorEnd': '#FF8A65',
        'category': 'Doces',
        'time': '50 min',
        'servings': '8 porções',
        'difficulty': 'Fácil',
        'rating': 4.8,
        'likes': 3,
        'curtidas': 1,
        'isCommunity': true,
        'ingredients': [
          '3 cenouras médias',
          '3 ovos',
          '1 xícara de óleo',
          '2 xícaras de farinha de trigo',
          '2 xícaras de açúcar',
          '1 colher de sopa de fermento',
        ],
        'steps': [
          'Bata no liquidificador as cenouras, os ovos e o óleo até ficar homogêneo.',
          'Em uma tigela, misture a farinha e o açúcar. Adicione a mistura do liquidificador e mexa bem.',
          'Acrescente o fermento e misture delicadamente.',
          'Despeje em forma untada e asse a 180°C por 35 minutos.',
          'Para a cobertura, derreta chocolate meio amargo com creme de leite e despeje sobre o bolo frio.',
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'id': 'seed_2',
        'title': 'Frango Xadrez',
        'content': '',
        'author': 'Carlos Motta',
        'emoji': '🍗',
        'colorStart': '#FFF3C4',
        'colorEnd': '#FFD980',
        'category': 'Carnes',
        'time': '35 min',
        'servings': '4 porções',
        'difficulty': 'Médio',
        'rating': 4.6,
        'likes': 2,
        'curtidas': 0,
        'isCommunity': true,
        'ingredients': [
          '500g de peito de frango em cubos',
          '1 pimentão vermelho',
          '1 pimentão verde',
          '1 cebola',
          '3 colheres de shoyu',
          '1 colher de amido de milho',
          'Amendoim torrado a gosto',
        ],
        'steps': [
          'Tempere o frango com sal, pimenta e shoyu. Deixe marinar por 15 minutos.',
          'Frite o frango em óleo quente até dourar. Reserve.',
          'Na mesma panela, refogue a cebola e os pimentões em cubos.',
          'Dissolva o amido em um pouco de água e adicione ao refogado.',
          'Junte o frango, misture tudo e finalize com amendoim.',
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      },
      {
        'id': 'seed_3',
        'title': 'Brigadeiro Gourmet',
        'content': '',
        'author': 'Mariana Souza',
        'emoji': '🍫',
        'colorStart': '#D7B49E',
        'colorEnd': '#8B5E3C',
        'category': 'Doces',
        'time': '20 min',
        'servings': '30 unidades',
        'difficulty': 'Fácil',
        'rating': 5.0,
        'likes': 4,
        'curtidas': 2,
        'isCommunity': true,
        'ingredients': [
          '1 lata de leite condensado',
          '3 colheres de cacau em pó 70%',
          '1 colher de manteiga sem sal',
          'Granulado belga para enrolar',
        ],
        'steps': [
          'Em uma panela, misture o leite condensado, o cacau e a manteiga.',
          'Cozinhe em fogo médio, mexendo sempre, até desgrudar do fundo.',
          'Despeje em um prato untado e deixe esfriar completamente.',
          'Enrole em bolinhas e passe no granulado.',
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'id': 'seed_4',
        'title': 'Macarrão ao Alho e Óleo',
        'content': '',
        'author': 'Pedro Alves',
        'emoji': '🍝',
        'colorStart': '#FFF8DC',
        'colorEnd': '#F5D769',
        'category': 'Massas',
        'time': '20 min',
        'servings': '2 porções',
        'difficulty': 'Fácil',
        'rating': 4.7,
        'likes': 2,
        'curtidas': 1,
        'isCommunity': true,
        'ingredients': [
          '200g de espaguete',
          '5 dentes de alho fatiados',
          '4 colheres de azeite extra virgem',
          'Salsinha picada a gosto',
          'Sal e pimenta-do-reino',
          'Parmesão ralado para servir',
        ],
        'steps': [
          'Cozinhe o espaguete em água com sal até al dente. Reserve 1 xícara da água do cozimento.',
          'Em uma frigideira, doure o alho no azeite em fogo baixo sem deixar queimar.',
          'Adicione a massa escorrida e um pouco da água do cozimento. Misture bem.',
          'Finalize com salsinha, pimenta e sirva com parmesão.',
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
      },
    ];

    final batch = _db.batch();
    for (final post in posts) {
      final ref = _db.collection(_colecao).doc(post['id'] as String);
      batch.set(ref, post);
    }
    await batch.commit();
  }

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
      'curtidas': 0,
      'imageUrl': receita.imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isCommunity': true,
    });
  }

  /// Faz upload de uma imagem para o Firebase Storage e retorna a URL pública.
  /// Lança exceção se o upload falhar.
  Future<String> uploadImagemPost(String postId, File imagem) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts/$postId/capa.jpg');
    await ref.putFile(
      imagem,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await ref.getDownloadURL();
  }

  /// Incrementa ou decrementa o contador de likes (coração) de um post.
  Future<void> toggleLike(String postId, {required bool curtiu}) async {
    try {
      await _db.collection(_colecao).doc(postId).update({
        'likes': FieldValue.increment(curtiu ? 1 : -1),
      });
    } catch (_) {}
  }

  /// Incrementa ou decrementa o contador de curtidas (👍) de um post.
  Future<void> toggleCurtida(String postId, {required bool curtiu}) async {
    try {
      await _db.collection(_colecao).doc(postId).update({
        'curtidas': FieldValue.increment(curtiu ? 1 : -1),
      });
    } catch (_) {}
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
        likes: (d['likes'] as num?)?.toInt() ?? 0,
        curtidas: (d['curtidas'] as num?)?.toInt() ?? 0,
        imageUrl: d['imageUrl'] as String?,
      );
    }).toList();
  }
}
