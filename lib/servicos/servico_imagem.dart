import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class FoodImageService {
  static const _base = 'https://api.spoonacular.com/recipes/complexSearch';

  static final Map<String, String?> cache = {};

  bool get _keySet => spoonacularApiKey != 'SUA_CHAVE_AQUI';

  Future<String?> fetchImage(String recipeId, String query) async {
    return null; // Spoonacular desativado temporariamente
    // ignore: dead_code
    if (!_keySet) return null;
    if (cache.containsKey(recipeId)) return cache[recipeId];

    final url = await _search(query);
    cache[recipeId] = url;
    return url;
  }

  Future<String?> _search(String query) async {
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'query': query,
        'number': '1',
        'apiKey': spoonacularApiKey,
      });
      // ignore: avoid_print
      print('[IMG] buscando: $query → $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      // ignore: avoid_print
      print('[IMG] status: ${res.statusCode} para "$query"');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final url = results.first['image'] as String?;
          // ignore: avoid_print
          print('[IMG] imagem: $url');
          return url;
        }
        // ignore: avoid_print
        print('[IMG] nenhum resultado para "$query"');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[IMG] ERRO para "$query": $e');
    }
    return null;
  }
}
