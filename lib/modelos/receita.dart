import 'dart:convert';

class Recipe {
  final String id;
  final String title;
  final String? content;
  final String query;
  final DateTime createdAt;
  final bool isCommunity;
  final String? author;
  final String time;
  final String servings;
  final String difficulty;
  final double rating;
  final String emoji;
  final String colorStart;
  final String colorEnd;
  final String category;
  final List<String> ingredients;
  final List<String> steps;

  Recipe({
    required this.id,
    required this.title,
    this.content,
    required this.query,
    required this.createdAt,
    this.isCommunity = false,
    this.author,
    this.time = '30 min',
    this.servings = '4 porções',
    this.difficulty = 'Médio',
    this.rating = 4.5,
    this.emoji = '🍳',
    this.colorStart = '#FFE0B2',
    this.colorEnd = '#FF8A65',
    this.category = 'Outros',
    this.ingredients = const [],
    this.steps = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'query': query,
        'createdAt': createdAt.toIso8601String(),
        'isCommunity': isCommunity,
        'author': author,
        'time': time,
        'servings': servings,
        'difficulty': difficulty,
        'rating': rating,
        'emoji': emoji,
        'colorStart': colorStart,
        'colorEnd': colorEnd,
        'category': category,
        'ingredients': ingredients,
        'steps': steps,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String?,
        query: json['query'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isCommunity: json['isCommunity'] as bool? ?? false,
        author: json['author'] as String?,
        time: json['time'] as String? ?? '30 min',
        servings: json['servings'] as String? ?? '4 porções',
        difficulty: json['difficulty'] as String? ?? 'Médio',
        rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
        emoji: json['emoji'] as String? ?? '🍳',
        colorStart: json['colorStart'] as String? ?? '#FFE0B2',
        colorEnd: json['colorEnd'] as String? ?? '#FF8A65',
        category: json['category'] as String? ?? 'Outros',
        ingredients: (json['ingredients'] as List<dynamic>?)?.cast<String>() ?? [],
        steps: (json['steps'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  String toJsonString() => jsonEncode(toJson());
  factory Recipe.fromJsonString(String str) =>
      Recipe.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
