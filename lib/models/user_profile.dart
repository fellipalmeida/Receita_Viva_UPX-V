import 'dart:convert';

class UserProfile {
  final String name;
  final String email;
  final List<String> alergias;
  final List<String> dietas;
  final List<String> cozinhas;

  const UserProfile({
    required this.name,
    required this.email,
    this.alergias = const [],
    this.dietas = const [],
    this.cozinhas = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'alergias': alergias,
        'dietas': dietas,
        'cozinhas': cozinhas,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Chef',
        email: json['email'] as String? ?? '',
        alergias: (json['alergias'] as List<dynamic>?)?.cast<String>() ?? [],
        dietas: (json['dietas'] as List<dynamic>?)?.cast<String>() ?? [],
        cozinhas: (json['cozinhas'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  String toJsonString() => jsonEncode(toJson());
  factory UserProfile.fromJsonString(String str) =>
      UserProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
